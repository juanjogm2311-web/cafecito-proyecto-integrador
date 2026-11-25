/* =====================================================================
   CAFECITO · PROYECTO INTEGRADOR · EQUIPO 1 · GRUPO O3
   src/03_etl_limpieza_plata.sql
   LIMPIEZA Y CALIDAD: bronce -> plata.
     A. Fase 1 · diagnóstico (perfilado de anomalías en bronce)      -> Paulina Martínez (QA)
     B. plata.sp_limpiar_y_cargar_plata (fases 2, 3 y 4, IDEMPOTENTE)  -> Ana Sofía Arroniz (ETL)
     C. plata.sp_registrar_cliente (alta controlada con validaciones)
     D. Ejecución del pipeline y pruebas de calidad de plata
   Prerrequisitos: src/01 y src/02.
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

/* =====================================================================
   SECCIÓN A · FASE 1 · DIAGNÓSTICO (solo consulta, no modifica datos)
   La consulta 1.9 resume todas las anomalías de bronce.
   ===================================================================== */
/* 1.1 VOLUMEN POR ORIGEN */
SELECT 'Clientes (SQL)' AS Origen, COUNT(*) AS Registros FROM bronce.clientes_raw
UNION ALL SELECT 'Ventas (SQL)',     COUNT(*) FROM bronce.ventas_raw
UNION ALL SELECT 'Clima (JSON)',     COUNT(*) FROM bronce.clima_raw
UNION ALL SELECT 'Entregas (CSV)',   COUNT(*) FROM bronce.entregas_raw;

/* 1.2 NULOS O VACÍOS POR COLUMNA */
SELECT 'Ventas' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(ID_Cliente), '')  IS NULL THEN 1 ELSE 0 END) AS Nulos_ID_Cliente,
       SUM(CASE WHEN NULLIF(TRIM(Monto_Total), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Monto,
       SUM(CASE WHEN NULLIF(TRIM(Fecha_Hora), '')  IS NULL THEN 1 ELSE 0 END) AS Nulos_Fecha
FROM bronce.ventas_raw;

SELECT 'Clientes' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Telefono), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Telefono,
       SUM(CASE WHEN NULLIF(TRIM(Email), '')    IS NULL THEN 1 ELSE 0 END) AS Nulos_Email
FROM bronce.clientes_raw;

SELECT 'Clima' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Temperatura_C), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Temperatura,
       SUM(CASE WHEN NULLIF(TRIM(Humedad_Pct), '')   IS NULL THEN 1 ELSE 0 END) AS Nulos_Humedad
FROM bronce.clima_raw;

SELECT 'Entregas' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Minutos_Demora), '')       IS NULL THEN 1 ELSE 0 END) AS Nulos_Minutos_Demora,
       SUM(CASE WHEN NULLIF(TRIM(Calificacion_Cliente), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Calificacion
FROM bronce.entregas_raw;

/* 1.3 ESPACIOS EXTRA Y VARIANTES DE ESCRITURA */
SELECT 'Ventas.Tipo_Producto' AS Campo,
       SUM(CASE WHEN DATALENGTH(Tipo_Producto) <> DATALENGTH(TRIM(Tipo_Producto)) OR Tipo_Producto LIKE '%  %' THEN 1 ELSE 0 END) AS Con_Espacios_Extra
FROM bronce.ventas_raw
UNION ALL
SELECT 'Ventas.ID_Sucursal',
       SUM(CASE WHEN DATALENGTH(ID_Sucursal) <> DATALENGTH(TRIM(ID_Sucursal)) THEN 1 ELSE 0 END)
FROM bronce.ventas_raw
UNION ALL
SELECT 'Clientes.Nombre',
       SUM(CASE WHEN DATALENGTH(Nombre) <> DATALENGTH(TRIM(Nombre)) OR Nombre LIKE '%  %' THEN 1 ELSE 0 END)
FROM bronce.clientes_raw
UNION ALL
SELECT 'Clientes.Email',
       SUM(CASE WHEN DATALENGTH(Email) <> DATALENGTH(TRIM(Email)) OR Email COLLATE Latin1_General_CS_AS <> LOWER(Email) THEN 1 ELSE 0 END)
FROM bronce.clientes_raw
UNION ALL
SELECT 'Entregas.ID_Pedido',
       SUM(CASE WHEN DATALENGTH(ID_Pedido) <> DATALENGTH(TRIM(ID_Pedido)) OR ID_Pedido COLLATE Latin1_General_CS_AS <> UPPER(ID_Pedido) THEN 1 ELSE 0 END)
FROM bronce.entregas_raw;

-- Variantes de escritura de una misma categoría / ciudad.
-- Se agrupa con COLLATE Latin1_General_BIN y entre corchetes para que
-- 'Leon', 'LEON' y 'Leon ' cuenten como valores DISTINTOS (si no, la
-- intercalación CI de la BD los juntaría y escondería el problema).
SELECT Valor_Crudo AS Tipo_Producto_Crudo, COUNT(*) AS Veces
FROM (SELECT (N'[' + Tipo_Producto + N']') COLLATE Latin1_General_BIN AS Valor_Crudo FROM bronce.ventas_raw) AS x
GROUP BY Valor_Crudo
ORDER BY Valor_Crudo;

SELECT Origen, Valor_Crudo AS Ciudad_Cruda, COUNT(*) AS Veces
FROM (
    SELECT 'Ventas'   AS Origen, (N'[' + Sucursal_Ciudad + N']') COLLATE Latin1_General_BIN AS Valor_Crudo FROM bronce.ventas_raw
    UNION ALL
    SELECT 'Clima',              (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN                  FROM bronce.clima_raw
    UNION ALL
    SELECT 'Clientes',           (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN                  FROM bronce.clientes_raw
) AS x
GROUP BY Origen, Valor_Crudo
ORDER BY Origen, Valor_Crudo;

/* 1.4 TIPOS DE DATO INVÁLIDOS */
SELECT ID_Pedido, Monto_Total AS Monto_Crudo
FROM bronce.ventas_raw
WHERE TRY_CONVERT(DECIMAL(10,2), TRIM(Monto_Total)) IS NULL;           -- ej. '$180.00'

SELECT Fecha_Consulta, Ciudad, Temperatura_C, Humedad_Pct
FROM bronce.clima_raw
WHERE TRY_CONVERT(DECIMAL(4,1), Temperatura_C) IS NULL OR TRY_CONVERT(INT, Humedad_Pct) IS NULL;

-- Tipos dentro del JSON original de la API: OPENJSON sin WITH devuelve [type]
--   0 = null, 1 = string (texto), 2 = number. Temperatura y Humedad DEBEN ser 2.
SELECT j.[key] AS Posicion_En_Arreglo, p.[key] AS Campo, p.[value] AS Valor,
       CASE p.[type] WHEN 0 THEN 'NULL' WHEN 1 THEN 'TEXTO (debería ser número)' ELSE 'OTRO' END AS Tipo_Detectado
FROM bronce.clima_json_raw AS r
CROSS APPLY OPENJSON(r.Respuesta_JSON) AS j
CROSS APPLY OPENJSON(j.[value]) AS p
WHERE p.[key] IN (N'Temperatura_C', N'Humedad_Pct') AND p.[type] <> 2;

/* 1.5 VALORES FUERA DE RANGO */
SELECT 'Monto negativo' AS Regla, ID_Pedido AS Llave, Monto_Total AS Valor
FROM bronce.ventas_raw WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(TRIM(Monto_Total), '$', '')) < 0
UNION ALL
SELECT 'Humedad fuera de 0-100', Fecha_Consulta + ' ' + Ciudad, Humedad_Pct
FROM bronce.clima_raw WHERE TRY_CONVERT(INT, Humedad_Pct) NOT BETWEEN 0 AND 100
UNION ALL
SELECT 'Demora negativa', ID_Envio, Minutos_Demora
FROM bronce.entregas_raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Minutos_Demora), '')) < 0
UNION ALL
SELECT 'Calificación fuera de 1-5', ID_Envio, Calificacion_Cliente
FROM bronce.entregas_raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Calificacion_Cliente), '')) NOT BETWEEN 1 AND 5;

/* 1.6 DUPLICADOS (reintentos de ingesta) */
SELECT 'Ventas' AS Origen, UPPER(TRIM(ID_Pedido)) AS Llave, COUNT(*) AS Veces
FROM bronce.ventas_raw GROUP BY UPPER(TRIM(ID_Pedido)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clientes', UPPER(TRIM(ID_Cliente)), COUNT(*)
FROM bronce.clientes_raw GROUP BY UPPER(TRIM(ID_Cliente)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Entregas', UPPER(TRIM(ID_Envio)), COUNT(*)
FROM bronce.entregas_raw GROUP BY UPPER(TRIM(ID_Envio)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clima', Fecha_Consulta + ' | ' + UPPER(TRIM(Ciudad)), COUNT(*)
FROM bronce.clima_raw GROUP BY Fecha_Consulta, UPPER(TRIM(Ciudad)) HAVING COUNT(*) > 1
ORDER BY Origen, Llave;

/* 1.7 FORMATOS DE FECHA HETEROGÉNEOS EN EL CSV DE ENTREGAS
   OJO: '01/08/2026' es 1 de agosto (dd/mm/aaaa). Si se convierte sin
   indicar el formato, SQL Server o pandas pueden leerlo como 8 de enero. */
SELECT CASE
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]' THEN 'aaaa/mm/dd'
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' THEN 'aaaa-mm-dd (ISO)'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN 'dd/mm/aaaa'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'dd-mm-aaaa'
           ELSE 'FORMATO NO RECONOCIDO'
       END AS Formato_Detectado,
       COUNT(*) AS Registros,
       MIN(Fecha_Entrega) AS Ejemplo
FROM bronce.entregas_raw
GROUP BY CASE
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]' THEN 'aaaa/mm/dd'
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' THEN 'aaaa-mm-dd (ISO)'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN 'dd/mm/aaaa'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'dd-mm-aaaa'
           ELSE 'FORMATO NO RECONOCIDO'
         END;

/* 1.8 INTEGRIDAD REFERENCIAL: entregas cuyo pedido no existe en ventas */
SELECT e.ID_Envio, e.ID_Pedido AS ID_Pedido_Crudo
FROM bronce.entregas_raw AS e
LEFT JOIN (SELECT DISTINCT UPPER(TRIM(ID_Pedido)) AS ID_Pedido FROM bronce.ventas_raw) AS v
       ON v.ID_Pedido = UPPER(TRIM(e.ID_Pedido))
WHERE v.ID_Pedido IS NULL;

/* 1.9 RESUMEN DE ANOMALÍAS (esta tabla va en el documento, Fase 1) */
SELECT Origen, Anomalia, Registros_Afectados
FROM (
    SELECT 1 AS Orden, 'Ventas (SQL)' AS Origen, 'Duplicados por reintento de ingesta' AS Anomalia,
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Pedido))) FROM bronce.ventas_raw) AS Registros_Afectados
    UNION ALL SELECT 2, 'Ventas (SQL)', 'Tipo_Producto con espacios / mayúsculas / sin acento',
           (SELECT COUNT(*) FROM bronce.ventas_raw
             WHERE Tipo_Producto COLLATE Latin1_General_CS_AS NOT IN (N'Bebida Caliente', N'Bebida Fría', N'Repostería')
                OR DATALENGTH(Tipo_Producto) <> DATALENGTH(TRIM(Tipo_Producto)))
    UNION ALL SELECT 3, 'Ventas (SQL)', 'ID_Sucursal con espacios o minúsculas',
           (SELECT COUNT(*) FROM bronce.ventas_raw
             WHERE DATALENGTH(ID_Sucursal) <> DATALENGTH(TRIM(ID_Sucursal)) OR ID_Sucursal COLLATE Latin1_General_CS_AS <> UPPER(ID_Sucursal))
    UNION ALL SELECT 4, 'Ventas (SQL)', 'Monto negativo',
           (SELECT COUNT(*) FROM bronce.ventas_raw WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(TRIM(Monto_Total), '$', '')) < 0)
    UNION ALL SELECT 5, 'Ventas (SQL)', 'Monto con símbolo $ (tipo inválido)',
           (SELECT COUNT(*) FROM bronce.ventas_raw WHERE Monto_Total LIKE '%$%')
    UNION ALL SELECT 6, 'Ventas (SQL)', 'Pedido sin ID_Cliente (nulo)',
           (SELECT COUNT(*) FROM bronce.ventas_raw WHERE NULLIF(TRIM(ID_Cliente), '') IS NULL)
    UNION ALL SELECT 7, 'Clientes (SQL)', 'Duplicados por reintento de ingesta',
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Cliente))) FROM bronce.clientes_raw)
    UNION ALL SELECT 8, 'Clientes (SQL)', 'Nombre / Email con espacios o mayúsculas',
           (SELECT COUNT(*) FROM bronce.clientes_raw
             WHERE DATALENGTH(Nombre) <> DATALENGTH(TRIM(Nombre)) OR Nombre LIKE '%  %'
                OR Nombre COLLATE Latin1_General_CS_AS = UPPER(Nombre) OR Nombre COLLATE Latin1_General_CS_AS = LOWER(Nombre)
                OR DATALENGTH(Email) <> DATALENGTH(TRIM(Email)) OR Email COLLATE Latin1_General_CS_AS <> LOWER(Email))
    UNION ALL SELECT 9, 'Clientes (SQL)', 'Teléfono nulo',
           (SELECT COUNT(*) FROM bronce.clientes_raw WHERE NULLIF(TRIM(Telefono), '') IS NULL)
    UNION ALL SELECT 10, 'Clima (JSON)', 'Duplicados por reintento de la API',
           (SELECT COUNT(*) - COUNT(DISTINCT Fecha_Consulta + N'|' + UPPER(TRIM(Ciudad))) FROM bronce.clima_raw)
    UNION ALL SELECT 11, 'Clima (JSON)', 'Ciudad con variantes (León, GTO, espacios)',
           (SELECT COUNT(*) FROM bronce.clima_raw WHERE Ciudad COLLATE Latin1_General_CS_AS NOT IN (N'Leon', N'Silao', N'Guanajuato'))
    UNION ALL SELECT 12, 'Clima (JSON)', 'Temperatura como texto en el JSON (tipo inconsistente)',
           (SELECT COUNT(*) FROM bronce.clima_json_raw AS r CROSS APPLY OPENJSON(r.Respuesta_JSON) AS j CROSS APPLY OPENJSON(j.[value]) AS p
             WHERE p.[key] = N'Temperatura_C' AND p.[type] = 1)
    UNION ALL SELECT 13, 'Clima (JSON)', 'Temperatura nula',
           (SELECT COUNT(*) FROM bronce.clima_raw WHERE NULLIF(TRIM(Temperatura_C), '') IS NULL)
    UNION ALL SELECT 14, 'Clima (JSON)', 'Humedad fuera de rango 0-100',
           (SELECT COUNT(*) FROM bronce.clima_raw WHERE TRY_CONVERT(INT, Humedad_Pct) NOT BETWEEN 0 AND 100)
    UNION ALL SELECT 15, 'Entregas (CSV)', 'Duplicados por reintento de ingesta',
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Envio))) FROM bronce.entregas_raw)
    UNION ALL SELECT 16, 'Entregas (CSV)', 'Fecha en formato distinto a ISO',
           (SELECT COUNT(*) FROM bronce.entregas_raw WHERE Fecha_Entrega NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
    UNION ALL SELECT 17, 'Entregas (CSV)', 'Minutos_Demora vacío',
           (SELECT COUNT(*) FROM bronce.entregas_raw WHERE NULLIF(TRIM(Minutos_Demora), '') IS NULL)
    UNION ALL SELECT 18, 'Entregas (CSV)', 'Minutos_Demora negativo',
           (SELECT COUNT(*) FROM bronce.entregas_raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Minutos_Demora), '')) < 0)
    UNION ALL SELECT 19, 'Entregas (CSV)', 'Calificación vacía',
           (SELECT COUNT(*) FROM bronce.entregas_raw WHERE NULLIF(TRIM(Calificacion_Cliente), '') IS NULL)
    UNION ALL SELECT 20, 'Entregas (CSV)', 'Calificación fuera de 1-5',
           (SELECT COUNT(*) FROM bronce.entregas_raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Calificacion_Cliente), '')) NOT BETWEEN 1 AND 5)
    UNION ALL SELECT 21, 'Entregas (CSV)', 'ID_Pedido con espacios o minúsculas',
           (SELECT COUNT(*) FROM bronce.entregas_raw
             WHERE DATALENGTH(ID_Pedido) <> DATALENGTH(TRIM(ID_Pedido)) OR ID_Pedido COLLATE Latin1_General_CS_AS <> UPPER(ID_Pedido))
    UNION ALL SELECT 22, 'Entregas (CSV)', 'Entrega sin pedido existente (huérfana)',
           (SELECT COUNT(*) FROM bronce.entregas_raw AS e
             WHERE NOT EXISTS (SELECT 1 FROM bronce.ventas_raw AS v WHERE UPPER(TRIM(v.ID_Pedido)) = UPPER(TRIM(e.ID_Pedido))))
) AS r
ORDER BY Orden;
GO

/* =====================================================================
   SECCIÓN B · PIPELINE DE LIMPIEZA BRONCE -> PLATA (fases 2, 3 y 4)
   Procedimiento almacenado IDEMPOTENTE: al empezar vacía lo cargado en plata y lo
   reconstruye desde bronce, por eso se puede ejecutar N veces con el mismo resultado.
     Fase 2  Estandarización: TRIM / UPPER / LOWER, TRY_CONVERT con estilo explícito
     Fase 3  Deduplicación:  ROW_NUMBER() conservando la primera llegada
     Fase 4  Validación:     ABS, rangos, LEFT JOIN a maestras + rechazos,
                             imputación (COALESCE / ISNULL / mediana / moda / promedio)
   @mostrar_detalle = 1 muestra los controles intermedios (útil para depurar).
   Responsable: Ana Sofía Arroniz Domínguez (Ingeniera ETL / Data Engineer)
   ===================================================================== */
CREATE OR ALTER PROCEDURE plata.sp_limpiar_y_cargar_plata
    @mostrar_detalle BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @n INT, @Mediana FLOAT, @MedianaEntera INT, @Moda INT;

    /* ---------- 0. Reinicio (idempotencia) ---------- */
    DELETE FROM plata.fact_entrega;
    DELETE FROM plata.fact_pedido;
    TRUNCATE TABLE plata.fact_clima_diario;      -- ninguna FK la referencia; reinicia su identity
    DELETE FROM plata.dim_cliente WHERE cliente_id <> 'CLI-000';
    TRUNCATE TABLE plata.registros_rechazados;
    TRUNCATE TABLE plata.bitacora_limpieza;
    DROP TABLE IF EXISTS #Clientes_Std, #Ventas_Std, #Clima_Std, #Entregas_Std;

    /* =====================================================================
       FASE 2 · ESTANDARIZACIÓN
       - TRIM / UPPER / LOWER en textos; espacios dobles internos -> uno
         (truco REPLACE '<>' / '><').
       - Categorías y ciudades unificadas comparando SIN acentos ni mayúsculas
         (COLLATE Latin1_General_CI_AI) y mapeadas a su ID del catálogo.
       - Fechas a tipo DATE/DATETIME con estilo EXPLÍCITO (no depende del idioma
         del servidor): 120 = aaaa-mm-dd hh:mi:ss, 23 = aaaa-mm-dd,
         111 = aaaa/mm/dd, 103 = dd/mm/aaaa, 105 = dd-mm-aaaa.
       - Números: TRY_CONVERT (si no se puede convertir queda NULL, no truena).
       ===================================================================== */
    DROP TABLE IF EXISTS #Clientes_Std;
    DROP TABLE IF EXISTS #Ventas_Std;
    DROP TABLE IF EXISTS #Clima_Std;
    DROP TABLE IF EXISTS #Entregas_Std;

    -- 2.1 Clientes
    SELECT  r.ID_Carga,
            CAST(UPPER(TRIM(r.ID_Cliente)) AS VARCHAR(10))                                   AS ID_Cliente,
            UPPER(REPLACE(REPLACE(REPLACE(TRIM(r.Nombre), N' ', N'<>'), N'><', N''), N'<>', N' ')) AS Nombre_Completo,
            CAST(LOWER(TRIM(r.Email)) AS VARCHAR(120))                                      AS Email,
            CAST(NULLIF(TRIM(r.Telefono), N'') AS VARCHAR(15))                              AS Telefono,
            CAST(CASE WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI = N'LEON'                     THEN 1
                      WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI = N'SILAO'                    THEN 2
                      WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI IN (N'GUANAJUATO', N'GTO')    THEN 3
                 END AS TINYINT)                                                            AS ID_Ciudad,
            TRY_CONVERT(DATE, TRIM(r.Fecha_Registro), 23)                                   AS Fecha_Registro
    INTO #Clientes_Std
    FROM bronce.clientes_raw AS r;

    -- 2.2 Ventas (pedidos)
    SELECT  r.ID_Carga,
            CAST(UPPER(TRIM(r.ID_Pedido)) AS VARCHAR(10))                    AS ID_Pedido,
            CAST(UPPER(NULLIF(TRIM(r.ID_Cliente), N'')) AS VARCHAR(10))      AS ID_Cliente,
            TRY_CONVERT(DATETIME, TRIM(r.Fecha_Hora), 120)                   AS Fecha_Hora,
            CAST(UPPER(TRIM(r.ID_Sucursal)) AS VARCHAR(10))                  AS ID_Sucursal,
            CAST(CASE WHEN t.Tipo_Limpio COLLATE Latin1_General_CI_AI = N'BEBIDA CALIENTE' THEN 1
                      WHEN t.Tipo_Limpio COLLATE Latin1_General_CI_AI = N'BEBIDA FRIA'     THEN 2
                      WHEN t.Tipo_Limpio COLLATE Latin1_General_CI_AI = N'REPOSTERIA'      THEN 3
                 END AS TINYINT)                                             AS ID_Categoria,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(TRIM(r.Monto_Total), N'$', N'')) AS Monto_Total,
            CAST(CASE WHEN TRIM(r.Sucursal_Ciudad) COLLATE Latin1_General_CI_AI = N'LEON'                  THEN 1
                      WHEN TRIM(r.Sucursal_Ciudad) COLLATE Latin1_General_CI_AI = N'SILAO'                 THEN 2
                      WHEN TRIM(r.Sucursal_Ciudad) COLLATE Latin1_General_CI_AI IN (N'GUANAJUATO', N'GTO') THEN 3
                 END AS TINYINT)                                             AS ID_Ciudad_Origen
    INTO #Ventas_Std
    FROM bronce.ventas_raw AS r
    CROSS APPLY (SELECT REPLACE(REPLACE(REPLACE(TRIM(r.Tipo_Producto), N' ', N'<>'), N'><', N''), N'<>', N' ') AS Tipo_Limpio) AS t;

    -- 2.3 Clima (API JSON)
    SELECT  r.ID_Carga,
            TRY_CONVERT(DATE, TRIM(r.Fecha_Consulta), 23)                    AS Fecha,
            CAST(CASE WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI = N'LEON'                  THEN 1
                      WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI = N'SILAO'                 THEN 2
                      WHEN TRIM(r.Ciudad) COLLATE Latin1_General_CI_AI IN (N'GUANAJUATO', N'GTO') THEN 3
                 END AS TINYINT)                                             AS ID_Ciudad,
            TRY_CONVERT(DECIMAL(4,1), TRIM(r.Temperatura_C))                 AS Temperatura_C,
            CAST(UPPER(TRIM(r.Condicion_Climatica)) AS NVARCHAR(30))         AS Condicion_Climatica,
            TRY_CONVERT(INT, TRIM(r.Humedad_Pct))                            AS Humedad_Pct,
            CAST(0 AS BIT)                                                   AS Temperatura_Imputada
    INTO #Clima_Std
    FROM bronce.clima_raw AS r;

    -- 2.4 Entregas (CSV) - fechas heterogéneas -> DATE
    SELECT  r.ID_Carga,
            CAST(UPPER(TRIM(r.ID_Envio))  AS VARCHAR(10))                    AS ID_Envio,
            CAST(UPPER(TRIM(r.ID_Pedido)) AS VARCHAR(10))                    AS ID_Pedido,
            CASE
                WHEN f.F LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]' THEN TRY_CONVERT(DATE, f.F, 111)
                WHEN f.F LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' THEN TRY_CONVERT(DATE, f.F, 23)
                WHEN f.F LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN TRY_CONVERT(DATE, f.F, 103)
                WHEN f.F LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN TRY_CONVERT(DATE, f.F, 105)
            END                                                              AS Fecha_Entrega,
            TRY_CONVERT(INT, NULLIF(TRIM(r.Minutos_Demora), N''))            AS Minutos_Demora,
            TRY_CONVERT(INT, NULLIF(TRIM(r.Calificacion_Cliente), N''))      AS Calificacion_Cliente,
            CAST(0 AS BIT)                                                   AS Demora_Imputada,
            CAST(0 AS BIT)                                                   AS Calificacion_Imputada
    INTO #Entregas_Std
    FROM bronce.entregas_raw AS r
    CROSS APPLY (SELECT TRIM(r.Fecha_Entrega) AS F) AS f;

    -- Evidencia de la Fase 2
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros)
    SELECT N'2-Estandarización', N'Ventas', N'Variantes de Tipo_Producto en origen (se unifican a 3 categorías)',
           COUNT(DISTINCT (N'[' + Tipo_Producto + N']') COLLATE Latin1_General_BIN) FROM bronce.ventas_raw
    UNION ALL
    SELECT N'2-Estandarización', N'Ventas', N'Variantes de Sucursal_Ciudad en origen (se unifican a ID_Ciudad)',
           COUNT(DISTINCT (N'[' + Sucursal_Ciudad + N']') COLLATE Latin1_General_BIN) FROM bronce.ventas_raw
    UNION ALL
    SELECT N'2-Estandarización', N'Clima', N'Variantes de Ciudad en el JSON (se unifican a ID_Ciudad)',
           COUNT(DISTINCT (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN) FROM bronce.clima_raw
    UNION ALL
    SELECT N'2-Estandarización', N'Entregas', N'Fechas convertidas de formato no ISO a DATE',
           COUNT(*) FROM bronce.entregas_raw WHERE TRIM(Fecha_Entrega) NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
    UNION ALL
    SELECT N'2-Estandarización', N'Ventas', N'Montos con símbolo $ convertidos a DECIMAL',
           COUNT(*) FROM bronce.ventas_raw WHERE Monto_Total LIKE N'%$%';

    IF @mostrar_detalle = 1
    BEGIN
    -- Control: nada debe quedar sin mapear (resultado esperado: 0 filas)
    SELECT 'Ventas sin categoría o ciudad' AS Control, COUNT(*) AS Filas FROM #Ventas_Std WHERE ID_Categoria IS NULL OR ID_Ciudad_Origen IS NULL OR Fecha_Hora IS NULL
    UNION ALL SELECT 'Clima sin ciudad o fecha', COUNT(*) FROM #Clima_Std WHERE ID_Ciudad IS NULL OR Fecha IS NULL
    UNION ALL SELECT 'Entregas sin fecha válida', COUNT(*) FROM #Entregas_Std WHERE Fecha_Entrega IS NULL
    UNION ALL SELECT 'Clientes sin ciudad', COUNT(*) FROM #Clientes_Std WHERE ID_Ciudad IS NULL;

    -- Antes vs. después (captura para el documento)
    SELECT TOP (12) r.ID_Envio, r.ID_Pedido AS ID_Pedido_Crudo, s.ID_Pedido AS ID_Pedido_Limpio,
           r.Fecha_Entrega AS Fecha_Cruda, s.Fecha_Entrega AS Fecha_ISO
    FROM bronce.entregas_raw AS r
    JOIN #Entregas_Std AS s ON s.ID_Carga = r.ID_Carga
    ORDER BY r.ID_Carga;
    END


    /* =====================================================================
       FASE 3 · DEDUPLICACIÓN
       1) Se COMPRUEBA que las copias son idénticas (Versiones_Distintas = 1),
          es decir, que de verdad son reintentos y no datos distintos.
       2) Se conserva la primera llegada (menor ID_Carga) con ROW_NUMBER().
       ===================================================================== */

    IF @mostrar_detalle = 1
    BEGIN
    -- 3.1 Comprobación previa
    SELECT 'Ventas' AS Tabla, ID_Pedido AS Llave, COUNT(*) AS Copias,
           COUNT(DISTINCT CONCAT(ID_Cliente, '|', CONVERT(VARCHAR(19), Fecha_Hora, 120), '|', ID_Sucursal, '|', ID_Categoria, '|', Monto_Total)) AS Versiones_Distintas
    FROM #Ventas_Std GROUP BY ID_Pedido HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'Clientes', ID_Cliente, COUNT(*),
           COUNT(DISTINCT CONCAT(Nombre_Completo, '|', Email, '|', Telefono, '|', ID_Ciudad))
    FROM #Clientes_Std GROUP BY ID_Cliente HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'Entregas', ID_Envio, COUNT(*),
           COUNT(DISTINCT CONCAT(ID_Pedido, '|', Fecha_Entrega, '|', Minutos_Demora, '|', Calificacion_Cliente))
    FROM #Entregas_Std GROUP BY ID_Envio HAVING COUNT(*) > 1
    UNION ALL
    SELECT 'Clima', CONCAT(CONVERT(VARCHAR(10), Fecha, 23), ' | ', ID_Ciudad), COUNT(*),
           COUNT(DISTINCT CONCAT(Temperatura_C, '|', Condicion_Climatica, '|', Humedad_Pct))
    FROM #Clima_Std GROUP BY Fecha, ID_Ciudad HAVING COUNT(*) > 1;
    END


    -- 3.2 Eliminación con ROW_NUMBER()
    ;WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Pedido ORDER BY ID_Carga) AS rn FROM #Ventas_Std)
    DELETE FROM d WHERE rn > 1;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'3-Deduplicación', N'Ventas', N'Pedidos duplicados eliminados (ROW_NUMBER)', @n);

    ;WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Cliente ORDER BY ID_Carga) AS rn FROM #Clientes_Std)
    DELETE FROM d WHERE rn > 1;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'3-Deduplicación', N'Clientes', N'Clientes duplicados eliminados (ROW_NUMBER)', @n);

    ;WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY Fecha, ID_Ciudad ORDER BY ID_Carga) AS rn FROM #Clima_Std)
    DELETE FROM d WHERE rn > 1;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'3-Deduplicación', N'Clima', N'Registros de clima duplicados eliminados (Fecha + Ciudad)', @n);

    ;WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Envio ORDER BY ID_Carga) AS rn FROM #Entregas_Std)
    DELETE FROM d WHERE rn > 1;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'3-Deduplicación', N'Entregas', N'Envíos duplicados eliminados (ROW_NUMBER)', @n);

    /* =====================================================================
       FASE 4 · VALIDACIÓN Y ENRIQUECIMIENTO
       4.1 Reglas de negocio (ABS, rangos válidos)
       4.2 Integración relacional con LEFT JOIN a maestras (+ rechazos) y carga
       4.3 Imputación de faltantes (ISNULL / COALESCE, mediana, moda, promedio)
       ===================================================================== */

    -- 4.1 Reglas de negocio --------------------------------------------------
    UPDATE #Ventas_Std SET Monto_Total = ABS(Monto_Total) WHERE Monto_Total < 0;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Ventas', N'Montos negativos corregidos con ABS', @n);

    UPDATE #Entregas_Std SET Minutos_Demora = ABS(Minutos_Demora) WHERE Minutos_Demora < 0;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Entregas', N'Minutos de demora negativos corregidos con ABS', @n);

    UPDATE #Entregas_Std SET Calificacion_Cliente = NULL WHERE Calificacion_Cliente NOT BETWEEN 1 AND 5;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Entregas', N'Calificaciones fuera de 1-5 marcadas como faltantes (se imputan)', @n);

    UPDATE #Clima_Std SET Humedad_Pct = NULL WHERE Humedad_Pct NOT BETWEEN 0 AND 100;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Clima', N'Humedad fuera de 0-100 invalidada (queda NULL, no confiable)', @n);

    UPDATE #Clima_Std SET Temperatura_C = NULL WHERE Temperatura_C NOT BETWEEN -10 AND 50;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Clima', N'Temperaturas fuera de -10 a 50 °C invalidadas', @n);

    -- 4.2a CLIENTES: LEFT JOIN con Ciudad -> rechazo o carga -------------------
    INSERT INTO plata.registros_rechazados (origen, llave_registro, motivo)
    SELECT N'Clientes', ISNULL(c.ID_Cliente, N'(nulo)'), N'Ciudad no existe en catálogo, email o fecha inválidos'
    FROM #Clientes_Std AS c
    LEFT JOIN plata.dim_ciudad AS ci ON ci.ciudad_id = c.ID_Ciudad
    WHERE ci.ciudad_id IS NULL OR c.Email IS NULL OR c.Email NOT LIKE '%_@_%._%' OR c.Fecha_Registro IS NULL;

    INSERT INTO plata.dim_cliente (cliente_id, nombre_completo, email, telefono, ciudad_id, fecha_registro)
    SELECT c.ID_Cliente, c.Nombre_Completo, c.Email, c.Telefono, c.ID_Ciudad, c.Fecha_Registro
    FROM #Clientes_Std AS c
    LEFT JOIN plata.dim_ciudad AS ci ON ci.ciudad_id = c.ID_Ciudad
    WHERE ci.ciudad_id IS NOT NULL AND c.Email LIKE '%_@_%._%' AND c.Fecha_Registro IS NOT NULL;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Carga', N'plata.dim_cliente', N'Clientes cargados al modelo', @n);

    -- 4.2b PEDIDOS: COALESCE cliente faltante + LEFT JOIN con 3 maestras --------
    SELECT @n = COUNT(*) FROM #Ventas_Std WHERE ID_Cliente IS NULL;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Imputación', N'Ventas', N'Pedidos sin cliente asignados a CLI-000 (COALESCE)', @n);

    INSERT INTO plata.registros_rechazados (origen, llave_registro, motivo)
    SELECT N'Ventas', v.ID_Pedido, N'Cliente, sucursal o categoría inexistente / fecha o monto inválido'
    FROM #Ventas_Std AS v
    LEFT JOIN plata.dim_cliente            AS cl ON cl.cliente_id   = COALESCE(v.ID_Cliente, 'CLI-000')
    LEFT JOIN plata.dim_sucursal           AS s  ON s.sucursal_id   = v.ID_Sucursal
    LEFT JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = v.ID_Categoria
    WHERE cl.cliente_id IS NULL OR s.sucursal_id IS NULL OR ca.categoria_id IS NULL
       OR v.Fecha_Hora IS NULL OR v.Monto_Total IS NULL;

    INSERT INTO plata.fact_pedido (pedido_id, cliente_id, sucursal_id, categoria_id, fecha_hora, monto_total)
    SELECT v.ID_Pedido, cl.cliente_id, s.sucursal_id, ca.categoria_id, v.Fecha_Hora, v.Monto_Total
    FROM #Ventas_Std AS v
    LEFT JOIN plata.dim_cliente            AS cl ON cl.cliente_id   = COALESCE(v.ID_Cliente, 'CLI-000')
    LEFT JOIN plata.dim_sucursal           AS s  ON s.sucursal_id   = v.ID_Sucursal
    LEFT JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = v.ID_Categoria
    WHERE cl.cliente_id IS NOT NULL AND s.sucursal_id IS NOT NULL AND ca.categoria_id IS NOT NULL
      AND v.Fecha_Hora IS NOT NULL AND v.Monto_Total IS NOT NULL;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Carga', N'plata.fact_pedido', N'Pedidos cargados al modelo', @n);

    IF @mostrar_detalle = 1
    BEGIN
    -- Control de consistencia: la ciudad escrita en ventas coincide con la de la sucursal (esperado 0)
    SELECT COUNT(*) AS Pedidos_Ciudad_Inconsistente
    FROM #Ventas_Std AS v JOIN plata.dim_sucursal AS s ON s.sucursal_id = v.ID_Sucursal
    WHERE v.ID_Ciudad_Origen <> s.ciudad_id;
    END


    -- 4.2c + 4.3 CLIMA: imputación de temperatura con el promedio de su ciudad --
    UPDATE c
    SET    c.Temperatura_C        = pc.Promedio_Ciudad,
           c.Temperatura_Imputada = 1
    FROM #Clima_Std AS c
    JOIN (SELECT ID_Ciudad, CAST(ROUND(AVG(Temperatura_C), 1) AS DECIMAL(4,1)) AS Promedio_Ciudad
          FROM #Clima_Std WHERE Temperatura_C IS NOT NULL GROUP BY ID_Ciudad) AS pc
      ON pc.ID_Ciudad = c.ID_Ciudad
    WHERE c.Temperatura_C IS NULL;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Imputación', N'Clima', N'Temperaturas nulas imputadas con el promedio de su ciudad', @n);

    INSERT INTO plata.registros_rechazados (origen, llave_registro, motivo)
    SELECT N'Clima', CONCAT(CONVERT(VARCHAR(10), c.Fecha, 23), ' ', ISNULL(CAST(c.ID_Ciudad AS VARCHAR(3)), '?')), N'Ciudad/fecha inválida o condición no reconocida'
    FROM #Clima_Std AS c
    LEFT JOIN plata.dim_ciudad AS ci ON ci.ciudad_id = c.ID_Ciudad
    WHERE ci.ciudad_id IS NULL OR c.Fecha IS NULL
       OR c.Condicion_Climatica NOT IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO');

    INSERT INTO plata.fact_clima_diario (fecha, ciudad_id, temperatura_c, condicion_climatica, humedad_pct, temperatura_imputada)
    SELECT c.Fecha, c.ID_Ciudad, c.Temperatura_C, c.Condicion_Climatica, c.Humedad_Pct, c.Temperatura_Imputada
    FROM #Clima_Std AS c
    LEFT JOIN plata.dim_ciudad AS ci ON ci.ciudad_id = c.ID_Ciudad
    WHERE ci.ciudad_id IS NOT NULL AND c.Fecha IS NOT NULL
      AND c.Condicion_Climatica IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO');
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Carga', N'plata.fact_clima_diario', N'Registros de clima cargados al modelo', @n);

    -- 4.2d ENTREGAS: LEFT JOIN con Pedido -> las huérfanas se rechazan ---------
    INSERT INTO plata.registros_rechazados (origen, llave_registro, motivo)
    SELECT N'Entregas', e.ID_Envio, CONCAT(N'Pedido ', e.ID_Pedido, N' no existe en ventas (entrega huérfana)')
    FROM #Entregas_Std AS e
    LEFT JOIN plata.fact_pedido AS p ON p.pedido_id = e.ID_Pedido
    WHERE p.pedido_id IS NULL;

    DELETE e
    FROM #Entregas_Std AS e
    LEFT JOIN plata.fact_pedido AS p ON p.pedido_id = e.ID_Pedido
    WHERE p.pedido_id IS NULL;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Validación', N'Entregas', N'Entregas huérfanas rechazadas (LEFT JOIN con Pedido)', @n);

    INSERT INTO plata.registros_rechazados (origen, llave_registro, motivo)
    SELECT N'Entregas', e.ID_Envio, N'Fecha de entrega anterior a la fecha del pedido'
    FROM #Entregas_Std AS e JOIN plata.fact_pedido AS p ON p.pedido_id = e.ID_Pedido
    WHERE e.Fecha_Entrega < p.fecha;
    DELETE e FROM #Entregas_Std AS e JOIN plata.fact_pedido AS p ON p.pedido_id = e.ID_Pedido WHERE e.Fecha_Entrega < p.fecha;

    -- 4.3 Imputación de logística (indicada en el dataset del proyecto) --------
    --   Minutos_Demora  -> MEDIANA del conjunto (robusta ante valores extremos)
    --   Calificación    -> MODA (valor más frecuente; si hay empate, el menor)

    SELECT TOP (1) @Mediana = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Minutos_Demora) OVER ()
    FROM #Entregas_Std
    WHERE Minutos_Demora IS NOT NULL;
    SET @MedianaEntera = CAST(ROUND(@Mediana, 0) AS INT);

    SELECT TOP (1) @Moda = Calificacion_Cliente
    FROM #Entregas_Std
    WHERE Calificacion_Cliente IS NOT NULL
    GROUP BY Calificacion_Cliente
    ORDER BY COUNT(*) DESC, Calificacion_Cliente ASC;

    IF @mostrar_detalle = 1 SELECT @Mediana AS Mediana_Minutos_Demora, @MedianaEntera AS Valor_Imputado_Demora, @Moda AS Moda_Calificacion;

    SELECT @n = COUNT(*) FROM #Entregas_Std WHERE Minutos_Demora IS NULL;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Imputación', N'Entregas', CONCAT(N'Minutos_Demora nulos imputados con la mediana = ', @MedianaEntera), @n);
    SELECT @n = COUNT(*) FROM #Entregas_Std WHERE Calificacion_Cliente IS NULL;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Imputación', N'Entregas', CONCAT(N'Calificaciones faltantes imputadas con la moda = ', @Moda), @n);

    UPDATE #Entregas_Std
    SET Demora_Imputada       = CASE WHEN Minutos_Demora       IS NULL THEN 1 ELSE 0 END,
        Calificacion_Imputada = CASE WHEN Calificacion_Cliente IS NULL THEN 1 ELSE 0 END,
        Minutos_Demora        = ISNULL(Minutos_Demora, @MedianaEntera),
        Calificacion_Cliente  = COALESCE(Calificacion_Cliente, @Moda);

    INSERT INTO plata.fact_entrega (envio_id, pedido_id, fecha_entrega, minutos_demora, calificacion_cliente, demora_imputada, calificacion_imputada)
    SELECT e.ID_Envio, e.ID_Pedido, e.Fecha_Entrega, e.Minutos_Demora, e.Calificacion_Cliente, e.Demora_Imputada, e.Calificacion_Imputada
    FROM #Entregas_Std AS e
    INNER JOIN plata.fact_pedido AS p ON p.pedido_id = e.ID_Pedido;
    SET @n = @@ROWCOUNT;
    INSERT INTO plata.bitacora_limpieza (fase, tabla, accion, registros) VALUES (N'4-Carga', N'plata.fact_entrega', N'Entregas cargadas al modelo', @n);

    /* ---------- RESULTADOS ---------- */
    SELECT x.entidad, x.registros_bronce, x.registros_plata, x.registros_bronce - x.registros_plata AS diferencia
    FROM (
        SELECT N'clientes' AS entidad, (SELECT COUNT(*) FROM bronce.clientes_raw) AS registros_bronce,
               (SELECT COUNT(*) FROM plata.dim_cliente WHERE cliente_id <> 'CLI-000') AS registros_plata
        UNION ALL SELECT N'pedidos',  (SELECT COUNT(*) FROM bronce.ventas_raw),   (SELECT COUNT(*) FROM plata.fact_pedido)
        UNION ALL SELECT N'clima',    (SELECT COUNT(*) FROM bronce.clima_raw),    (SELECT COUNT(*) FROM plata.fact_clima_diario)
        UNION ALL SELECT N'entregas', (SELECT COUNT(*) FROM bronce.entregas_raw), (SELECT COUNT(*) FROM plata.fact_entrega)
    ) AS x;

    SELECT paso_id, fase, tabla, accion, registros FROM plata.bitacora_limpieza ORDER BY paso_id;
END;
GO

/* =====================================================================
   SECCIÓN C · REGISTRO CONTROLADO DE CLIENTES (validación en la entrada)
   ===================================================================== */
/* SP 1 · INSERCIÓN CONTROLADA CON VALIDACIÓN */
CREATE OR ALTER PROCEDURE plata.sp_registrar_cliente
    @nombre_completo     NVARCHAR(100),
    @email               VARCHAR(120),
    @telefono            VARCHAR(15)  = NULL,
    @ciudad              NVARCHAR(50),
    @cliente_id_generado VARCHAR(10)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Limpieza previa de cadenas
    DECLARE @nombre_limpio NVARCHAR(100) = UPPER(TRIM(@nombre_completo)),
            @email_limpio  VARCHAR(120)  = LOWER(TRIM(@email)),
            @tel_limpio    VARCHAR(15)   = NULLIF(TRIM(@telefono), ''),
            @ciudad_id     TINYINT;

    SELECT @ciudad_id = ciudad_id
    FROM plata.dim_ciudad
    WHERE nombre_ciudad COLLATE Latin1_General_CI_AI = TRIM(@ciudad) COLLATE Latin1_General_CI_AI;

    BEGIN TRY
        -- 2) Validaciones
        IF @nombre_limpio IS NULL OR @nombre_limpio = N''
            RAISERROR('El nombre del cliente es obligatorio.', 16, 1);

        IF @email_limpio IS NULL OR @email_limpio NOT LIKE '%_@_%._%'
            RAISERROR('El email "%s" no tiene un formato válido.', 16, 1, @email_limpio);

        IF @ciudad_id IS NULL
            RAISERROR('La ciudad indicada no existe en el catálogo (LEÓN, SILAO, GUANAJUATO).', 16, 1);

        IF EXISTS (SELECT 1 FROM plata.dim_cliente WHERE email = @email_limpio)
            RAISERROR('Ya existe un cliente registrado con el email "%s". No se insertó el duplicado.', 16, 1, @email_limpio);

        -- 3) Inserción
        BEGIN TRANSACTION;

            SELECT @cliente_id_generado = 'CLI-' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(cliente_id, 5, 6) AS INT)), 0) + 1 AS VARCHAR(6)), 3)
            FROM plata.dim_cliente WITH (UPDLOCK, HOLDLOCK);

            INSERT INTO plata.dim_cliente (cliente_id, nombre_completo, email, telefono, ciudad_id, fecha_registro)
            VALUES (@cliente_id_generado, @nombre_limpio, @email_limpio, @tel_limpio, @ciudad_id, CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;

        SELECT N'Cliente registrado correctamente' AS resultado, @cliente_id_generado AS cliente_id,
               @nombre_limpio AS nombre, @email_limpio AS email;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- re-lanza el error original al usuario
    END CATCH
END;
GO
GO

/* =====================================================================
   SECCIÓN D · EJECUCIÓN DEL PIPELINE Y PRUEBAS DE CALIDAD
   Ejecutar el procedimiento DOS veces demuestra la idempotencia:
   los conteos de plata son iguales en la 1.ª y en la 2.ª ejecución.
   ===================================================================== */
EXEC plata.sp_limpiar_y_cargar_plata;
GO

/* Pruebas de calidad de plata: todas las filas deben decir ✔ PASA */
SET NOCOUNT ON;
DECLARE @pruebas TABLE (id INT IDENTITY(1,1), categoria NVARCHAR(30), prueba NVARCHAR(150), esperado NVARCHAR(30), obtenido NVARCHAR(30));

-- A.1 Conciliación de volúmenes
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Conciliación', N'Clientes cargados (40 + CLI-000)', N'41', CAST((SELECT COUNT(*) FROM plata.dim_cliente) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Pedidos cargados (135 crudos - 6 duplicados)', N'129', CAST((SELECT COUNT(*) FROM plata.fact_pedido) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros de clima (65 crudos - 2 duplicados)', N'63', CAST((SELECT COUNT(*) FROM plata.fact_clima_diario) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Entregas (107 - 3 duplicados - 1 huérfana)', N'103', CAST((SELECT COUNT(*) FROM plata.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros rechazados (ENV-999 sin pedido)', N'1', CAST((SELECT COUNT(*) FROM plata.registros_rechazados) AS NVARCHAR(30));

-- A.2 Completitud
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Completitud', N'Entregas con demora o calificación nula', N'0',
       CAST((SELECT COUNT(*) FROM plata.fact_entrega WHERE minutos_demora IS NULL OR calificacion_cliente IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Clima con temperatura nula', N'0',
       CAST((SELECT COUNT(*) FROM plata.fact_clima_diario WHERE temperatura_c IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Pedidos sin clima para su fecha y ciudad', N'0',
       CAST((SELECT COUNT(*) FROM plata.fact_pedido p JOIN plata.dim_sucursal s ON s.sucursal_id = p.sucursal_id
              LEFT JOIN plata.fact_clima_diario c ON c.fecha = p.fecha AND c.ciudad_id = s.ciudad_id WHERE c.clima_id IS NULL) AS NVARCHAR(30));

-- A.3 Unicidad
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Unicidad', N'Pedidos con más de una entrega', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT pedido_id FROM plata.fact_entrega GROUP BY pedido_id HAVING COUNT(*) > 1) d) AS NVARCHAR(30))
UNION ALL SELECT N'Unicidad', N'Emails de cliente repetidos', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT email FROM plata.dim_cliente GROUP BY email HAVING COUNT(*) > 1) d) AS NVARCHAR(30));

-- A.4 Validez
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Validez', N'Montos negativos', N'0', CAST((SELECT COUNT(*) FROM plata.fact_pedido WHERE monto_total < 0) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Calificaciones fuera de 1-5', N'0', CAST((SELECT COUNT(*) FROM plata.fact_entrega WHERE calificacion_cliente NOT BETWEEN 1 AND 5) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Entregas anteriores a su pedido', N'0',
       CAST((SELECT COUNT(*) FROM plata.fact_entrega e JOIN plata.fact_pedido p ON p.pedido_id = e.pedido_id WHERE e.fecha_entrega < p.fecha) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Textos con espacios sobrantes (dim_cliente.nombre_completo)', N'0',
       CAST((SELECT COUNT(*) FROM plata.dim_cliente WHERE DATALENGTH(nombre_completo) <> DATALENGTH(TRIM(nombre_completo)) OR nombre_completo LIKE N'%  %') AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Emails con mayúsculas', N'0',
       CAST((SELECT COUNT(*) FROM plata.dim_cliente WHERE email COLLATE Latin1_General_CS_AS <> LOWER(email)) AS NVARCHAR(30));

-- A.5 Imputación
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Imputación', N'Demoras imputadas con la mediana', N'8', CAST((SELECT SUM(CAST(demora_imputada AS INT)) FROM plata.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Calificaciones imputadas con la moda', N'11', CAST((SELECT SUM(CAST(calificacion_imputada AS INT)) FROM plata.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-103: minutos_demora (mediana)', N'30', CAST((SELECT minutos_demora FROM plata.fact_entrega WHERE pedido_id = 'PED-103') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-105: calificación (moda)', N'4', CAST((SELECT calificacion_cliente FROM plata.fact_entrega WHERE pedido_id = 'PED-105') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Temperaturas imputadas (promedio por ciudad)', N'2', CAST((SELECT SUM(CAST(temperatura_imputada AS INT)) FROM plata.fact_clima_diario) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Pedidos asignados a CLI-000 (COALESCE)', N'2', CAST((SELECT COUNT(*) FROM plata.fact_pedido WHERE cliente_id = 'CLI-000') AS NVARCHAR(30));

SELECT id, categoria, prueba, esperado, obtenido,
       CASE WHEN esperado = obtenido THEN N'✔ PASA' ELSE N'✘ FALLA' END AS resultado
FROM @pruebas
ORDER BY id;

SELECT COUNT(*) AS total_pruebas,
       SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) AS pasan,
       SUM(CASE WHEN esperado <> obtenido OR obtenido IS NULL THEN 1 ELSE 0 END) AS fallan
FROM @pruebas;
GO

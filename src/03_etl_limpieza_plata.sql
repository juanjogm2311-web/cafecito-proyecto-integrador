/*
CAFECITO · EQUIPO 1 · GRUPO O3
03_etl_limpieza_plata.sql
Diagnóstico, estandarización, deduplicación, validación e integración.
La capa dbo normalizada/dimensional representa la información limpia
equivalente a Plata. El script 10 migra nombres al estándar snake_case.
*/
/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 04 · FASE 1 - DIAGNÓSTICO (perfilado de datos crudos)
   Responsable: Paulina Karime Martínez Rivera (Data Quality & QA Specialist)
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;

/* 1.1 VOLUMEN POR ORIGEN */
SELECT 'Clientes (SQL)' AS Origen, COUNT(*) AS Registros FROM stg.Clientes_Raw
UNION ALL SELECT 'Ventas (SQL)',     COUNT(*) FROM stg.Ventas_Raw
UNION ALL SELECT 'Clima (JSON)',     COUNT(*) FROM stg.Clima_Raw
UNION ALL SELECT 'Entregas (CSV)',   COUNT(*) FROM stg.Entregas_Raw;

/* 1.2 NULOS O VACÍOS POR COLUMNA */
SELECT 'Ventas' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(ID_Cliente), '')  IS NULL THEN 1 ELSE 0 END) AS Nulos_ID_Cliente,
       SUM(CASE WHEN NULLIF(TRIM(Monto_Total), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Monto,
       SUM(CASE WHEN NULLIF(TRIM(Fecha_Hora), '')  IS NULL THEN 1 ELSE 0 END) AS Nulos_Fecha
FROM stg.Ventas_Raw;

SELECT 'Clientes' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Telefono), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Telefono,
       SUM(CASE WHEN NULLIF(TRIM(Email), '')    IS NULL THEN 1 ELSE 0 END) AS Nulos_Email
FROM stg.Clientes_Raw;

SELECT 'Clima' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Temperatura_C), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Temperatura,
       SUM(CASE WHEN NULLIF(TRIM(Humedad_Pct), '')   IS NULL THEN 1 ELSE 0 END) AS Nulos_Humedad
FROM stg.Clima_Raw;

SELECT 'Entregas' AS Origen,
       SUM(CASE WHEN NULLIF(TRIM(Minutos_Demora), '')       IS NULL THEN 1 ELSE 0 END) AS Nulos_Minutos_Demora,
       SUM(CASE WHEN NULLIF(TRIM(Calificacion_Cliente), '') IS NULL THEN 1 ELSE 0 END) AS Nulos_Calificacion
FROM stg.Entregas_Raw;

/* 1.3 ESPACIOS EXTRA Y VARIANTES DE ESCRITURA */
SELECT 'Ventas.Tipo_Producto' AS Campo,
       SUM(CASE WHEN DATALENGTH(Tipo_Producto) <> DATALENGTH(TRIM(Tipo_Producto)) OR Tipo_Producto LIKE '%  %' THEN 1 ELSE 0 END) AS Con_Espacios_Extra
FROM stg.Ventas_Raw
UNION ALL
SELECT 'Ventas.ID_Sucursal',
       SUM(CASE WHEN DATALENGTH(ID_Sucursal) <> DATALENGTH(TRIM(ID_Sucursal)) THEN 1 ELSE 0 END)
FROM stg.Ventas_Raw
UNION ALL
SELECT 'Clientes.Nombre',
       SUM(CASE WHEN DATALENGTH(Nombre) <> DATALENGTH(TRIM(Nombre)) OR Nombre LIKE '%  %' THEN 1 ELSE 0 END)
FROM stg.Clientes_Raw
UNION ALL
SELECT 'Clientes.Email',
       SUM(CASE WHEN DATALENGTH(Email) <> DATALENGTH(TRIM(Email)) OR Email COLLATE Latin1_General_CS_AS <> LOWER(Email) THEN 1 ELSE 0 END)
FROM stg.Clientes_Raw
UNION ALL
SELECT 'Entregas.ID_Pedido',
       SUM(CASE WHEN DATALENGTH(ID_Pedido) <> DATALENGTH(TRIM(ID_Pedido)) OR ID_Pedido COLLATE Latin1_General_CS_AS <> UPPER(ID_Pedido) THEN 1 ELSE 0 END)
FROM stg.Entregas_Raw;

-- Variantes de escritura de una misma categoría / ciudad.
-- Se agrupa con COLLATE Latin1_General_BIN y entre corchetes para que
-- 'Leon', 'LEON' y 'Leon ' cuenten como valores DISTINTOS (si no, la
-- intercalación CI de la BD los juntaría y escondería el problema).
SELECT Valor_Crudo AS Tipo_Producto_Crudo, COUNT(*) AS Veces
FROM (SELECT (N'[' + Tipo_Producto + N']') COLLATE Latin1_General_BIN AS Valor_Crudo FROM stg.Ventas_Raw) AS x
GROUP BY Valor_Crudo
ORDER BY Valor_Crudo;

SELECT Origen, Valor_Crudo AS Ciudad_Cruda, COUNT(*) AS Veces
FROM (
    SELECT 'Ventas'   AS Origen, (N'[' + Sucursal_Ciudad + N']') COLLATE Latin1_General_BIN AS Valor_Crudo FROM stg.Ventas_Raw
    UNION ALL
    SELECT 'Clima',              (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN                  FROM stg.Clima_Raw
    UNION ALL
    SELECT 'Clientes',           (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN                  FROM stg.Clientes_Raw
) AS x
GROUP BY Origen, Valor_Crudo
ORDER BY Origen, Valor_Crudo;

/* 1.4 TIPOS DE DATO INVÁLIDOS */
SELECT ID_Pedido, Monto_Total AS Monto_Crudo
FROM stg.Ventas_Raw
WHERE TRY_CONVERT(DECIMAL(10,2), TRIM(Monto_Total)) IS NULL;           -- ej. '$180.00'

SELECT Fecha_Consulta, Ciudad, Temperatura_C, Humedad_Pct
FROM stg.Clima_Raw
WHERE TRY_CONVERT(DECIMAL(4,1), Temperatura_C) IS NULL OR TRY_CONVERT(INT, Humedad_Pct) IS NULL;

-- Tipos dentro del JSON original de la API: OPENJSON sin WITH devuelve [type]
--   0 = null, 1 = string (texto), 2 = number. Temperatura y Humedad DEBEN ser 2.
SELECT j.[key] AS Posicion_En_Arreglo, p.[key] AS Campo, p.[value] AS Valor,
       CASE p.[type] WHEN 0 THEN 'NULL' WHEN 1 THEN 'TEXTO (debería ser número)' ELSE 'OTRO' END AS Tipo_Detectado
FROM stg.Clima_JSON_Raw AS r
CROSS APPLY OPENJSON(r.Respuesta_JSON) AS j
CROSS APPLY OPENJSON(j.[value]) AS p
WHERE p.[key] IN (N'Temperatura_C', N'Humedad_Pct') AND p.[type] <> 2;

/* 1.5 VALORES FUERA DE RANGO */
SELECT 'Monto negativo' AS Regla, ID_Pedido AS Llave, Monto_Total AS Valor
FROM stg.Ventas_Raw WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(TRIM(Monto_Total), '$', '')) < 0
UNION ALL
SELECT 'Humedad fuera de 0-100', Fecha_Consulta + ' ' + Ciudad, Humedad_Pct
FROM stg.Clima_Raw WHERE TRY_CONVERT(INT, Humedad_Pct) NOT BETWEEN 0 AND 100
UNION ALL
SELECT 'Demora negativa', ID_Envio, Minutos_Demora
FROM stg.Entregas_Raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Minutos_Demora), '')) < 0
UNION ALL
SELECT 'Calificación fuera de 1-5', ID_Envio, Calificacion_Cliente
FROM stg.Entregas_Raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Calificacion_Cliente), '')) NOT BETWEEN 1 AND 5;

/* 1.6 DUPLICADOS (reintentos de ingesta) */
SELECT 'Ventas' AS Origen, UPPER(TRIM(ID_Pedido)) AS Llave, COUNT(*) AS Veces
FROM stg.Ventas_Raw GROUP BY UPPER(TRIM(ID_Pedido)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clientes', UPPER(TRIM(ID_Cliente)), COUNT(*)
FROM stg.Clientes_Raw GROUP BY UPPER(TRIM(ID_Cliente)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Entregas', UPPER(TRIM(ID_Envio)), COUNT(*)
FROM stg.Entregas_Raw GROUP BY UPPER(TRIM(ID_Envio)) HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clima', Fecha_Consulta + ' | ' + UPPER(TRIM(Ciudad)), COUNT(*)
FROM stg.Clima_Raw GROUP BY Fecha_Consulta, UPPER(TRIM(Ciudad)) HAVING COUNT(*) > 1
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
FROM stg.Entregas_Raw
GROUP BY CASE
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]' THEN 'aaaa/mm/dd'
           WHEN Fecha_Entrega LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' THEN 'aaaa-mm-dd (ISO)'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]' THEN 'dd/mm/aaaa'
           WHEN Fecha_Entrega LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN 'dd-mm-aaaa'
           ELSE 'FORMATO NO RECONOCIDO'
         END;

/* 1.8 INTEGRIDAD REFERENCIAL: entregas cuyo pedido no existe en ventas */
SELECT e.ID_Envio, e.ID_Pedido AS ID_Pedido_Crudo
FROM stg.Entregas_Raw AS e
LEFT JOIN (SELECT DISTINCT UPPER(TRIM(ID_Pedido)) AS ID_Pedido FROM stg.Ventas_Raw) AS v
       ON v.ID_Pedido = UPPER(TRIM(e.ID_Pedido))
WHERE v.ID_Pedido IS NULL;

/* 1.9 RESUMEN DE ANOMALÍAS (esta tabla va en el documento, Fase 1) */
SELECT Origen, Anomalia, Registros_Afectados
FROM (
    SELECT 1 AS Orden, 'Ventas (SQL)' AS Origen, 'Duplicados por reintento de ingesta' AS Anomalia,
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Pedido))) FROM stg.Ventas_Raw) AS Registros_Afectados
    UNION ALL SELECT 2, 'Ventas (SQL)', 'Tipo_Producto con espacios / mayúsculas / sin acento',
           (SELECT COUNT(*) FROM stg.Ventas_Raw
             WHERE Tipo_Producto COLLATE Latin1_General_CS_AS NOT IN (N'Bebida Caliente', N'Bebida Fría', N'Repostería')
                OR DATALENGTH(Tipo_Producto) <> DATALENGTH(TRIM(Tipo_Producto)))
    UNION ALL SELECT 3, 'Ventas (SQL)', 'ID_Sucursal con espacios o minúsculas',
           (SELECT COUNT(*) FROM stg.Ventas_Raw
             WHERE DATALENGTH(ID_Sucursal) <> DATALENGTH(TRIM(ID_Sucursal)) OR ID_Sucursal COLLATE Latin1_General_CS_AS <> UPPER(ID_Sucursal))
    UNION ALL SELECT 4, 'Ventas (SQL)', 'Monto negativo',
           (SELECT COUNT(*) FROM stg.Ventas_Raw WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(TRIM(Monto_Total), '$', '')) < 0)
    UNION ALL SELECT 5, 'Ventas (SQL)', 'Monto con símbolo $ (tipo inválido)',
           (SELECT COUNT(*) FROM stg.Ventas_Raw WHERE Monto_Total LIKE '%$%')
    UNION ALL SELECT 6, 'Ventas (SQL)', 'Pedido sin ID_Cliente (nulo)',
           (SELECT COUNT(*) FROM stg.Ventas_Raw WHERE NULLIF(TRIM(ID_Cliente), '') IS NULL)
    UNION ALL SELECT 7, 'Clientes (SQL)', 'Duplicados por reintento de ingesta',
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Cliente))) FROM stg.Clientes_Raw)
    UNION ALL SELECT 8, 'Clientes (SQL)', 'Nombre / Email con espacios o mayúsculas',
           (SELECT COUNT(*) FROM stg.Clientes_Raw
             WHERE DATALENGTH(Nombre) <> DATALENGTH(TRIM(Nombre)) OR Nombre LIKE '%  %'
                OR Nombre COLLATE Latin1_General_CS_AS = UPPER(Nombre) OR Nombre COLLATE Latin1_General_CS_AS = LOWER(Nombre)
                OR DATALENGTH(Email) <> DATALENGTH(TRIM(Email)) OR Email COLLATE Latin1_General_CS_AS <> LOWER(Email))
    UNION ALL SELECT 9, 'Clientes (SQL)', 'Teléfono nulo',
           (SELECT COUNT(*) FROM stg.Clientes_Raw WHERE NULLIF(TRIM(Telefono), '') IS NULL)
    UNION ALL SELECT 10, 'Clima (JSON)', 'Duplicados por reintento de la API',
           (SELECT COUNT(*) - COUNT(DISTINCT Fecha_Consulta + N'|' + UPPER(TRIM(Ciudad))) FROM stg.Clima_Raw)
    UNION ALL SELECT 11, 'Clima (JSON)', 'Ciudad con variantes (León, GTO, espacios)',
           (SELECT COUNT(*) FROM stg.Clima_Raw WHERE Ciudad COLLATE Latin1_General_CS_AS NOT IN (N'Leon', N'Silao', N'Guanajuato'))
    UNION ALL SELECT 12, 'Clima (JSON)', 'Temperatura como texto en el JSON (tipo inconsistente)',
           (SELECT COUNT(*) FROM stg.Clima_JSON_Raw AS r CROSS APPLY OPENJSON(r.Respuesta_JSON) AS j CROSS APPLY OPENJSON(j.[value]) AS p
             WHERE p.[key] = N'Temperatura_C' AND p.[type] = 1)
    UNION ALL SELECT 13, 'Clima (JSON)', 'Temperatura nula',
           (SELECT COUNT(*) FROM stg.Clima_Raw WHERE NULLIF(TRIM(Temperatura_C), '') IS NULL)
    UNION ALL SELECT 14, 'Clima (JSON)', 'Humedad fuera de rango 0-100',
           (SELECT COUNT(*) FROM stg.Clima_Raw WHERE TRY_CONVERT(INT, Humedad_Pct) NOT BETWEEN 0 AND 100)
    UNION ALL SELECT 15, 'Entregas (CSV)', 'Duplicados por reintento de ingesta',
           (SELECT COUNT(*) - COUNT(DISTINCT UPPER(TRIM(ID_Envio))) FROM stg.Entregas_Raw)
    UNION ALL SELECT 16, 'Entregas (CSV)', 'Fecha en formato distinto a ISO',
           (SELECT COUNT(*) FROM stg.Entregas_Raw WHERE Fecha_Entrega NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
    UNION ALL SELECT 17, 'Entregas (CSV)', 'Minutos_Demora vacío',
           (SELECT COUNT(*) FROM stg.Entregas_Raw WHERE NULLIF(TRIM(Minutos_Demora), '') IS NULL)
    UNION ALL SELECT 18, 'Entregas (CSV)', 'Minutos_Demora negativo',
           (SELECT COUNT(*) FROM stg.Entregas_Raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Minutos_Demora), '')) < 0)
    UNION ALL SELECT 19, 'Entregas (CSV)', 'Calificación vacía',
           (SELECT COUNT(*) FROM stg.Entregas_Raw WHERE NULLIF(TRIM(Calificacion_Cliente), '') IS NULL)
    UNION ALL SELECT 20, 'Entregas (CSV)', 'Calificación fuera de 1-5',
           (SELECT COUNT(*) FROM stg.Entregas_Raw WHERE TRY_CONVERT(INT, NULLIF(TRIM(Calificacion_Cliente), '')) NOT BETWEEN 1 AND 5)
    UNION ALL SELECT 21, 'Entregas (CSV)', 'ID_Pedido con espacios o minúsculas',
           (SELECT COUNT(*) FROM stg.Entregas_Raw
             WHERE DATALENGTH(ID_Pedido) <> DATALENGTH(TRIM(ID_Pedido)) OR ID_Pedido COLLATE Latin1_General_CS_AS <> UPPER(ID_Pedido))
    UNION ALL SELECT 22, 'Entregas (CSV)', 'Entrega sin pedido existente (huérfana)',
           (SELECT COUNT(*) FROM stg.Entregas_Raw AS e
             WHERE NOT EXISTS (SELECT 1 FROM stg.Ventas_Raw AS v WHERE UPPER(TRIM(v.ID_Pedido)) = UPPER(TRIM(e.ID_Pedido))))
) AS r
ORDER BY Orden;
GO


/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 05 · PIPELINE DE LIMPIEZA: FASES 2, 3 y 4 + CARGA AL MODELO
   Responsable: Ana Sofía Arroniz Domínguez (Data Engineer / Pipeline Lead)
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;

/* ---------- 0. Reinicio (permite volver a ejecutar este script) ---------- */
DELETE FROM dbo.Entrega;
DELETE FROM dbo.Pedido;
DELETE FROM dbo.Clima_Diario;
DELETE FROM dbo.Cliente WHERE ID_Cliente <> 'CLI-000';
TRUNCATE TABLE stg.Registros_Rechazados;

DROP TABLE IF EXISTS stg.Bitacora_Limpieza;
CREATE TABLE stg.Bitacora_Limpieza (
    ID_Paso    INT IDENTITY(1,1) PRIMARY KEY,
    Fase       NVARCHAR(30)  NOT NULL,
    Tabla      NVARCHAR(30)  NOT NULL,
    Accion     NVARCHAR(200) NOT NULL,
    Registros  INT           NOT NULL,
    Fecha      DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);
GO

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
DROP TABLE IF EXISTS stg.Clientes_Std;
DROP TABLE IF EXISTS stg.Ventas_Std;
DROP TABLE IF EXISTS stg.Clima_Std;
DROP TABLE IF EXISTS stg.Entregas_Std;

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
INTO stg.Clientes_Std
FROM stg.Clientes_Raw AS r;

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
INTO stg.Ventas_Std
FROM stg.Ventas_Raw AS r
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
INTO stg.Clima_Std
FROM stg.Clima_Raw AS r;

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
INTO stg.Entregas_Std
FROM stg.Entregas_Raw AS r
CROSS APPLY (SELECT TRIM(r.Fecha_Entrega) AS F) AS f;

-- Evidencia de la Fase 2
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros)
SELECT N'2-Estandarización', N'Ventas', N'Variantes de Tipo_Producto en origen (se unifican a 3 categorías)',
       COUNT(DISTINCT (N'[' + Tipo_Producto + N']') COLLATE Latin1_General_BIN) FROM stg.Ventas_Raw
UNION ALL
SELECT N'2-Estandarización', N'Ventas', N'Variantes de Sucursal_Ciudad en origen (se unifican a ID_Ciudad)',
       COUNT(DISTINCT (N'[' + Sucursal_Ciudad + N']') COLLATE Latin1_General_BIN) FROM stg.Ventas_Raw
UNION ALL
SELECT N'2-Estandarización', N'Clima', N'Variantes de Ciudad en el JSON (se unifican a ID_Ciudad)',
       COUNT(DISTINCT (N'[' + Ciudad + N']') COLLATE Latin1_General_BIN) FROM stg.Clima_Raw
UNION ALL
SELECT N'2-Estandarización', N'Entregas', N'Fechas convertidas de formato no ISO a DATE',
       COUNT(*) FROM stg.Entregas_Raw WHERE TRIM(Fecha_Entrega) NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
UNION ALL
SELECT N'2-Estandarización', N'Ventas', N'Montos con símbolo $ convertidos a DECIMAL',
       COUNT(*) FROM stg.Ventas_Raw WHERE Monto_Total LIKE N'%$%';

-- Control: nada debe quedar sin mapear (resultado esperado: 0 filas)
SELECT 'Ventas sin categoría o ciudad' AS Control, COUNT(*) AS Filas FROM stg.Ventas_Std WHERE ID_Categoria IS NULL OR ID_Ciudad_Origen IS NULL OR Fecha_Hora IS NULL
UNION ALL SELECT 'Clima sin ciudad o fecha', COUNT(*) FROM stg.Clima_Std WHERE ID_Ciudad IS NULL OR Fecha IS NULL
UNION ALL SELECT 'Entregas sin fecha válida', COUNT(*) FROM stg.Entregas_Std WHERE Fecha_Entrega IS NULL
UNION ALL SELECT 'Clientes sin ciudad', COUNT(*) FROM stg.Clientes_Std WHERE ID_Ciudad IS NULL;

-- Antes vs. después (captura para el documento)
SELECT TOP (12) r.ID_Envio, r.ID_Pedido AS ID_Pedido_Crudo, s.ID_Pedido AS ID_Pedido_Limpio,
       r.Fecha_Entrega AS Fecha_Cruda, s.Fecha_Entrega AS Fecha_ISO
FROM stg.Entregas_Raw AS r
JOIN stg.Entregas_Std AS s ON s.ID_Carga = r.ID_Carga
ORDER BY r.ID_Carga;
GO

/* =====================================================================
   FASE 3 · DEDUPLICACIÓN
   1) Se COMPRUEBA que las copias son idénticas (Versiones_Distintas = 1),
      es decir, que de verdad son reintentos y no datos distintos.
   2) Se conserva la primera llegada (menor ID_Carga) con ROW_NUMBER().
   ===================================================================== */
DECLARE @n INT;

-- 3.1 Comprobación previa
SELECT 'Ventas' AS Tabla, ID_Pedido AS Llave, COUNT(*) AS Copias,
       COUNT(DISTINCT CONCAT(ID_Cliente, '|', CONVERT(VARCHAR(19), Fecha_Hora, 120), '|', ID_Sucursal, '|', ID_Categoria, '|', Monto_Total)) AS Versiones_Distintas
FROM stg.Ventas_Std GROUP BY ID_Pedido HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clientes', ID_Cliente, COUNT(*),
       COUNT(DISTINCT CONCAT(Nombre_Completo, '|', Email, '|', Telefono, '|', ID_Ciudad))
FROM stg.Clientes_Std GROUP BY ID_Cliente HAVING COUNT(*) > 1
UNION ALL
SELECT 'Entregas', ID_Envio, COUNT(*),
       COUNT(DISTINCT CONCAT(ID_Pedido, '|', Fecha_Entrega, '|', Minutos_Demora, '|', Calificacion_Cliente))
FROM stg.Entregas_Std GROUP BY ID_Envio HAVING COUNT(*) > 1
UNION ALL
SELECT 'Clima', CONCAT(CONVERT(VARCHAR(10), Fecha, 23), ' | ', ID_Ciudad), COUNT(*),
       COUNT(DISTINCT CONCAT(Temperatura_C, '|', Condicion_Climatica, '|', Humedad_Pct))
FROM stg.Clima_Std GROUP BY Fecha, ID_Ciudad HAVING COUNT(*) > 1;

-- 3.2 Eliminación con ROW_NUMBER()
WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Pedido ORDER BY ID_Carga) AS rn FROM stg.Ventas_Std)
DELETE FROM d WHERE rn > 1;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'3-Deduplicación', N'Ventas', N'Pedidos duplicados eliminados (ROW_NUMBER)', @n);

WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Cliente ORDER BY ID_Carga) AS rn FROM stg.Clientes_Std)
DELETE FROM d WHERE rn > 1;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'3-Deduplicación', N'Clientes', N'Clientes duplicados eliminados (ROW_NUMBER)', @n);

WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY Fecha, ID_Ciudad ORDER BY ID_Carga) AS rn FROM stg.Clima_Std)
DELETE FROM d WHERE rn > 1;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'3-Deduplicación', N'Clima', N'Registros de clima duplicados eliminados (Fecha + Ciudad)', @n);

WITH d AS (SELECT ROW_NUMBER() OVER (PARTITION BY ID_Envio ORDER BY ID_Carga) AS rn FROM stg.Entregas_Std)
DELETE FROM d WHERE rn > 1;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'3-Deduplicación', N'Entregas', N'Envíos duplicados eliminados (ROW_NUMBER)', @n);
GO

/* =====================================================================
   FASE 4 · VALIDACIÓN Y ENRIQUECIMIENTO
   4.1 Reglas de negocio (ABS, rangos válidos)
   4.2 Integración relacional con LEFT JOIN a maestras (+ rechazos) y carga
   4.3 Imputación de faltantes (ISNULL / COALESCE, mediana, moda, promedio)
   ===================================================================== */
DECLARE @n INT;

-- 4.1 Reglas de negocio --------------------------------------------------
UPDATE stg.Ventas_Std SET Monto_Total = ABS(Monto_Total) WHERE Monto_Total < 0;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Ventas', N'Montos negativos corregidos con ABS', @n);

UPDATE stg.Entregas_Std SET Minutos_Demora = ABS(Minutos_Demora) WHERE Minutos_Demora < 0;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Entregas', N'Minutos de demora negativos corregidos con ABS', @n);

UPDATE stg.Entregas_Std SET Calificacion_Cliente = NULL WHERE Calificacion_Cliente NOT BETWEEN 1 AND 5;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Entregas', N'Calificaciones fuera de 1-5 marcadas como faltantes (se imputan)', @n);

UPDATE stg.Clima_Std SET Humedad_Pct = NULL WHERE Humedad_Pct NOT BETWEEN 0 AND 100;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Clima', N'Humedad fuera de 0-100 invalidada (queda NULL, no confiable)', @n);

UPDATE stg.Clima_Std SET Temperatura_C = NULL WHERE Temperatura_C NOT BETWEEN -10 AND 50;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Clima', N'Temperaturas fuera de -10 a 50 °C invalidadas', @n);

-- 4.2a CLIENTES: LEFT JOIN con Ciudad -> rechazo o carga -------------------
INSERT INTO stg.Registros_Rechazados (Origen, Llave_Registro, Motivo)
SELECT N'Clientes', ISNULL(c.ID_Cliente, N'(nulo)'), N'Ciudad no existe en catálogo, email o fecha inválidos'
FROM stg.Clientes_Std AS c
LEFT JOIN dbo.Ciudad AS ci ON ci.ID_Ciudad = c.ID_Ciudad
WHERE ci.ID_Ciudad IS NULL OR c.Email IS NULL OR c.Email NOT LIKE '%_@_%._%' OR c.Fecha_Registro IS NULL;

INSERT INTO dbo.Cliente (ID_Cliente, Nombre_Completo, Email, Telefono, ID_Ciudad, Fecha_Registro)
SELECT c.ID_Cliente, c.Nombre_Completo, c.Email, c.Telefono, c.ID_Ciudad, c.Fecha_Registro
FROM stg.Clientes_Std AS c
LEFT JOIN dbo.Ciudad AS ci ON ci.ID_Ciudad = c.ID_Ciudad
WHERE ci.ID_Ciudad IS NOT NULL AND c.Email LIKE '%_@_%._%' AND c.Fecha_Registro IS NOT NULL;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Carga', N'dbo.Cliente', N'Clientes cargados al modelo', @n);

-- 4.2b PEDIDOS: COALESCE cliente faltante + LEFT JOIN con 3 maestras --------
SELECT @n = COUNT(*) FROM stg.Ventas_Std WHERE ID_Cliente IS NULL;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Imputación', N'Ventas', N'Pedidos sin cliente asignados a CLI-000 (COALESCE)', @n);

INSERT INTO stg.Registros_Rechazados (Origen, Llave_Registro, Motivo)
SELECT N'Ventas', v.ID_Pedido, N'Cliente, sucursal o categoría inexistente / fecha o monto inválido'
FROM stg.Ventas_Std AS v
LEFT JOIN dbo.Cliente            AS cl ON cl.ID_Cliente   = COALESCE(v.ID_Cliente, 'CLI-000')
LEFT JOIN dbo.Sucursal           AS s  ON s.ID_Sucursal   = v.ID_Sucursal
LEFT JOIN dbo.Categoria_Producto AS ca ON ca.ID_Categoria = v.ID_Categoria
WHERE cl.ID_Cliente IS NULL OR s.ID_Sucursal IS NULL OR ca.ID_Categoria IS NULL
   OR v.Fecha_Hora IS NULL OR v.Monto_Total IS NULL;

INSERT INTO dbo.Pedido (ID_Pedido, ID_Cliente, ID_Sucursal, ID_Categoria, Fecha_Hora, Monto_Total)
SELECT v.ID_Pedido, cl.ID_Cliente, s.ID_Sucursal, ca.ID_Categoria, v.Fecha_Hora, v.Monto_Total
FROM stg.Ventas_Std AS v
LEFT JOIN dbo.Cliente            AS cl ON cl.ID_Cliente   = COALESCE(v.ID_Cliente, 'CLI-000')
LEFT JOIN dbo.Sucursal           AS s  ON s.ID_Sucursal   = v.ID_Sucursal
LEFT JOIN dbo.Categoria_Producto AS ca ON ca.ID_Categoria = v.ID_Categoria
WHERE cl.ID_Cliente IS NOT NULL AND s.ID_Sucursal IS NOT NULL AND ca.ID_Categoria IS NOT NULL
  AND v.Fecha_Hora IS NOT NULL AND v.Monto_Total IS NOT NULL;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Carga', N'dbo.Pedido', N'Pedidos cargados al modelo', @n);

-- Control de consistencia: la ciudad escrita en ventas coincide con la de la sucursal (esperado 0)
SELECT COUNT(*) AS Pedidos_Ciudad_Inconsistente
FROM stg.Ventas_Std AS v JOIN dbo.Sucursal AS s ON s.ID_Sucursal = v.ID_Sucursal
WHERE v.ID_Ciudad_Origen <> s.ID_Ciudad;

-- 4.2c + 4.3 CLIMA: imputación de temperatura con el promedio de su ciudad --
UPDATE c
SET    c.Temperatura_C        = p.Promedio_Ciudad,
       c.Temperatura_Imputada = 1
FROM stg.Clima_Std AS c
JOIN (SELECT ID_Ciudad, CAST(ROUND(AVG(Temperatura_C), 1) AS DECIMAL(4,1)) AS Promedio_Ciudad
      FROM stg.Clima_Std WHERE Temperatura_C IS NOT NULL GROUP BY ID_Ciudad) AS p
  ON p.ID_Ciudad = c.ID_Ciudad
WHERE c.Temperatura_C IS NULL;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Imputación', N'Clima', N'Temperaturas nulas imputadas con el promedio de su ciudad', @n);

INSERT INTO stg.Registros_Rechazados (Origen, Llave_Registro, Motivo)
SELECT N'Clima', CONCAT(CONVERT(VARCHAR(10), c.Fecha, 23), ' ', ISNULL(CAST(c.ID_Ciudad AS VARCHAR(3)), '?')), N'Ciudad/fecha inválida o condición no reconocida'
FROM stg.Clima_Std AS c
LEFT JOIN dbo.Ciudad AS ci ON ci.ID_Ciudad = c.ID_Ciudad
WHERE ci.ID_Ciudad IS NULL OR c.Fecha IS NULL
   OR c.Condicion_Climatica NOT IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO');

INSERT INTO dbo.Clima_Diario (Fecha, ID_Ciudad, Temperatura_C, Condicion_Climatica, Humedad_Pct, Temperatura_Imputada)
SELECT c.Fecha, c.ID_Ciudad, c.Temperatura_C, c.Condicion_Climatica, c.Humedad_Pct, c.Temperatura_Imputada
FROM stg.Clima_Std AS c
LEFT JOIN dbo.Ciudad AS ci ON ci.ID_Ciudad = c.ID_Ciudad
WHERE ci.ID_Ciudad IS NOT NULL AND c.Fecha IS NOT NULL
  AND c.Condicion_Climatica IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO');
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Carga', N'dbo.Clima_Diario', N'Registros de clima cargados al modelo', @n);

-- 4.2d ENTREGAS: LEFT JOIN con Pedido -> las huérfanas se rechazan ---------
INSERT INTO stg.Registros_Rechazados (Origen, Llave_Registro, Motivo)
SELECT N'Entregas', e.ID_Envio, CONCAT(N'Pedido ', e.ID_Pedido, N' no existe en ventas (entrega huérfana)')
FROM stg.Entregas_Std AS e
LEFT JOIN dbo.Pedido AS p ON p.ID_Pedido = e.ID_Pedido
WHERE p.ID_Pedido IS NULL;

DELETE e
FROM stg.Entregas_Std AS e
LEFT JOIN dbo.Pedido AS p ON p.ID_Pedido = e.ID_Pedido
WHERE p.ID_Pedido IS NULL;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Validación', N'Entregas', N'Entregas huérfanas rechazadas (LEFT JOIN con Pedido)', @n);

INSERT INTO stg.Registros_Rechazados (Origen, Llave_Registro, Motivo)
SELECT N'Entregas', e.ID_Envio, N'Fecha de entrega anterior a la fecha del pedido'
FROM stg.Entregas_Std AS e JOIN dbo.Pedido AS p ON p.ID_Pedido = e.ID_Pedido
WHERE e.Fecha_Entrega < p.Fecha;
DELETE e FROM stg.Entregas_Std AS e JOIN dbo.Pedido AS p ON p.ID_Pedido = e.ID_Pedido WHERE e.Fecha_Entrega < p.Fecha;

-- 4.3 Imputación de logística (indicada en el dataset del proyecto) --------
--   Minutos_Demora  -> MEDIANA del conjunto (robusta ante valores extremos)
--   Calificación    -> MODA (valor más frecuente; si hay empate, el menor)
DECLARE @Mediana FLOAT, @MedianaEntera INT, @Moda INT;

SELECT TOP (1) @Mediana = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Minutos_Demora) OVER ()
FROM stg.Entregas_Std
WHERE Minutos_Demora IS NOT NULL;
SET @MedianaEntera = CAST(ROUND(@Mediana, 0) AS INT);

SELECT TOP (1) @Moda = Calificacion_Cliente
FROM stg.Entregas_Std
WHERE Calificacion_Cliente IS NOT NULL
GROUP BY Calificacion_Cliente
ORDER BY COUNT(*) DESC, Calificacion_Cliente ASC;

SELECT @Mediana AS Mediana_Minutos_Demora, @MedianaEntera AS Valor_Imputado_Demora, @Moda AS Moda_Calificacion;

SELECT @n = COUNT(*) FROM stg.Entregas_Std WHERE Minutos_Demora IS NULL;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Imputación', N'Entregas', CONCAT(N'Minutos_Demora nulos imputados con la mediana = ', @MedianaEntera), @n);
SELECT @n = COUNT(*) FROM stg.Entregas_Std WHERE Calificacion_Cliente IS NULL;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Imputación', N'Entregas', CONCAT(N'Calificaciones faltantes imputadas con la moda = ', @Moda), @n);

UPDATE stg.Entregas_Std
SET Demora_Imputada       = CASE WHEN Minutos_Demora       IS NULL THEN 1 ELSE 0 END,
    Calificacion_Imputada = CASE WHEN Calificacion_Cliente IS NULL THEN 1 ELSE 0 END,
    Minutos_Demora        = ISNULL(Minutos_Demora, @MedianaEntera),
    Calificacion_Cliente  = COALESCE(Calificacion_Cliente, @Moda);

INSERT INTO dbo.Entrega (ID_Envio, ID_Pedido, Fecha_Entrega, Minutos_Demora, Calificacion_Cliente, Demora_Imputada, Calificacion_Imputada)
SELECT e.ID_Envio, e.ID_Pedido, e.Fecha_Entrega, e.Minutos_Demora, e.Calificacion_Cliente, e.Demora_Imputada, e.Calificacion_Imputada
FROM stg.Entregas_Std AS e
INNER JOIN dbo.Pedido AS p ON p.ID_Pedido = e.ID_Pedido;
SET @n = @@ROWCOUNT;
INSERT INTO stg.Bitacora_Limpieza (Fase, Tabla, Accion, Registros) VALUES (N'4-Carga', N'dbo.Entrega', N'Entregas cargadas al modelo', @n);
GO

/* ---------- RESUMEN DEL PIPELINE (captura para el documento) ---------- */
SELECT ID_Paso, Fase, Tabla, Accion, Registros FROM stg.Bitacora_Limpieza ORDER BY ID_Paso;
SELECT * FROM stg.Registros_Rechazados;

-- Casos señalados en la especificación del dataset
SELECT e.ID_Envio, e.ID_Pedido, e.Minutos_Demora, e.Demora_Imputada, e.Calificacion_Cliente, e.Calificacion_Imputada
FROM dbo.Entrega AS e
WHERE e.ID_Pedido IN ('PED-101', 'PED-102', 'PED-103', 'PED-104', 'PED-105')
ORDER BY e.ID_Pedido;
GO


/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   Script 10 · ESTANDARIZACIÓN DE NOMENCLATURA (minúsculas, snake_case, prefijos)
   Responsable: André Campos Díaz (Data Architect / SQL Specialist)
   Entrega 2 · Semana 9 (P9)

   QUÉ HACE: migra el modelo dbo de PascalCase (ID_Cliente, Fecha_Hora...) al estándar
   corporativo de la clase 17:
     · 100 % minúsculas y snake_case       · prefijos dim_ (catálogos) y fact_ (transaccionales)
     · llaves como <entidad>_id             · constraints: pk_/fk_/uq_/ck_/df_/ix_
   NO TOCA el esquema stg (la capa de staging conserva los nombres del origen).
   Es IDEMPOTENTE: se puede ejecutar más de una vez sin error.
   ORDEN: 01 -> 05 (originales) -> 10 -> 11 -> 12 -> 13 -> 14 -> 15 / P9 de cada integrante.
   Los mensajes "Caution: Changing any part of an object name..." de sp_rename son normales.
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

/* (Recomendado) Respaldo antes de migrar. Cambia la ruta y quita los comentarios:
-- BACKUP DATABASE BD_Cafecito TO DISK = N'C:\Temp\BD_Cafecito_antes_nomenclatura.bak' WITH INIT;
*/

/* ---------------------------------------------------------------------
   CAPTURA "ANTES": nombres actuales y conteo de objetos fuera de estándar
   --------------------------------------------------------------------- */
SELECT t.name AS tabla, c.column_id AS orden, c.name AS columna
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE s.name = N'dbo' AND t.name <> N'sysdiagrams'
ORDER BY t.name, c.column_id;
SELECT
  (SELECT COUNT(*) FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
      AND t.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%')   AS tablas_dbo_fuera_de_estandar,
  (SELECT COUNT(*) FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
      AND c.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%')   AS columnas_dbo_fuera_de_estandar;
GO

/* ---------------------------------------------------------------------
   PASO 1 · Retirar vistas y procedimientos antiguos (se recrean en 11 y 12)
   Si no se retiran, quedarían con referencias a nombres que ya no existen.
   --------------------------------------------------------------------- */
DROP VIEW IF EXISTS dbo.vw_Ventas_Operativa;
DROP VIEW IF EXISTS dbo.vw_Analitica_360_Cliente;
DROP VIEW IF EXISTS dbo.vw_KPI_Consumo_por_Clima;
DROP VIEW IF EXISTS dbo.vw_KPI_Logistica_por_Clima;
DROP VIEW IF EXISTS dbo.vw_KPI_Resumen_Sucursal;
DROP PROCEDURE IF EXISTS dbo.sp_Registrar_Cliente;
DROP PROCEDURE IF EXISTS dbo.sp_Consultar_Cliente;
DROP PROCEDURE IF EXISTS dbo.sp_Historial_Pedidos_Cliente;
GO

/* ---------------------------------------------------------------------
   PASO 2 · Procedimientos temporales de apoyo (viven solo en esta sesión)
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'tempdb..#rn_tabla')   IS NOT NULL DROP PROCEDURE #rn_tabla;
IF OBJECT_ID(N'tempdb..#rn_columna') IS NOT NULL DROP PROCEDURE #rn_columna;
IF OBJECT_ID(N'tempdb..#rn_objeto')  IS NOT NULL DROP PROCEDURE #rn_objeto;
IF OBJECT_ID(N'tempdb..#rn_indice')  IS NOT NULL DROP PROCEDURE #rn_indice;
GO

CREATE PROCEDURE #rn_tabla @viejo SYSNAME, @nuevo SYSNAME
AS
BEGIN
    DECLARE @obj NVARCHAR(300) = N'dbo.' + @viejo, @dest NVARCHAR(300) = N'dbo.' + @nuevo;
    IF OBJECT_ID(@dest, N'U') IS NOT NULL BEGIN PRINT N'   (ya estaba) tabla ' + @nuevo; RETURN; END
    IF OBJECT_ID(@obj,  N'U') IS NULL     BEGIN PRINT N'   ¡No existe la tabla ' + @viejo + N'!'; RETURN; END
    EXEC sys.sp_rename @obj, @nuevo, N'OBJECT';
    PRINT N'   tabla   ' + @viejo + N'  ->  ' + @nuevo;
END;
GO

CREATE PROCEDURE #rn_columna @tabla SYSNAME, @viejo SYSNAME, @nuevo SYSNAME
AS
BEGIN
    DECLARE @t NVARCHAR(300) = N'dbo.' + @tabla, @obj NVARCHAR(600), @tmp SYSNAME;
    IF EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(@t)
                 AND name COLLATE Latin1_General_BIN2 = @nuevo COLLATE Latin1_General_BIN2)
        RETURN;                                           -- ya tiene el nombre exacto
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@t) AND name = @viejo)
    BEGIN PRINT N'   ¡No existe ' + @tabla + N'.' + @viejo + N'!'; RETURN; END
    SET @obj = @t + N'.' + @viejo;
    IF LOWER(@viejo) = LOWER(@nuevo)                      -- solo cambian mayúsculas: dos pasos
    BEGIN
        SET @tmp = @nuevo + N'_tmp_rn';
        EXEC sys.sp_rename @obj, @tmp, N'COLUMN';
        SET @obj = @t + N'.' + @tmp;
    END
    EXEC sys.sp_rename @obj, @nuevo, N'COLUMN';
END;
GO

CREATE PROCEDURE #rn_objeto @viejo SYSNAME, @nuevo SYSNAME
AS
BEGIN
    DECLARE @obj NVARCHAR(300) = N'dbo.' + @viejo;
    IF OBJECT_ID(N'dbo.' + @nuevo) IS NOT NULL RETURN;
    IF OBJECT_ID(@obj) IS NULL BEGIN PRINT N'   ¡No existe el objeto ' + @viejo + N'!'; RETURN; END
    EXEC sys.sp_rename @obj, @nuevo, N'OBJECT';
END;
GO

CREATE PROCEDURE #rn_indice @tabla SYSNAME, @viejo SYSNAME, @nuevo SYSNAME
AS
BEGIN
    DECLARE @obj NVARCHAR(600) = N'dbo.' + @tabla + N'.' + @viejo;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.' + @tabla) AND name = @viejo)
        EXEC sys.sp_rename @obj, @nuevo, N'INDEX';
END;
GO

/* ---------------------------------------------------------------------
   PASO 3 · Renombrar TABLAS
   --------------------------------------------------------------------- */
PRINT N'== Tablas ==';
EXEC #rn_tabla N'Ciudad', N'dim_ciudad';
EXEC #rn_tabla N'Sucursal', N'dim_sucursal';
EXEC #rn_tabla N'Categoria_Producto', N'dim_categoria_producto';
EXEC #rn_tabla N'Cliente', N'dim_cliente';
EXEC #rn_tabla N'Pedido', N'fact_pedido';
EXEC #rn_tabla N'Clima_Diario', N'fact_clima_diario';
EXEC #rn_tabla N'Entrega', N'fact_entrega';
GO

/* ---------------------------------------------------------------------
   PASO 4 · Renombrar COLUMNAS (usan ya el nombre nuevo de la tabla)
   --------------------------------------------------------------------- */
PRINT N'== Columnas ==';

-- dim_ciudad
EXEC #rn_columna N'dim_ciudad', N'ID_Ciudad', N'ciudad_id';
EXEC #rn_columna N'dim_ciudad', N'Nombre_Ciudad', N'nombre_ciudad';
EXEC #rn_columna N'dim_ciudad', N'Estado', N'estado';
-- dim_sucursal
EXEC #rn_columna N'dim_sucursal', N'ID_Sucursal', N'sucursal_id';
EXEC #rn_columna N'dim_sucursal', N'Nombre_Sucursal', N'nombre_sucursal';
EXEC #rn_columna N'dim_sucursal', N'ID_Ciudad', N'ciudad_id';
-- dim_categoria_producto
EXEC #rn_columna N'dim_categoria_producto', N'ID_Categoria', N'categoria_id';
EXEC #rn_columna N'dim_categoria_producto', N'Nombre_Categoria', N'nombre_categoria';
EXEC #rn_columna N'dim_categoria_producto', N'Temperatura_Servicio', N'temperatura_servicio';
-- dim_cliente
EXEC #rn_columna N'dim_cliente', N'ID_Cliente', N'cliente_id';
EXEC #rn_columna N'dim_cliente', N'Nombre_Completo', N'nombre_completo';
EXEC #rn_columna N'dim_cliente', N'Email', N'email';
EXEC #rn_columna N'dim_cliente', N'Telefono', N'telefono';
EXEC #rn_columna N'dim_cliente', N'ID_Ciudad', N'ciudad_id';
EXEC #rn_columna N'dim_cliente', N'Fecha_Registro', N'fecha_registro';
-- fact_pedido
EXEC #rn_columna N'fact_pedido', N'ID_Pedido', N'pedido_id';
EXEC #rn_columna N'fact_pedido', N'ID_Cliente', N'cliente_id';
EXEC #rn_columna N'fact_pedido', N'ID_Sucursal', N'sucursal_id';
EXEC #rn_columna N'fact_pedido', N'ID_Categoria', N'categoria_id';
EXEC #rn_columna N'fact_pedido', N'Fecha_Hora', N'fecha_hora';
EXEC #rn_columna N'fact_pedido', N'Fecha', N'fecha';
EXEC #rn_columna N'fact_pedido', N'Monto_Total', N'monto_total';
-- fact_clima_diario
EXEC #rn_columna N'fact_clima_diario', N'ID_Clima', N'clima_id';
EXEC #rn_columna N'fact_clima_diario', N'Fecha', N'fecha';
EXEC #rn_columna N'fact_clima_diario', N'ID_Ciudad', N'ciudad_id';
EXEC #rn_columna N'fact_clima_diario', N'Temperatura_C', N'temperatura_c';
EXEC #rn_columna N'fact_clima_diario', N'Condicion_Climatica', N'condicion_climatica';
EXEC #rn_columna N'fact_clima_diario', N'Humedad_Pct', N'humedad_pct';
EXEC #rn_columna N'fact_clima_diario', N'Temperatura_Imputada', N'temperatura_imputada';
-- fact_entrega
EXEC #rn_columna N'fact_entrega', N'ID_Envio', N'envio_id';
EXEC #rn_columna N'fact_entrega', N'ID_Pedido', N'pedido_id';
EXEC #rn_columna N'fact_entrega', N'Fecha_Entrega', N'fecha_entrega';
EXEC #rn_columna N'fact_entrega', N'Minutos_Demora', N'minutos_demora';
EXEC #rn_columna N'fact_entrega', N'Calificacion_Cliente', N'calificacion_cliente';
EXEC #rn_columna N'fact_entrega', N'Demora_Imputada', N'demora_imputada';
EXEC #rn_columna N'fact_entrega', N'Calificacion_Imputada', N'calificacion_imputada';
GO

/* ---------------------------------------------------------------------
   PASO 5 · Renombrar CONSTRAINTS e ÍNDICES
   --------------------------------------------------------------------- */
PRINT N'== Constraints e índices ==';
EXEC #rn_objeto N'PK_Ciudad', N'pk_dim_ciudad';
EXEC #rn_objeto N'PK_Sucursal', N'pk_dim_sucursal';
EXEC #rn_objeto N'PK_Categoria_Producto', N'pk_dim_categoria_producto';
EXEC #rn_objeto N'PK_Cliente', N'pk_dim_cliente';
EXEC #rn_objeto N'PK_Pedido', N'pk_fact_pedido';
EXEC #rn_objeto N'PK_Clima_Diario', N'pk_fact_clima_diario';
EXEC #rn_objeto N'PK_Entrega', N'pk_fact_entrega';
EXEC #rn_objeto N'UQ_Ciudad_Nombre', N'uq_dim_ciudad_nombre';
EXEC #rn_objeto N'UQ_Categoria_Nombre', N'uq_dim_categoria_producto_nombre';
EXEC #rn_objeto N'UQ_Cliente_Email', N'uq_dim_cliente_email';
EXEC #rn_objeto N'UQ_Clima_Fecha_Ciudad', N'uq_fact_clima_diario_fecha_ciudad';
EXEC #rn_objeto N'UQ_Entrega_Pedido', N'uq_fact_entrega_pedido';
EXEC #rn_objeto N'FK_Sucursal_Ciudad', N'fk_dim_sucursal_ciudad';
EXEC #rn_objeto N'FK_Cliente_Ciudad', N'fk_dim_cliente_ciudad';
EXEC #rn_objeto N'FK_Pedido_Cliente', N'fk_fact_pedido_cliente';
EXEC #rn_objeto N'FK_Pedido_Sucursal', N'fk_fact_pedido_sucursal';
EXEC #rn_objeto N'FK_Pedido_Categoria', N'fk_fact_pedido_categoria';
EXEC #rn_objeto N'FK_Clima_Ciudad', N'fk_fact_clima_diario_ciudad';
EXEC #rn_objeto N'FK_Entrega_Pedido', N'fk_fact_entrega_pedido';
EXEC #rn_objeto N'CK_Categoria_TempServicio', N'ck_dim_categoria_producto_temperatura';
EXEC #rn_objeto N'CK_Cliente_Email', N'ck_dim_cliente_email';
EXEC #rn_objeto N'CK_Pedido_Monto', N'ck_fact_pedido_monto';
EXEC #rn_objeto N'CK_Clima_Condicion', N'ck_fact_clima_diario_condicion';
EXEC #rn_objeto N'CK_Clima_Humedad', N'ck_fact_clima_diario_humedad';
EXEC #rn_objeto N'CK_Entrega_Demora', N'ck_fact_entrega_demora';
EXEC #rn_objeto N'CK_Entrega_Calif', N'ck_fact_entrega_calificacion';
EXEC #rn_objeto N'DF_Clima_TempImp', N'df_fact_clima_diario_temp_imputada';
EXEC #rn_objeto N'DF_Entrega_DemImp', N'df_fact_entrega_demora_imputada';
EXEC #rn_objeto N'DF_Entrega_CalImp', N'df_fact_entrega_calificacion_imputada';
EXEC #rn_indice N'fact_pedido', N'IX_Pedido_Fecha', N'ix_fact_pedido_fecha';
EXEC #rn_indice N'fact_pedido', N'IX_Pedido_Cliente', N'ix_fact_pedido_cliente';
GO

DROP PROCEDURE #rn_tabla;
DROP PROCEDURE #rn_columna;
DROP PROCEDURE #rn_objeto;
DROP PROCEDURE #rn_indice;
GO

/* ---------------------------------------------------------------------
   CAPTURA "DESPUÉS": nombres finales y conteo de objetos fuera de estándar
   (ambos conteos deben ser 0)
   --------------------------------------------------------------------- */
SELECT t.name AS tabla, c.column_id AS orden, c.name AS columna
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE s.name = N'dbo' AND t.name <> N'sysdiagrams'
ORDER BY t.name, c.column_id;
SELECT
  (SELECT COUNT(*) FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
      AND t.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%')   AS tablas_dbo_fuera_de_estandar,
  (SELECT COUNT(*) FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
      AND c.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%')   AS columnas_dbo_fuera_de_estandar;
GO

PRINT N'Nomenclatura estandarizada. Siguiente paso: ejecutar 11, 12 y 13.';
GO

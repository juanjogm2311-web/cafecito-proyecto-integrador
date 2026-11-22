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

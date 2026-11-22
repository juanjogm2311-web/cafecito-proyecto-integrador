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

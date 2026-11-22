/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   Script 14 · PRUEBAS DE CALIDAD (QA) con nomenclatura estándar (reemplaza al 08)
   Responsable: Paulina Karime Martínez Rivera (Data Quality & QA Specialist)
   Mismas pruebas que el script 08 + sección A.7 de METADATOS (Semana 9).
   Prerrequisito: scripts 10, 11, 12 y 15 (o los P9 de cada integrante).
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;

DECLARE @pruebas TABLE (id INT IDENTITY(1,1), categoria NVARCHAR(30), prueba NVARCHAR(150), esperado NVARCHAR(30), obtenido NVARCHAR(30));

-- A.1 Conciliación de volúmenes
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Conciliación', N'Clientes cargados (40 + CLI-000)', N'41', CAST((SELECT COUNT(*) FROM dbo.dim_cliente) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Pedidos cargados (135 crudos - 6 duplicados)', N'129', CAST((SELECT COUNT(*) FROM dbo.fact_pedido) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros de clima (65 crudos - 2 duplicados)', N'63', CAST((SELECT COUNT(*) FROM dbo.fact_clima_diario) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Entregas (107 - 3 duplicados - 1 huérfana)', N'103', CAST((SELECT COUNT(*) FROM dbo.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros rechazados (ENV-999 sin pedido)', N'1', CAST((SELECT COUNT(*) FROM stg.Registros_Rechazados) AS NVARCHAR(30));

-- A.2 Completitud
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Completitud', N'Entregas con demora o calificación nula', N'0',
       CAST((SELECT COUNT(*) FROM dbo.fact_entrega WHERE minutos_demora IS NULL OR calificacion_cliente IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Clima con temperatura nula', N'0',
       CAST((SELECT COUNT(*) FROM dbo.fact_clima_diario WHERE temperatura_c IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Pedidos sin clima para su fecha y ciudad', N'0',
       CAST((SELECT COUNT(*) FROM dbo.fact_pedido p JOIN dbo.dim_sucursal s ON s.sucursal_id = p.sucursal_id
              LEFT JOIN dbo.fact_clima_diario c ON c.fecha = p.fecha AND c.ciudad_id = s.ciudad_id WHERE c.clima_id IS NULL) AS NVARCHAR(30));

-- A.3 Unicidad
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Unicidad', N'Pedidos con más de una entrega', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT pedido_id FROM dbo.fact_entrega GROUP BY pedido_id HAVING COUNT(*) > 1) d) AS NVARCHAR(30))
UNION ALL SELECT N'Unicidad', N'Emails de cliente repetidos', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT email FROM dbo.dim_cliente GROUP BY email HAVING COUNT(*) > 1) d) AS NVARCHAR(30));

-- A.4 Validez
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Validez', N'Montos negativos', N'0', CAST((SELECT COUNT(*) FROM dbo.fact_pedido WHERE monto_total < 0) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Calificaciones fuera de 1-5', N'0', CAST((SELECT COUNT(*) FROM dbo.fact_entrega WHERE calificacion_cliente NOT BETWEEN 1 AND 5) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Entregas anteriores a su pedido', N'0',
       CAST((SELECT COUNT(*) FROM dbo.fact_entrega e JOIN dbo.fact_pedido p ON p.pedido_id = e.pedido_id WHERE e.fecha_entrega < p.fecha) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Textos con espacios sobrantes (dim_cliente.nombre_completo)', N'0',
       CAST((SELECT COUNT(*) FROM dbo.dim_cliente WHERE DATALENGTH(nombre_completo) <> DATALENGTH(TRIM(nombre_completo)) OR nombre_completo LIKE N'%  %') AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Emails con mayúsculas', N'0',
       CAST((SELECT COUNT(*) FROM dbo.dim_cliente WHERE email COLLATE Latin1_General_CS_AS <> LOWER(email)) AS NVARCHAR(30));

-- A.5 Imputación
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Imputación', N'Demoras imputadas con la mediana', N'8', CAST((SELECT SUM(CAST(demora_imputada AS INT)) FROM dbo.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Calificaciones imputadas con la moda', N'11', CAST((SELECT SUM(CAST(calificacion_imputada AS INT)) FROM dbo.fact_entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-103: minutos_demora (mediana)', N'30', CAST((SELECT minutos_demora FROM dbo.fact_entrega WHERE pedido_id = 'PED-103') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-105: calificación (moda)', N'4', CAST((SELECT calificacion_cliente FROM dbo.fact_entrega WHERE pedido_id = 'PED-105') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Temperaturas imputadas (promedio por ciudad)', N'2', CAST((SELECT SUM(CAST(temperatura_imputada AS INT)) FROM dbo.fact_clima_diario) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Pedidos asignados a CLI-000 (COALESCE)', N'2', CAST((SELECT COUNT(*) FROM dbo.fact_pedido WHERE cliente_id = 'CLI-000') AS NVARCHAR(30));

-- A.6 Vistas
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Vistas', N'vw_ventas_operativa: filas', N'129', CAST((SELECT COUNT(*) FROM dbo.vw_ventas_operativa) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'vw_analitica_360: clientes sin compras', N'3',
       CAST((SELECT COUNT(*) FROM dbo.vw_analitica_360_cliente WHERE pedido_id IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Venta total MXN', N'19310.00', CAST((SELECT SUM(venta_total_mxn) FROM dbo.vw_kpi_consumo_por_clima) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Demora promedio con LLUVIA INTENSA (min)', N'51.04',
       CAST((SELECT demora_promedio_min FROM dbo.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con LLUVIA INTENSA', N'2.26',
       CAST((SELECT calificacion_promedio FROM dbo.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con clima TEMPLADO', N'4.29',
       CAST((SELECT calificacion_promedio FROM dbo.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'TEMPLADO') AS NVARCHAR(30));

-- A.7 Metadatos y nomenclatura (NUEVO · Semana 9)
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Metadatos', N'Tablas dbo sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
               AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = t.object_id AND ep.minor_id = 0 AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Columnas dbo sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
               AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Tablas dbo fuera de snake_case', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
               AND t.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%') AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Columnas dbo fuera de snake_case', N'0',
       CAST((SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
               AND c.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%') AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Tablas dbo sin prefijo dim_ / fact_', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'dbo' AND t.is_ms_shipped = 0 AND t.name <> N'sysdiagrams'
               AND t.name NOT LIKE N'dim[_]%' AND t.name NOT LIKE N'fact[_]%') AS NVARCHAR(30));

SELECT id, categoria, prueba, esperado, obtenido,
       CASE WHEN esperado = obtenido THEN N'✔ PASA' ELSE N'✘ FALLA' END AS resultado
FROM @pruebas
ORDER BY id;

SELECT COUNT(*) AS total_pruebas,
       SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) AS pasan,
       SUM(CASE WHEN esperado <> obtenido OR obtenido IS NULL THEN 1 ELSE 0 END) AS fallan
FROM @pruebas;
GO

/* ---------------------------------------------------------------------
   B) PRUEBAS DE PROCEDIMIENTOS ALMACENADOS
   --------------------------------------------------------------------- */
PRINT '--- SP1 caso válido (se deshace con ROLLBACK para poder repetir la prueba) ---';
BEGIN TRANSACTION;
    DECLARE @nuevo_id VARCHAR(10);
    EXEC dbo.sp_registrar_cliente
         @nombre_completo     = N'   paulina   prueba qa  ',
         @email               = '  PAULINA.QA@Correo.COM ',
         @telefono            = '4771234567',
         @ciudad              = N'leon',
         @cliente_id_generado = @nuevo_id OUTPUT;
    SELECT @nuevo_id AS id_generado;                                      -- esperado: CLI-041
    SELECT * FROM dbo.dim_cliente WHERE cliente_id = @nuevo_id;           -- nombre en mayúsculas, email en minúsculas
ROLLBACK TRANSACTION;
GO

PRINT '--- SP1 caso de error: email duplicado ---';
BEGIN TRY
    EXEC dbo.sp_registrar_cliente @nombre_completo = N'Cliente Repetido', @email = 'MARIA.NAVARRO1@correo.com', @ciudad = N'León';
END TRY
BEGIN CATCH
    SELECT N'SP1 - duplicado' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP1 caso de error: ciudad inexistente ---';
BEGIN TRY
    EXEC dbo.sp_registrar_cliente @nombre_completo = N'Cliente Foráneo', @email = 'foraneo@correo.com', @ciudad = N'Monterrey';
END TRY
BEGIN CATCH
    SELECT N'SP1 - ciudad inválida' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP2 consulta por ID (acepta espacios y minúsculas) ---';
EXEC dbo.sp_consultar_cliente @cliente_id = '  cli-001 ';   -- 7 pedidos
EXEC dbo.sp_consultar_cliente @cliente_id = 'CLI-038';      -- cliente sin compras: 0 / SIN COMPRAS
BEGIN TRY
    EXEC dbo.sp_consultar_cliente @cliente_id = 'CLI-999';
END TRY
BEGIN CATCH
    SELECT N'SP2 - ID inexistente' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP3 historial por rango de fechas ---';
EXEC dbo.sp_historial_pedidos_cliente @cliente_id = 'CLI-001', @fecha_inicio = '20260801', @fecha_fin = '20260807';  -- 4 pedidos
EXEC dbo.sp_historial_pedidos_cliente @cliente_id = 'CLI-001';                                                      -- historial completo: 7
BEGIN TRY
    EXEC dbo.sp_historial_pedidos_cliente @cliente_id = 'CLI-001', @fecha_inicio = '20260831', @fecha_fin = '20260801';
END TRY
BEGIN CATCH
    SELECT N'SP3 - rango inválido' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

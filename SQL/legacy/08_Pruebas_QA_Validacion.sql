/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 08 · PRUEBAS DE CALIDAD (QA) DESPUÉS DE LA CARGA
   Responsable: Paulina Karime Martínez Rivera (Data Quality & QA Specialist)
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;

/* ---------------------------------------------------------------------
   A) TABLERO DE PRUEBAS
   --------------------------------------------------------------------- */
DECLARE @Pruebas TABLE (ID INT IDENTITY(1,1), Categoria NVARCHAR(30), Prueba NVARCHAR(150), Esperado NVARCHAR(30), Obtenido NVARCHAR(30));

-- A.1 Conciliación de volúmenes (crudo - duplicados - rechazados = final)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Conciliación', N'Clientes cargados (40 + CLI-000)', N'41', CAST((SELECT COUNT(*) FROM dbo.Cliente) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Pedidos cargados (135 crudos - 6 duplicados)', N'129', CAST((SELECT COUNT(*) FROM dbo.Pedido) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros de clima (65 crudos - 2 duplicados)', N'63', CAST((SELECT COUNT(*) FROM dbo.Clima_Diario) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Entregas (107 - 3 duplicados - 1 huérfana)', N'103', CAST((SELECT COUNT(*) FROM dbo.Entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Conciliación', N'Registros rechazados (ENV-999 sin pedido)', N'1', CAST((SELECT COUNT(*) FROM stg.Registros_Rechazados) AS NVARCHAR(30));

-- A.2 Completitud (sin nulos en campos críticos)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Completitud', N'Entregas con demora o calificación nula', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Entrega WHERE Minutos_Demora IS NULL OR Calificacion_Cliente IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Clima con temperatura nula', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Clima_Diario WHERE Temperatura_C IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Completitud', N'Pedidos sin clima para su fecha y ciudad', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Pedido p JOIN dbo.Sucursal s ON s.ID_Sucursal = p.ID_Sucursal
              LEFT JOIN dbo.Clima_Diario c ON c.Fecha = p.Fecha AND c.ID_Ciudad = s.ID_Ciudad WHERE c.ID_Clima IS NULL) AS NVARCHAR(30));

-- A.3 Unicidad (sin duplicados)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Unicidad', N'Pedidos con más de una entrega', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT ID_Pedido FROM dbo.Entrega GROUP BY ID_Pedido HAVING COUNT(*) > 1) d) AS NVARCHAR(30))
UNION ALL SELECT N'Unicidad', N'Emails de cliente repetidos', N'0',
       CAST((SELECT COUNT(*) FROM (SELECT Email FROM dbo.Cliente GROUP BY Email HAVING COUNT(*) > 1) d) AS NVARCHAR(30));

-- A.4 Validez (reglas de negocio)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Validez', N'Montos negativos', N'0', CAST((SELECT COUNT(*) FROM dbo.Pedido WHERE Monto_Total < 0) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Calificaciones fuera de 1-5', N'0', CAST((SELECT COUNT(*) FROM dbo.Entrega WHERE Calificacion_Cliente NOT BETWEEN 1 AND 5) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Entregas anteriores a su pedido', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Entrega e JOIN dbo.Pedido p ON p.ID_Pedido = e.ID_Pedido WHERE e.Fecha_Entrega < p.Fecha) AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Textos con espacios sobrantes (Cliente.Nombre)', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Cliente WHERE DATALENGTH(Nombre_Completo) <> DATALENGTH(TRIM(Nombre_Completo)) OR Nombre_Completo LIKE N'%  %') AS NVARCHAR(30))
UNION ALL SELECT N'Validez', N'Emails con mayúsculas', N'0',
       CAST((SELECT COUNT(*) FROM dbo.Cliente WHERE Email COLLATE Latin1_General_CS_AS <> LOWER(Email)) AS NVARCHAR(30));

-- A.5 Imputación (valores indicados en el dataset)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Imputación', N'Demoras imputadas con la mediana', N'8', CAST((SELECT SUM(CAST(Demora_Imputada AS INT)) FROM dbo.Entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Calificaciones imputadas con la moda', N'11', CAST((SELECT SUM(CAST(Calificacion_Imputada AS INT)) FROM dbo.Entrega) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-103: Minutos_Demora (mediana)', N'30', CAST((SELECT Minutos_Demora FROM dbo.Entrega WHERE ID_Pedido = 'PED-103') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'PED-105: Calificación (moda)', N'4', CAST((SELECT Calificacion_Cliente FROM dbo.Entrega WHERE ID_Pedido = 'PED-105') AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Temperaturas imputadas (promedio por ciudad)', N'2', CAST((SELECT SUM(CAST(Temperatura_Imputada AS INT)) FROM dbo.Clima_Diario) AS NVARCHAR(30))
UNION ALL SELECT N'Imputación', N'Pedidos asignados a CLI-000 (COALESCE)', N'2', CAST((SELECT COUNT(*) FROM dbo.Pedido WHERE ID_Cliente = 'CLI-000') AS NVARCHAR(30));

-- A.6 Vistas (resultados de negocio)
INSERT INTO @Pruebas (Categoria, Prueba, Esperado, Obtenido)
SELECT N'Vistas', N'vw_Ventas_Operativa: filas', N'129', CAST((SELECT COUNT(*) FROM dbo.vw_Ventas_Operativa) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'vw_Analitica_360: clientes sin compras', N'3',
       CAST((SELECT COUNT(*) FROM dbo.vw_Analitica_360_Cliente WHERE ID_Pedido IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Venta total MXN', N'19310.00', CAST((SELECT SUM(Venta_Total_MXN) FROM dbo.vw_KPI_Consumo_por_Clima) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Demora promedio con LLUVIA INTENSA (min)', N'51.04',
       CAST((SELECT Demora_Promedio_Min FROM dbo.vw_KPI_Logistica_por_Clima WHERE Condicion_Climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con LLUVIA INTENSA', N'2.26',
       CAST((SELECT Calificacion_Promedio FROM dbo.vw_KPI_Logistica_por_Clima WHERE Condicion_Climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con clima TEMPLADO', N'4.29',
       CAST((SELECT Calificacion_Promedio FROM dbo.vw_KPI_Logistica_por_Clima WHERE Condicion_Climatica = N'TEMPLADO') AS NVARCHAR(30));

SELECT ID, Categoria, Prueba, Esperado, Obtenido,
       CASE WHEN Esperado = Obtenido THEN N'✔ PASA' ELSE N'✘ FALLA' END AS Resultado
FROM @Pruebas
ORDER BY ID;

SELECT COUNT(*) AS Total_Pruebas,
       SUM(CASE WHEN Esperado = Obtenido THEN 1 ELSE 0 END) AS Pasan,
       SUM(CASE WHEN Esperado <> Obtenido OR Obtenido IS NULL THEN 1 ELSE 0 END) AS Fallan
FROM @Pruebas;
GO

/* ---------------------------------------------------------------------
   B) PRUEBAS DE PROCEDIMIENTOS ALMACENADOS
   --------------------------------------------------------------------- */
PRINT '--- SP1 caso válido (se deshace al final con ROLLBACK para poder repetir la prueba) ---';
BEGIN TRANSACTION;
    DECLARE @NuevoID VARCHAR(10);
    EXEC dbo.sp_Registrar_Cliente
         @Nombre_Completo = N'   paulina   prueba qa  ',
         @Email           = '  PAULINA.QA@Correo.COM ',
         @Telefono        = '4771234567',
         @Ciudad          = N'leon',
         @ID_Generado     = @NuevoID OUTPUT;
    SELECT @NuevoID AS ID_Generado;                                       -- esperado: CLI-041
    SELECT * FROM dbo.Cliente WHERE ID_Cliente = @NuevoID;                -- nombre en mayúsculas, email en minúsculas
ROLLBACK TRANSACTION;
GO

PRINT '--- SP1 caso de error: email duplicado (debe mostrar el mensaje de error) ---';
BEGIN TRY
    EXEC dbo.sp_Registrar_Cliente @Nombre_Completo = N'Cliente Repetido', @Email = 'MARIA.NAVARRO1@correo.com', @Ciudad = N'León';
END TRY
BEGIN CATCH
    SELECT N'SP1 - duplicado' AS Prueba, ERROR_MESSAGE() AS Mensaje_Esperado;
END CATCH;
GO

PRINT '--- SP1 caso de error: ciudad inexistente ---';
BEGIN TRY
    EXEC dbo.sp_Registrar_Cliente @Nombre_Completo = N'Cliente Foráneo', @Email = 'foraneo@correo.com', @Ciudad = N'Monterrey';
END TRY
BEGIN CATCH
    SELECT N'SP1 - ciudad inválida' AS Prueba, ERROR_MESSAGE() AS Mensaje_Esperado;
END CATCH;
GO

PRINT '--- SP2 consulta por ID (acepta espacios y minúsculas) ---';
EXEC dbo.sp_Consultar_Cliente @ID_Cliente = '  cli-001 ';   -- 7 pedidos
EXEC dbo.sp_Consultar_Cliente @ID_Cliente = 'CLI-038';      -- cliente sin compras: 0 / SIN COMPRAS
BEGIN TRY
    EXEC dbo.sp_Consultar_Cliente @ID_Cliente = 'CLI-999';
END TRY
BEGIN CATCH
    SELECT N'SP2 - ID inexistente' AS Prueba, ERROR_MESSAGE() AS Mensaje_Esperado;
END CATCH;
GO

PRINT '--- SP3 historial por rango de fechas ---';
EXEC dbo.sp_Historial_Pedidos_Cliente @ID_Cliente = 'CLI-001', @FechaInicio = '20260801', @FechaFin = '20260807';  -- 4 pedidos
EXEC dbo.sp_Historial_Pedidos_Cliente @ID_Cliente = 'CLI-001';                                                    -- historial completo: 7
BEGIN TRY
    EXEC dbo.sp_Historial_Pedidos_Cliente @ID_Cliente = 'CLI-001', @FechaInicio = '20260831', @FechaFin = '20260801';
END TRY
BEGIN CATCH
    SELECT N'SP3 - rango inválido' AS Prueba, ERROR_MESSAGE() AS Mensaje_Esperado;
END CATCH;
GO

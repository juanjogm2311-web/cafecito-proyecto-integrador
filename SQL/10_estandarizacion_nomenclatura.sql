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

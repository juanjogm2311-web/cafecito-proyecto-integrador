/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   Script 13 · sp_obtener_diccionario_datos (Opción B de la actividad P9)
   Responsable: André Campos Díaz (Data Architect / SQL Specialist)
   Uso:
     EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_cliente';
     EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Ventas_Raw', @esquema = N'stg';
     EXEC dbo.sp_obtener_diccionario_datos;      -- diccionario global del esquema dbo
   ===================================================================== */
USE BD_Cafecito;
GO

CREATE OR ALTER PROCEDURE dbo.sp_obtener_diccionario_datos
    @nombre_tabla SYSNAME = NULL,
    @esquema      SYSNAME = N'dbo'
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre_tabla IS NOT NULL
       AND NOT EXISTS (SELECT 1
                       FROM sys.tables AS t
                       JOIN sys.schemas AS s ON s.schema_id = t.schema_id
                       WHERE s.name = @esquema AND t.name = @nombre_tabla)
    BEGIN
        RAISERROR(N'La tabla %s.%s no existe en la base de datos.', 16, 1, @esquema, @nombre_tabla);
        RETURN;
    END

SELECT s.name                                   AS esquema,
       t.name                                   AS tabla,
       c.column_id                              AS orden,
       c.name                                   AS columna,
       CASE
         WHEN ty.name IN (N'nvarchar', N'nchar')
              THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END + N')'
         WHEN ty.name IN (N'varchar', N'char', N'varbinary')
              THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length AS NVARCHAR(10)) END + N')'
         WHEN ty.name IN (N'decimal', N'numeric')
              THEN ty.name + N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
         ELSE ty.name
       END                                      AS tipo_dato,
       CASE WHEN c.is_nullable = 1 THEN N'Sí' ELSE N'No' END AS permite_nulos,
       CASE WHEN pk.column_id IS NOT NULL THEN N'Sí' ELSE N'No' END AS es_llave_primaria,
       COALESCE(fk.referencia, N'-')            AS referencia_foranea,
       COALESCE(CONVERT(NVARCHAR(4000), ep.value), N'Sin documentación') AS descripcion_negocio
FROM sys.tables  AS t
JOIN sys.schemas AS s  ON s.schema_id = t.schema_id
JOIN sys.columns AS c  ON c.object_id = t.object_id
JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.extended_properties AS ep
       ON ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id
      AND ep.name = N'MS_Description'
LEFT JOIN (SELECT ic.object_id, ic.column_id
           FROM sys.indexes AS i
           JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
           WHERE i.is_primary_key = 1) AS pk
       ON pk.object_id = c.object_id AND pk.column_id = c.column_id
LEFT JOIN (SELECT fkc.parent_object_id AS object_id, fkc.parent_column_id AS column_id,
                  STRING_AGG(OBJECT_NAME(fkc.referenced_object_id) + N'.' + COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id), N', ') AS referencia
           FROM sys.foreign_key_columns AS fkc
           GROUP BY fkc.parent_object_id, fkc.parent_column_id) AS fk
       ON fk.object_id = c.object_id AND fk.column_id = c.column_id
    WHERE s.name = @esquema
      AND (@nombre_tabla IS NULL OR t.name = @nombre_tabla)
      AND t.name <> N'sysdiagrams'
    ORDER BY t.name, c.column_id;
END;
GO

PRINT 'sp_obtener_diccionario_datos creado correctamente.';
GO

/* Prueba rápida */
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_cliente';
GO

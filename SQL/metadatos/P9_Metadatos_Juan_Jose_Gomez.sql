/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3 - BD_Cafecito
   Entrega 2 · Semana 9 (P9) · Metadatos con propiedades extendidas
   P9 · Documentación de metadatos: dbo.dim_ciudad, dbo.dim_sucursal, dbo.dim_categoria_producto
   Integrante : Juan José Gómez Montúfar  (Líder de proyecto / integración)
   Matrícula  : 196549-9
   Fecha      : 30/10/2026
   Prerrequisito: haber ejecutado 10, 11, 12 y 13 (paquete común).
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

/* =====================================================================
   BLOQUE 0 · VERIFICACIÓN PREVIA
   Confirma que existen los objetos con la nomenclatura estándar.
   Si aparece 0 en alguna fila, ejecuta primero los scripts 10 a 13.
   ===================================================================== */
SELECT x.esquema, x.tabla,
       CASE WHEN t.object_id IS NULL THEN N'✘ NO EXISTE (ejecuta script 10)' ELSE N'✔ existe' END AS estado,
       (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = t.object_id) AS columnas
FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
LEFT JOIN sys.schemas AS s ON s.name = x.esquema
LEFT JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
ORDER BY x.esquema, x.tabla;
GO

SELECT CASE WHEN OBJECT_ID(N'dbo.sp_obtener_diccionario_datos', N'P') IS NULL
            THEN N'✘ Falta el script 13 (sp_obtener_diccionario_datos)'
            ELSE N'✔ sp_obtener_diccionario_datos disponible' END AS procedimiento_diccionario;
GO

/* =====================================================================
   BLOQUE 1 · LIMPIEZA PREVIA (hace el script repetible)
   Elimina descripciones anteriores (por ejemplo las del script 09) de las
   tablas de este bloque para volver a aplicarlas con los nombres estándar.
   ===================================================================== */
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'EXEC sys.sp_dropextendedproperty @name = N''' + ep.name + N''', '
             + N'@level0type = N''SCHEMA'', @level0name = N''' + s.name + N''', '
             + N'@level1type = N''TABLE'', @level1name = N''' + t.name + N''''
             + CASE WHEN ep.minor_id > 0
                    THEN N', @level2type = N''COLUMN'', @level2name = N''' + c.name + N''''
                    ELSE N'' END
             + N';' + CHAR(13) + CHAR(10)
FROM sys.extended_properties AS ep
JOIN sys.tables  AS t ON t.object_id = ep.major_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
WHERE ep.class = 1
  AND ep.name IN (N'MS_Description', N'linaje_origen')
  AND (ep.minor_id = 0 OR c.column_id IS NOT NULL)
  AND EXISTS (SELECT 1
              FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name);

IF @sql <> N'' EXEC sys.sp_executesql @sql;
PRINT N'Descripciones previas de las tablas de este bloque eliminadas (si existían).';
GO

/* =====================================================================
   BLOQUE 2 · APLICACIÓN DE PROPIEDADES EXTENDIDAS (sys.sp_addextendedproperty)
   Por tabla: descripción (MS_Description), linaje (linaje_origen) y una descripción
   por cada columna. Para el PDF captura solo la PARTE FINAL de cada tabla.
   ===================================================================== */

/* ---- 2.1 · dbo.dim_ciudad ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra (catálogo) de las ciudades y estados donde opera Cafecito; sirve como referencia geográfica de sucursales, clientes y clima.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_ciudad';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el script 02 (dato de referencia ya limpio) -> dbo.dim_ciudad. Referenciada por dim_sucursal, dim_cliente y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la ciudad (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre normalizado en mayúsculas de la ciudad (LEÓN, SILAO, GUANAJUATO); no se repite.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'nombre_ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Estado de la República Mexicana al que pertenece la ciudad.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'estado';
PRINT N'Documentada: dbo.dim_ciudad (3 columnas).';
GO

/* ---- 2.2 · dbo.dim_sucursal ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra de las sucursales físicas de Cafecito y su ciudad; representa el punto de venta que atiende cada pedido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_sucursal';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el script 02 -> dbo.dim_sucursal. Referenciada por fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la sucursal con formato SUC-NN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'sucursal_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre comercial de la sucursal de Cafecito.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'nombre_sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad donde se ubica la sucursal (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
PRINT N'Documentada: dbo.dim_sucursal (3 columnas).';
GO

/* ---- 2.3 · dbo.dim_categoria_producto ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra de categorías de producto (bebida caliente, bebida fría y repostería) y su temperatura de servicio; base del análisis de consumo según el clima.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el script 02; el script 05 asigna la categoría a cada pedido a partir de stg.Ventas_Raw.Tipo_Producto -> dbo.dim_categoria_producto.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la categoría de producto (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'categoria_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre comercial de la categoría de producto; no se repite.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'nombre_categoria';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura a la que se sirve la categoría: CALIENTE, FRÍA o N/A (restringido por regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'temperatura_servicio';
PRINT N'Documentada: dbo.dim_categoria_producto (3 columnas).';
GO

/* =====================================================================
   BLOQUE 3 · PRUEBAS DE EJECUCIÓN · OPCIÓN B (procedimiento almacenado)
   Una captura del Results Grid por cada llamada (solo las últimas líneas).
   ===================================================================== */
-- Prueba 3.1 · dbo.dim_ciudad
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_ciudad', @esquema = N'dbo';
GO

-- Prueba 3.2 · dbo.dim_sucursal
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_sucursal', @esquema = N'dbo';
GO

-- Prueba 3.3 · dbo.dim_categoria_producto
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_categoria_producto', @esquema = N'dbo';
GO

/* =====================================================================
   BLOQUE 4 · PRUEBA DE EJECUCIÓN · OPCIÓN A (script directo, equivalente al 05)
   Muestra en una sola cuadrícula todas las tablas de este bloque.
   ===================================================================== */
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name, c.column_id;
GO

/* =====================================================================
   BLOQUE 5 · VALIDACIONES DE GOBERNANZA
   5.1 Descripción de cada tabla y su linaje (propiedad linaje_origen)
   5.2 Cobertura de descripciones por columna (debe decir 100 %)
   5.3 Auditoría de nomenclatura snake_case (tablas dbo)
   ===================================================================== */

-- 5.1 Descripción y linaje por tabla
SELECT s.name AS esquema, t.name AS tabla,
       CONVERT(NVARCHAR(4000), d.value) AS descripcion_tabla,
       CONVERT(NVARCHAR(4000), l.value) AS linaje_origen
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.extended_properties AS d ON d.class = 1 AND d.major_id = t.object_id AND d.minor_id = 0 AND d.name = N'MS_Description'
LEFT JOIN sys.extended_properties AS l ON l.class = 1 AND l.major_id = t.object_id AND l.minor_id = 0 AND l.name = N'linaje_origen'
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name;
GO

-- 5.2 Cobertura de descripciones
SELECT x.esquema, x.tabla,
       COUNT(c.column_id)  AS columnas_totales,
       COUNT(ep.major_id)  AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.extended_properties AS ep
       ON ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description'
GROUP BY x.esquema, x.tabla
ORDER BY x.esquema, x.tabla;
GO

-- 5.3 Auditoría de nomenclatura (minúsculas, snake_case y prefijo dim_ / fact_)
SELECT x.tabla,
       CASE WHEN t.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%' THEN N'✘' ELSE N'✔' END AS tabla_en_snake_case,
       CASE WHEN t.name LIKE N'dim[_]%' OR t.name LIKE N'fact[_]%' THEN N'✔' ELSE N'✘' END AS prefijo_dim_o_fact,
       (SELECT COUNT(*) FROM sys.columns AS c
        WHERE c.object_id = t.object_id
          AND c.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%') AS columnas_fuera_de_estandar
FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
ORDER BY x.tabla;
GO

/* =====================================================================
   BLOQUE 6 · INTEGRACIÓN (solo líder): diccionario global del esquema dbo
   Ejecutar DESPUÉS de que el equipo haya aplicado sus partes (o del script 15).
   ===================================================================== */
EXEC dbo.sp_obtener_diccionario_datos;      -- sin parámetros = todas las tablas de dbo
GO

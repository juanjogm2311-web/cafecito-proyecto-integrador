/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3 - BD_Cafecito
   Entrega 2 · Semana 9 (P9) · Metadatos con propiedades extendidas
   P9 · Documentación de metadatos: dbo.dim_cliente, dbo.fact_pedido
   Integrante : André Campos Díaz  (Data Architect / SQL Specialist)
   Matrícula  : <ESCRIBE TU MATRÍCULA>
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
FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
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
              FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name);

IF @sql <> N'' EXEC sys.sp_executesql @sql;
PRINT N'Descripciones previas de las tablas de este bloque eliminadas (si existían).';
GO

/* =====================================================================
   BLOQUE 2 · APLICACIÓN DE PROPIEDADES EXTENDIDAS (sys.sp_addextendedproperty)
   Por tabla: descripción (MS_Description), linaje (linaje_origen) y una descripción
   por cada columna. Para el PDF captura solo la PARTE FINAL de cada tabla.
   ===================================================================== */

/* ---- 2.1 · dbo.dim_cliente ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra con los datos de identificación y contacto de los clientes de Cafecito; base de la Vista 360°. Incluye el cliente genérico CLI-000 para pedidos sin cliente identificado.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (clientes) -> stg.Clientes_Raw (script 03) -> limpieza fases 2 a 4 (script 05) -> dbo.dim_cliente.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del cliente con formato CLI-NNN (Llave Primaria); CLI-000 agrupa pedidos sin cliente identificado.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'cliente_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre completo del cliente, estandarizado en mayúsculas y sin espacios sobrantes.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'nombre_completo';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Correo electrónico del cliente en minúsculas; único por cliente y con formato validado (regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'email';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Teléfono de contacto del cliente; campo opcional que puede ser nulo.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'telefono';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad de residencia del cliente (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha en que el cliente fue dado de alta en el sistema.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'fecha_registro';
PRINT N'Documentada: dbo.dim_cliente (6 columnas).';
GO

/* ---- 2.2 · dbo.fact_pedido ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional de pedidos del e-commerce: cliente, sucursal, categoría, fecha y monto. Contiene una fila por pedido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (ventas) -> stg.Ventas_Raw (script 03) -> limpieza fases 2 a 4 (script 05) -> dbo.fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del pedido con formato PED-NNN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'pedido_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Cliente que realizó el pedido (Llave Foránea hacia dim_cliente.cliente_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'cliente_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Sucursal que atendió el pedido (Llave Foránea hacia dim_sucursal.sucursal_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'sucursal_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Categoría del producto pedido (Llave Foránea hacia dim_categoria_producto.categoria_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'categoria_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora exactas en que se registró el pedido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'fecha_hora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha del pedido (columna calculada y persistida a partir de fecha_hora); llave temporal para cruzar con fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'fecha';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Importe total del pedido en pesos mexicanos (MXN); no puede ser negativo.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'monto_total';
PRINT N'Documentada: dbo.fact_pedido (7 columnas).';
GO

/* =====================================================================
   BLOQUE 3 · PRUEBAS DE EJECUCIÓN · OPCIÓN B (procedimiento almacenado)
   Una captura del Results Grid por cada llamada (solo las últimas líneas).
   ===================================================================== */
-- Prueba 3.1 · dbo.dim_cliente
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'dim_cliente', @esquema = N'dbo';
GO

-- Prueba 3.2 · dbo.fact_pedido
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'fact_pedido', @esquema = N'dbo';
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name;
GO

-- 5.2 Cobertura de descripciones
SELECT x.esquema, x.tabla,
       COUNT(c.column_id)  AS columnas_totales,
       COUNT(ep.major_id)  AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
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
FROM (VALUES (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
ORDER BY x.tabla;
GO

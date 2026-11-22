/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3 - BD_Cafecito
   Entrega 2 · Semana 9 (P9) · Metadatos con propiedades extendidas
   P9 · Documentación de metadatos: dbo.fact_clima_diario + 5 vistas analíticas
   Integrante : Antonio Hernández Ontiveros  (BI & Analytics Specialist)
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
FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
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
              FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name);

IF @sql <> N'' EXEC sys.sp_executesql @sql;
PRINT N'Descripciones previas de las tablas de este bloque eliminadas (si existían).';
GO

DECLARE @sql_v NVARCHAR(MAX) = N'';

SELECT @sql_v += N'EXEC sys.sp_dropextendedproperty @name = N''' + ep.name + N''', '
               + N'@level0type = N''SCHEMA'', @level0name = N''dbo'', '
               + N'@level1type = N''VIEW'', @level1name = N''' + v.name + N''';' + CHAR(13) + CHAR(10)
FROM sys.extended_properties AS ep
JOIN sys.views AS v ON v.object_id = ep.major_id
WHERE ep.class = 1 AND ep.minor_id = 0
  AND ep.name = N'MS_Description'
  AND v.name IN (N'vw_ventas_operativa', N'vw_analitica_360_cliente', N'vw_kpi_consumo_por_clima', N'vw_kpi_logistica_por_clima', N'vw_kpi_resumen_sucursal');

IF @sql_v <> N'' EXEC sys.sp_executesql @sql_v;
PRINT N'Descripciones previas de las vistas eliminadas (si existían).';
GO

/* =====================================================================
   BLOQUE 2 · APLICACIÓN DE PROPIEDADES EXTENDIDAS (sys.sp_addextendedproperty)
   Por tabla: descripción (MS_Description), linaje (linaje_origen) y una descripción
   por cada columna. Para el PDF captura solo la PARTE FINAL de cada tabla.
   ===================================================================== */

/* ---- 2.1 · dbo.fact_clima_diario ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional con el clima registrado por día y ciudad (origen: API meteorológica); se cruza con los pedidos por fecha y ciudad de la sucursal.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'API_Clima_Historico.json -> stg.Clima_JSON_Raw -> stg.Clima_Raw (script 03) -> limpieza fases 2 a 4 (script 05) -> dbo.fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único autoincremental del registro de clima (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'clima_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de la observación climática; junto con ciudad_id no se repite.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'fecha';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad observada (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura registrada en grados Celsius.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'temperatura_c';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Condición del día: LLUVIA INTENSA, CALUROSO, NUBLADO o TEMPLADO (regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'condicion_climatica';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Humedad relativa en porcentaje (0 a 100); puede ser nula si el dato original era inválido.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'humedad_pct';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que la temperatura se completó con el promedio de su ciudad.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'temperatura_imputada';
PRINT N'Documentada: dbo.fact_clima_diario (7 columnas).';
GO

/* ---- Vistas analíticas (descripción a nivel de vista = linaje hacia sus tablas origen) ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Vista operativa: pedidos limpios con sucursal, ciudad, categoría y canal de venta (domicilio o recoge en sucursal). Origen: fact_pedido, dim_sucursal, dim_ciudad, dim_categoria_producto y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_ventas_operativa';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Vista analítica 360° del cliente: parte de dim_cliente y cruza pedidos, entrega y clima del día (incluye clientes sin compras). Origen: dim_cliente, fact_pedido, dim_sucursal, dim_ciudad, dim_categoria_producto, fact_clima_diario y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_analitica_360_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI de consumo: pedidos, venta, ticket promedio y porcentaje por categoría en cada condición climática. Origen: fact_pedido, dim_sucursal, dim_categoria_producto y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_kpi_consumo_por_clima';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI de logística y satisfacción: demora, calificación, porcentaje de insatisfechos y de entregas tardías por condición climática. Origen: fact_entrega, fact_pedido, dim_sucursal y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_kpi_logistica_por_clima';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI ejecutivo por sucursal: pedidos, venta, ticket, clientes distintos, porcentaje a domicilio, demora y calificación. Origen: dim_sucursal, dim_ciudad, fact_pedido y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_kpi_resumen_sucursal';
PRINT N'Documentadas: 5 vistas analíticas.';
GO

/* =====================================================================
   BLOQUE 3 · PRUEBAS DE EJECUCIÓN · OPCIÓN B (procedimiento almacenado)
   Una captura del Results Grid por cada llamada (solo las últimas líneas).
   ===================================================================== */
-- Prueba 3.1 · dbo.fact_clima_diario
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'fact_clima_diario', @esquema = N'dbo';
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name;
GO

-- 5.2 Cobertura de descripciones
SELECT x.esquema, x.tabla,
       COUNT(c.column_id)  AS columnas_totales,
       COUNT(ep.major_id)  AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
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
FROM (VALUES (N'dbo', N'fact_clima_diario')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
ORDER BY x.tabla;
GO

/* 5.4 Descripción de las vistas analíticas (linaje hacia las tablas origen) */
SELECT s.name AS esquema, v.name AS vista, CONVERT(NVARCHAR(4000), ep.value) AS descripcion_negocio
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
LEFT JOIN sys.extended_properties AS ep ON ep.class = 1 AND ep.major_id = v.object_id AND ep.minor_id = 0 AND ep.name = N'MS_Description'
WHERE s.name = N'dbo' AND v.name LIKE N'vw[_]%'
ORDER BY v.name;
GO

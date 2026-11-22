/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3 - BD_Cafecito
   Entrega 2 · Semana 9 (P9) · Metadatos con propiedades extendidas
   P9 · Documentación de metadatos: stg.Clientes_Raw, stg.Ventas_Raw, stg.Clima_JSON_Raw, stg.Clima_Raw, stg.Entregas_Raw
   Integrante : Ana Sofía Arroniz Domínguez  (ETL / staging)
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
FROM (VALUES (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw')) AS x(esquema, tabla)
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
              FROM (VALUES (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name);

IF @sql <> N'' EXEC sys.sp_executesql @sql;
PRINT N'Descripciones previas de las tablas de este bloque eliminadas (si existían).';
GO

/* =====================================================================
   BLOQUE 2 · APLICACIÓN DE PROPIEDADES EXTENDIDAS (sys.sp_addextendedproperty)
   Por tabla: descripción (MS_Description), linaje (linaje_origen) y una descripción
   por cada columna. Para el PDF captura solo la PARTE FINAL de cada tabla.
   ===================================================================== */

/* ---- 2.1 · stg.Clientes_Raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con datos de clientes recibidos desde el sistema de origen, antes de la limpieza.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (clientes) -> script 03 -> stg.Clientes_Raw -> script 05 -> dbo.dim_cliente.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Nombre';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Correo electrónico del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Email';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Teléfono del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Telefono';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad del cliente tal como fue recibida desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de registro en el formato original recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Registro';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clientes_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
PRINT N'Documentada: stg.Clientes_Raw (8 columnas).';
GO

/* ---- 2.2 · stg.Ventas_Raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con pedidos recibidos del sistema de ventas, conservando los valores originales como texto.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (ventas) -> script 03 -> stg.Ventas_Raw -> script 05 -> dbo.fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del pedido tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del cliente asociado tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora del pedido en su formato original.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Hora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador de sucursal tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tipo de producto reportado por el sistema de ventas.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'Tipo_Producto';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Importe total del pedido en su formato original.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'Monto_Total';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad de la sucursal tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'Sucursal_Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Ventas_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
PRINT N'Documentada: stg.Ventas_Raw (9 columnas).';
GO

/* ---- 2.3 · stg.Clima_JSON_Raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Almacena la respuesta JSON original de la API climática para conservar evidencia del origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_JSON_Raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'API_Clima_Historico.json -> script 03 -> stg.Clima_JSON_Raw (respuesta completa de la API); se aplana en stg.Clima_Raw.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_JSON_Raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial de la respuesta JSON almacenada.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_JSON_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Respuesta';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Contenido JSON original recibido de la API de clima.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_JSON_Raw',
    @level2type = N'COLUMN', @level2name = N'Respuesta_JSON';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que se almacenó la respuesta JSON.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_JSON_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
PRINT N'Documentada: stg.Clima_JSON_Raw (3 columnas).';
GO

/* ---- 2.4 · stg.Clima_Raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con datos climáticos aplanados por fecha y ciudad antes de su normalización.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'stg.Clima_JSON_Raw (aplanado con OPENJSON) -> stg.Clima_Raw -> script 05 -> dbo.fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de observación climática en el formato original.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Consulta';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de ciudad tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura en grados Celsius tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Temperatura_C';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Descripción climática original recibida.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Condicion_Climatica';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Porcentaje de humedad tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Humedad_Pct';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Clima_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
PRINT N'Documentada: stg.Clima_Raw (7 columnas).';
GO

/* ---- 2.5 · stg.Entregas_Raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con información original de entregas recibida del archivo de origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'CSV_Entregas_ECommerce.csv -> script 03 -> stg.Entregas_Raw -> script 05 -> dbo.fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador de envío tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Envio';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del pedido relacionado tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'ID_Pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de entrega en el formato original.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Minutos de demora tal como fueron recibidos.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'Minutos_Demora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Calificación del cliente tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'Calificacion_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Entregas_Raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
PRINT N'Documentada: stg.Entregas_Raw (7 columnas).';
GO

/* =====================================================================
   BLOQUE 3 · PRUEBAS DE EJECUCIÓN · OPCIÓN B (procedimiento almacenado)
   Una captura del Results Grid por cada llamada (solo las últimas líneas).
   ===================================================================== */
-- Prueba 3.1 · stg.Clientes_Raw
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Clientes_Raw', @esquema = N'stg';
GO

-- Prueba 3.2 · stg.Ventas_Raw
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Ventas_Raw', @esquema = N'stg';
GO

-- Prueba 3.3 · stg.Clima_JSON_Raw
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Clima_JSON_Raw', @esquema = N'stg';
GO

-- Prueba 3.4 · stg.Clima_Raw
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Clima_Raw', @esquema = N'stg';
GO

-- Prueba 3.5 · stg.Entregas_Raw
EXEC dbo.sp_obtener_diccionario_datos @nombre_tabla = N'Entregas_Raw', @esquema = N'stg';
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw')) AS x(esquema, tabla)
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name;
GO

-- 5.2 Cobertura de descripciones
SELECT x.esquema, x.tabla,
       COUNT(c.column_id)  AS columnas_totales,
       COUNT(ep.major_id)  AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM (VALUES (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.extended_properties AS ep
       ON ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description'
GROUP BY x.esquema, x.tabla
ORDER BY x.esquema, x.tabla;
GO

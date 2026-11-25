/* =====================================================================
   CAFECITO · PROYECTO INTEGRADOR · EQUIPO 1 · GRUPO O3
   src/04_vistas_gold_bi.sql
   CAPA ORO Y GOBERNANZA.
     A. Vistas oro: Vista 360° y KPIs                       -> Antonio Hernández (BI)
     B. Procedimientos de consulta de clientes              -> André Campos
     C. plata.sp_obtener_diccionario_datos                  -> André Campos
     D. Metadatos: descripciones y linaje (bronce, plata, oro)
     E. Pruebas de oro y metadatos, y pruebas de procedimientos -> Paulina Martínez (QA)
   Prerrequisitos: src/01, src/02 y src/03.
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

/* =====================================================================
   SECCIÓN A · VISTAS ORO (oro.vw_*)
   ===================================================================== */
/* VISTA 1 · OPERATIVA */
CREATE OR ALTER VIEW oro.vw_ventas_operativa
AS
SELECT  p.pedido_id,
        p.fecha,
        CONVERT(CHAR(5), p.fecha_hora, 108)                 AS hora,
        DATEPART(HOUR, p.fecha_hora)                        AS hora_del_dia,
        s.sucursal_id,
        s.nombre_sucursal,
        ci.nombre_ciudad                                    AS ciudad_sucursal,
        ca.nombre_categoria                                 AS categoria,
        ca.temperatura_servicio,
        p.monto_total,
        CASE WHEN e.envio_id IS NULL THEN N'RECOGE EN SUCURSAL'
             ELSE N'ENTREGA A DOMICILIO' END                AS canal_venta
FROM plata.fact_pedido                AS p
INNER JOIN plata.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
INNER JOIN plata.dim_ciudad           AS ci ON ci.ciudad_id    = s.ciudad_id
INNER JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
LEFT  JOIN plata.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id;
GO

/* VISTA 2 · ANALÍTICA 360° DEL CLIENTE */
CREATE OR ALTER VIEW oro.vw_analitica_360_cliente
AS
SELECT  c.cliente_id,
        c.nombre_completo,
        c.email,
        ISNULL(c.telefono, 'SIN TELÉFONO')                  AS telefono,
        cc.nombre_ciudad                                    AS ciudad_cliente,
        p.pedido_id,
        p.fecha_hora,
        p.fecha                                             AS fecha_pedido,
        s.nombre_sucursal,
        cs.nombre_ciudad                                    AS ciudad_sucursal,
        ca.nombre_categoria                                 AS categoria,
        p.monto_total,
        cl.condicion_climatica,
        cl.temperatura_c,
        cl.humedad_pct,
        CASE WHEN cl.temperatura_c IS NULL THEN NULL
             WHEN cl.temperatura_c < 18   THEN N'FRÍO (<18 °C)'
             WHEN cl.temperatura_c <= 25  THEN N'TEMPLADO (18-25 °C)'
             ELSE N'CALUROSO (>25 °C)' END                  AS rango_temperatura,
        e.envio_id,
        e.fecha_entrega,
        e.minutos_demora,
        e.calificacion_cliente,
        CASE WHEN e.envio_id IS NULL            THEN NULL
             WHEN e.minutos_demora > 45         THEN N'SÍ' ELSE N'NO' END       AS entrega_tardia,
        CASE WHEN e.envio_id IS NULL            THEN NULL
             WHEN e.calificacion_cliente <= 2   THEN N'INSATISFECHO'
             WHEN e.calificacion_cliente = 3    THEN N'NEUTRAL'
             ELSE N'SATISFECHO' END                                            AS nivel_satisfaccion,
        COALESCE(e.demora_imputada, 0)                      AS demora_imputada,
        COALESCE(e.calificacion_imputada, 0)                AS calificacion_imputada
FROM plata.dim_cliente                AS c
INNER JOIN plata.dim_ciudad           AS cc ON cc.ciudad_id    = c.ciudad_id
LEFT  JOIN plata.fact_pedido          AS p  ON p.cliente_id    = c.cliente_id
LEFT  JOIN plata.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
LEFT  JOIN plata.dim_ciudad           AS cs ON cs.ciudad_id    = s.ciudad_id
LEFT  JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
LEFT  JOIN plata.fact_clima_diario    AS cl ON cl.fecha        = p.fecha
                                         AND cl.ciudad_id    = s.ciudad_id
LEFT  JOIN plata.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id;
GO

/* VISTA 3 · KPI CONSUMO vs CLIMA */
CREATE OR ALTER VIEW oro.vw_kpi_consumo_por_clima
AS
SELECT  cl.condicion_climatica,
        ca.nombre_categoria                                                   AS categoria,
        COUNT(*)                                                              AS num_pedidos,
        SUM(p.monto_total)                                                    AS venta_total_mxn,
        CAST(AVG(p.monto_total) AS DECIMAL(10,2))                             AS ticket_promedio_mxn,
        CAST(AVG(cl.temperatura_c) AS DECIMAL(4,1))                           AS temp_promedio_c,
        CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cl.condicion_climatica)
             AS DECIMAL(5,2))                                                 AS pct_pedidos_en_ese_clima
FROM plata.fact_pedido                AS p
INNER JOIN plata.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
INNER JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
INNER JOIN plata.fact_clima_diario    AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
GROUP BY cl.condicion_climatica, ca.nombre_categoria;
GO

/* VISTA 4 · KPI LOGÍSTICA Y SATISFACCIÓN vs CLIMA */
CREATE OR ALTER VIEW oro.vw_kpi_logistica_por_clima
AS
SELECT  cl.condicion_climatica,
        COUNT(*)                                                              AS num_entregas,
        CAST(AVG(CAST(e.minutos_demora AS DECIMAL(10,2))) AS DECIMAL(10,2))   AS demora_promedio_min,
        MAX(e.minutos_demora)                                                 AS demora_maxima_min,
        CAST(AVG(CAST(e.calificacion_cliente AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS calificacion_promedio,
        CAST(100.0 * SUM(CASE WHEN e.calificacion_cliente <= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_clientes_insatisfechos,
        CAST(100.0 * SUM(CASE WHEN e.minutos_demora > 45      THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_entregas_tardias,
        SUM(CAST(e.demora_imputada AS INT) + CAST(e.calificacion_imputada AS INT)) AS valores_imputados
FROM plata.fact_entrega         AS e
INNER JOIN plata.fact_pedido    AS p  ON p.pedido_id   = e.pedido_id
INNER JOIN plata.dim_sucursal   AS s  ON s.sucursal_id = p.sucursal_id
INNER JOIN plata.fact_clima_diario AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
GROUP BY cl.condicion_climatica;
GO

/* VISTA 5 · RESUMEN EJECUTIVO POR SUCURSAL */
CREATE OR ALTER VIEW oro.vw_kpi_resumen_sucursal
AS
SELECT  s.sucursal_id,
        s.nombre_sucursal,
        ci.nombre_ciudad                                                      AS ciudad,
        COUNT(p.pedido_id)                                                    AS num_pedidos,
        COUNT(DISTINCT p.cliente_id)                                          AS clientes_distintos,
        SUM(p.monto_total)                                                    AS venta_total_mxn,
        CAST(AVG(p.monto_total) AS DECIMAL(10,2))                             AS ticket_promedio_mxn,
        COUNT(e.envio_id)                                                     AS num_entregas,
        CAST(100.0 * COUNT(e.envio_id) / NULLIF(COUNT(p.pedido_id), 0) AS DECIMAL(5,2)) AS pct_pedidos_a_domicilio,
        CAST(AVG(CAST(e.minutos_demora AS DECIMAL(10,2))) AS DECIMAL(10,2))   AS demora_promedio_min,
        CAST(AVG(CAST(e.calificacion_cliente AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS calificacion_promedio
FROM plata.dim_sucursal       AS s
INNER JOIN plata.dim_ciudad   AS ci ON ci.ciudad_id  = s.ciudad_id
LEFT  JOIN plata.fact_pedido  AS p  ON p.sucursal_id = s.sucursal_id
LEFT  JOIN plata.fact_entrega AS e  ON e.pedido_id   = p.pedido_id
GROUP BY s.sucursal_id, s.nombre_sucursal, ci.nombre_ciudad;
GO

/* =====================================================================
   SECCIÓN B · PROCEDIMIENTOS DE CONSULTA (cliente e historial)
   ===================================================================== */
/* SP 2 · CONSULTA BÁSICA DE ENTIDAD POR ID (acepta espacios y minúsculas) */
CREATE OR ALTER PROCEDURE plata.sp_consultar_cliente
    @cliente_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id VARCHAR(10) = UPPER(TRIM(@cliente_id));

    IF NOT EXISTS (SELECT 1 FROM plata.dim_cliente WHERE cliente_id = @id)
    BEGIN
        RAISERROR('No existe un cliente con ID %s.', 16, 1, @id);
        RETURN;
    END

    SELECT  c.cliente_id,
            UPPER(TRIM(c.nombre_completo))                 AS nombre_completo,
            LOWER(TRIM(c.email))                           AS email,
            ISNULL(c.telefono, 'SIN TELÉFONO')             AS telefono,
            ci.nombre_ciudad                               AS ciudad,
            c.fecha_registro,
            COALESCE(r.num_pedidos, 0)                     AS num_pedidos,
            COALESCE(r.total_comprado, 0)                  AS total_comprado_mxn,
            COALESCE(CONVERT(VARCHAR(10), r.ultima_compra, 23), 'SIN COMPRAS') AS ultima_compra
    FROM plata.dim_cliente      AS c
    INNER JOIN plata.dim_ciudad AS ci ON ci.ciudad_id = c.ciudad_id
    LEFT JOIN (SELECT cliente_id, COUNT(*) AS num_pedidos, SUM(monto_total) AS total_comprado, MAX(fecha) AS ultima_compra
               FROM plata.fact_pedido GROUP BY cliente_id) AS r
           ON r.cliente_id = c.cliente_id
    WHERE c.cliente_id = @id;
END;
GO

/* SP 3 · HISTORIAL DE PEDIDOS DE UN CLIENTE */
CREATE OR ALTER PROCEDURE plata.sp_historial_pedidos_cliente
    @cliente_id   VARCHAR(10),
    @fecha_inicio DATE = NULL,
    @fecha_fin    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id VARCHAR(10) = UPPER(TRIM(@cliente_id));
    SET @fecha_inicio = ISNULL(@fecha_inicio, '19000101');
    SET @fecha_fin    = ISNULL(@fecha_fin,    '99991231');

    IF @fecha_inicio > @fecha_fin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor que la fecha fin.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM plata.dim_cliente WHERE cliente_id = @id)
    BEGIN
        RAISERROR('No existe un cliente con ID %s.', 16, 1, @id);
        RETURN;
    END

    SELECT  c.cliente_id,
            c.nombre_completo,
            p.pedido_id,
            p.fecha_hora,
            ca.nombre_categoria                              AS categoria,
            s.nombre_sucursal,
            p.monto_total,
            ISNULL(cl.condicion_climatica, N'SIN DATO')      AS clima_del_dia,
            cl.temperatura_c,
            COALESCE(e.envio_id, N'RECOGIÓ EN SUCURSAL')     AS envio_id,
            e.minutos_demora,
            e.calificacion_cliente
    FROM plata.dim_cliente                AS c
    INNER JOIN plata.fact_pedido          AS p  ON p.cliente_id    = c.cliente_id
    INNER JOIN plata.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
    INNER JOIN plata.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
    LEFT  JOIN plata.fact_clima_diario    AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
    LEFT  JOIN plata.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id
    WHERE c.cliente_id = @id
      AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
    ORDER BY p.fecha_hora;
END;
GO

/* =====================================================================
   SECCIÓN C · DICCIONARIO DE DATOS
   EXEC plata.sp_obtener_diccionario_datos @nombre_tabla = N'dim_cliente';
   EXEC plata.sp_obtener_diccionario_datos @nombre_tabla = N'ventas_raw', @esquema = N'bronce';
   ===================================================================== */
CREATE OR ALTER PROCEDURE plata.sp_obtener_diccionario_datos
    @nombre_tabla SYSNAME = NULL,
    @esquema      SYSNAME = N'plata'
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
GO

/* =====================================================================
   SECCIÓN D · GOBERNANZA: METADATOS CON PROPIEDADES EXTENDIDAS
   MS_Description = descripción de negocio · linaje_origen = recorrido del dato.
   Repetible: primero elimina las descripciones previas de bronce, plata y oro.
   ===================================================================== */
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'EXEC sys.sp_dropextendedproperty @name = N''' + ep.name + N''', '
             + N'@level0type = N''SCHEMA'', @level0name = N''' + s.name + N''', '
             + N'@level1type = N''' + CASE o.type WHEN 'U' THEN N'TABLE' ELSE N'VIEW' END + N''', @level1name = N''' + o.name + N''''
             + CASE WHEN ep.minor_id > 0 THEN N', @level2type = N''COLUMN'', @level2name = N''' + c.name + N'''' ELSE N'' END
             + N';' + CHAR(13) + CHAR(10)
FROM sys.extended_properties AS ep
JOIN sys.objects AS o ON o.object_id = ep.major_id AND o.type IN ('U', 'V')
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
WHERE ep.class = 1 AND ep.name IN (N'MS_Description', N'linaje_origen')
  AND s.name IN (N'bronce', N'plata', N'oro') AND (ep.minor_id = 0 OR c.column_id IS NOT NULL);
IF @sql <> N'' EXEC sys.sp_executesql @sql;
GO

/* ---- bronce.clientes_raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con datos de clientes recibidos desde el sistema de origen, antes de la limpieza.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (clientes) -> src/02 -> bronce.clientes_raw -> src/03 -> plata.dim_cliente.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Nombre';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Correo electrónico del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Email';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Teléfono del cliente tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Telefono';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad del cliente tal como fue recibida desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de registro en el formato original recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Registro';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clientes_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
GO

/* ---- bronce.ventas_raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con pedidos recibidos del sistema de ventas, conservando los valores originales como texto.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (ventas) -> src/02 -> bronce.ventas_raw -> src/03 -> plata.fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del pedido tal como fue recibido desde el origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del cliente asociado tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora del pedido en su formato original.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Hora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador de sucursal tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tipo de producto reportado por el sistema de ventas.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'Tipo_Producto';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Importe total del pedido en su formato original.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'Monto_Total';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad de la sucursal tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'Sucursal_Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'ventas_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
GO

/* ---- bronce.clima_json_raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Almacena la respuesta JSON original de la API climática para conservar evidencia del origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_json_raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'API_Clima_Historico.json -> src/02 -> bronce.clima_json_raw (respuesta completa de la API); se aplana en bronce.clima_raw.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_json_raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial de la respuesta JSON almacenada.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_json_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Respuesta';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Contenido JSON original recibido de la API de clima.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_json_raw',
    @level2type = N'COLUMN', @level2name = N'Respuesta_JSON';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que se almacenó la respuesta JSON.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_json_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
GO

/* ---- bronce.clima_raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con datos climáticos aplanados por fecha y ciudad antes de su normalización.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'bronce.clima_json_raw (aplanado con OPENJSON) -> bronce.clima_raw -> src/03 -> plata.fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de observación climática en el formato original.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Consulta';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de ciudad tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura en grados Celsius tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Temperatura_C';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Descripción climática original recibida.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Condicion_Climatica';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Porcentaje de humedad tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Humedad_Pct';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'clima_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
GO

/* ---- bronce.entregas_raw ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Capa de aterrizaje con información original de entregas recibida del archivo de origen.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'CSV_Entregas_ECommerce.csv -> src/02 -> bronce.entregas_raw -> src/03 -> plata.fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador secuencial del registro recibido en staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Carga';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador de envío tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Envio';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del pedido relacionado tal como fue recibido.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'ID_Pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de entrega en el formato original.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Minutos de demora tal como fueron recibidos.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'Minutos_Demora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Calificación del cliente tal como fue recibida.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'Calificacion_Cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que el registro fue cargado a staging.',
    @level0type = N'SCHEMA', @level0name = N'bronce',
    @level1type = N'TABLE', @level1name = N'entregas_raw',
    @level2type = N'COLUMN', @level2name = N'Fecha_Carga';
GO

/* ---- plata.dim_categoria_producto ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra de categorías de producto (bebida caliente, bebida fría y repostería) y su temperatura de servicio; base del análisis de consumo según el clima.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el src/01; el src/03 asigna la categoría a cada pedido a partir de bronce.ventas_raw.Tipo_Producto -> plata.dim_categoria_producto.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la categoría de producto (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'categoria_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre comercial de la categoría de producto; no se repite.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'nombre_categoria';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura a la que se sirve la categoría: CALIENTE, FRÍA o N/A (restringido por regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_categoria_producto',
    @level2type = N'COLUMN', @level2name = N'temperatura_servicio';
GO

/* ---- plata.dim_ciudad ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra (catálogo) de las ciudades y estados donde opera Cafecito; sirve como referencia geográfica de sucursales, clientes y clima.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_ciudad';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el src/01 (dato de referencia ya limpio) -> plata.dim_ciudad. Referenciada por dim_sucursal, dim_cliente y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la ciudad (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre normalizado en mayúsculas de la ciudad (LEÓN, SILAO, GUANAJUATO); no se repite.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'nombre_ciudad';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Estado de la República Mexicana al que pertenece la ciudad.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_ciudad',
    @level2type = N'COLUMN', @level2name = N'estado';
GO

/* ---- plata.dim_cliente ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra con los datos de identificación y contacto de los clientes de Cafecito; base de la Vista 360°. Incluye el cliente genérico CLI-000 para pedidos sin cliente identificado.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (clientes) -> bronce.clientes_raw (src/02) -> limpieza fases 2 a 4 (src/03) -> plata.dim_cliente.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del cliente con formato CLI-NNN (Llave Primaria); CLI-000 agrupa pedidos sin cliente identificado.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'cliente_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre completo del cliente, estandarizado en mayúsculas y sin espacios sobrantes.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'nombre_completo';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Correo electrónico del cliente en minúsculas; único por cliente y con formato validado (regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'email';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Teléfono de contacto del cliente; campo opcional que puede ser nulo.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'telefono';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad de residencia del cliente (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha en que el cliente fue dado de alta en el sistema.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_cliente',
    @level2type = N'COLUMN', @level2name = N'fecha_registro';
GO

/* ---- plata.dim_sucursal ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla maestra de las sucursales físicas de Cafecito y su ciudad; representa el punto de venta que atiende cada pedido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_sucursal';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Catálogo capturado en el src/01 -> plata.dim_sucursal. Referenciada por fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único de la sucursal con formato SUC-NN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'sucursal_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre comercial de la sucursal de Cafecito.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'nombre_sucursal';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad donde se ubica la sucursal (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'dim_sucursal',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
GO

/* ---- plata.fact_clima_diario ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional con el clima registrado por día y ciudad (origen: API meteorológica); se cruza con los pedidos por fecha y ciudad de la sucursal.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'API_Clima_Historico.json -> bronce.clima_json_raw -> bronce.clima_raw (src/02) -> limpieza fases 2 a 4 (src/03) -> plata.fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único autoincremental del registro de clima (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'clima_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha de la observación climática; junto con ciudad_id no se repite.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'fecha';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Ciudad observada (Llave Foránea hacia dim_ciudad.ciudad_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'ciudad_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Temperatura registrada en grados Celsius.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'temperatura_c';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Condición del día: LLUVIA INTENSA, CALUROSO, NUBLADO o TEMPLADO (regla CHECK).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'condicion_climatica';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Humedad relativa en porcentaje (0 a 100); puede ser nula si el dato original era inválido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'humedad_pct';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que la temperatura se completó con el promedio de su ciudad.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_clima_diario',
    @level2type = N'COLUMN', @level2name = N'temperatura_imputada';
GO

/* ---- plata.fact_entrega ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional de entregas a domicilio (relación 1 a 1 con el pedido) con demora y calificación del cliente; base del análisis de logística y satisfacción.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'CSV_Entregas_ECommerce.csv -> bronce.entregas_raw (src/02) -> limpieza fases 2 a 4 (src/03) -> plata.fact_entrega. Las entregas sin pedido se envían a plata.registros_rechazados.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del envío con formato ENV-NNN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'envio_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Pedido entregado (Llave Foránea hacia fact_pedido.pedido_id; no se repite, relación 1 a 1).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'pedido_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha en que se realizó la entrega.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'fecha_entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Minutos de demora de la entrega (mayor o igual a 0); si faltaba se imputó con la mediana.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'minutos_demora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Calificación del cliente de 1 a 5; si faltaba se imputó con la moda.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'calificacion_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que los minutos de demora fueron imputados.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'demora_imputada';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que la calificación del cliente fue imputada.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'calificacion_imputada';
GO

/* ---- plata.fact_pedido ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional de pedidos del e-commerce: cliente, sucursal, categoría, fecha y monto. Contiene una fila por pedido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'BD_Ventas_Cafecito (ventas) -> bronce.ventas_raw (src/02) -> limpieza fases 2 a 4 (src/03) -> plata.fact_pedido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del pedido con formato PED-NNN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'pedido_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Cliente que realizó el pedido (Llave Foránea hacia dim_cliente.cliente_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'cliente_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Sucursal que atendió el pedido (Llave Foránea hacia dim_sucursal.sucursal_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'sucursal_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Categoría del producto pedido (Llave Foránea hacia dim_categoria_producto.categoria_id).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'categoria_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora exactas en que se registró el pedido.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'fecha_hora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha del pedido (columna calculada y persistida a partir de fecha_hora); llave temporal para cruzar con fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'fecha';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Importe total del pedido en pesos mexicanos (MXN); no puede ser negativo.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'fact_pedido',
    @level2type = N'COLUMN', @level2name = N'monto_total';
GO

/* ---- plata.bitacora_limpieza ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Bitácora del pipeline de limpieza: cada paso con su fase, tabla, acción y registros afectados (evidencia de auditoría).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Alimentada por plata.sp_limpiar_y_cargar_plata; se reinicia en cada ejecución.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único autoincremental del paso (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'paso_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fase del pipeline: 2-Estandarización, 3-Deduplicación, 4-Validación, 4-Imputación o 4-Carga.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'fase';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Entidad o tabla afectada por el paso.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'tabla';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Descripción de la acción realizada.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'accion';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Número de registros afectados.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'registros';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora del paso.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'bitacora_limpieza',
    @level2type = N'COLUMN', @level2name = N'fecha';
GO

/* ---- plata.registros_rechazados ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Bitácora de registros descartados durante la integración por incumplir reglas de calidad o integridad.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Alimentada por la validación relacional (LEFT JOIN) de la fase 4 del src/03; conserva lo que no pasó las reglas de integridad.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del registro rechazado.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados',
    @level2type = N'COLUMN', @level2name = N'rechazo_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Sistema o archivo de donde proviene el registro rechazado.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados',
    @level2type = N'COLUMN', @level2name = N'origen';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del registro rechazado en el sistema de origen.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados',
    @level2type = N'COLUMN', @level2name = N'llave_registro';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Descripción de la regla o motivo por el que el registro fue rechazado.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados',
    @level2type = N'COLUMN', @level2name = N'motivo';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que se registró el rechazo.',
    @level0type = N'SCHEMA', @level0name = N'plata',
    @level1type = N'TABLE', @level1name = N'registros_rechazados',
    @level2type = N'COLUMN', @level2name = N'fecha_rechazo';
GO

/* ---- vistas de oro ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Vista operativa: pedidos limpios con sucursal, ciudad, categoría y canal de venta (domicilio o recoge en sucursal). Origen: fact_pedido, dim_sucursal, dim_ciudad, dim_categoria_producto y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'oro',
    @level1type = N'VIEW', @level1name = N'vw_ventas_operativa';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Vista analítica 360° del cliente: parte de dim_cliente y cruza pedidos, entrega y clima del día (incluye clientes sin compras). Origen: dim_cliente, fact_pedido, dim_sucursal, dim_ciudad, dim_categoria_producto, fact_clima_diario y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'oro',
    @level1type = N'VIEW', @level1name = N'vw_analitica_360_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI de consumo: pedidos, venta, ticket promedio y porcentaje por categoría en cada condición climática. Origen: fact_pedido, dim_sucursal, dim_categoria_producto y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'oro',
    @level1type = N'VIEW', @level1name = N'vw_kpi_consumo_por_clima';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI de logística y satisfacción: demora, calificación, porcentaje de insatisfechos y de entregas tardías por condición climática. Origen: fact_entrega, fact_pedido, dim_sucursal y fact_clima_diario.',
    @level0type = N'SCHEMA', @level0name = N'oro',
    @level1type = N'VIEW', @level1name = N'vw_kpi_logistica_por_clima';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'KPI ejecutivo por sucursal: pedidos, venta, ticket, clientes distintos, porcentaje a domicilio, demora y calificación. Origen: dim_sucursal, dim_ciudad, fact_pedido y fact_entrega.',
    @level0type = N'SCHEMA', @level0name = N'oro',
    @level1type = N'VIEW', @level1name = N'vw_kpi_resumen_sucursal';
GO

/* ---- Verificación: cobertura de descripciones (debe decir ✔ 100 %) ---- */
SELECT s.name AS esquema, t.name AS tabla, COUNT(c.column_id) AS columnas_totales, COUNT(ep.major_id) AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.extended_properties AS ep ON ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description'
WHERE s.name IN (N'bronce', N'plata') GROUP BY s.name, t.name ORDER BY s.name, t.name;
GO

/* =====================================================================
   SECCIÓN E · PRUEBAS
   ===================================================================== */
/* Pruebas de oro y metadatos: todas las filas deben decir ✔ PASA */
SET NOCOUNT ON;
DECLARE @pruebas TABLE (id INT IDENTITY(1,1), categoria NVARCHAR(30), prueba NVARCHAR(150), esperado NVARCHAR(30), obtenido NVARCHAR(30));

-- A.6 Vistas
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Vistas', N'vw_ventas_operativa: filas', N'129', CAST((SELECT COUNT(*) FROM oro.vw_ventas_operativa) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'vw_analitica_360: clientes sin compras', N'3',
       CAST((SELECT COUNT(*) FROM oro.vw_analitica_360_cliente WHERE pedido_id IS NULL) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Venta total MXN', N'19310.00', CAST((SELECT SUM(venta_total_mxn) FROM oro.vw_kpi_consumo_por_clima) AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Demora promedio con LLUVIA INTENSA (min)', N'51.04',
       CAST((SELECT demora_promedio_min FROM oro.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con LLUVIA INTENSA', N'2.26',
       CAST((SELECT calificacion_promedio FROM oro.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'LLUVIA INTENSA') AS NVARCHAR(30))
UNION ALL SELECT N'Vistas', N'Calificación promedio con clima TEMPLADO', N'4.29',
       CAST((SELECT calificacion_promedio FROM oro.vw_kpi_logistica_por_clima WHERE condicion_climatica = N'TEMPLADO') AS NVARCHAR(30));

-- A.7 Metadatos y nomenclatura
INSERT INTO @pruebas (categoria, prueba, esperado, obtenido)
SELECT N'Metadatos', N'Tablas de plata sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'plata' AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = t.object_id AND ep.minor_id = 0 AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Columnas de plata sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'plata' AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Tablas de bronce sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'bronce' AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = t.object_id AND ep.minor_id = 0 AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Vistas de oro sin descripción de negocio', N'0',
       CAST((SELECT COUNT(*) FROM sys.views v JOIN sys.schemas s ON s.schema_id = v.schema_id
             WHERE s.name = N'oro' AND NOT EXISTS (SELECT 1 FROM sys.extended_properties ep WHERE ep.class = 1 AND ep.major_id = v.object_id AND ep.minor_id = 0 AND ep.name = N'MS_Description')) AS NVARCHAR(30))
UNION ALL SELECT N'Metadatos', N'Tablas y columnas de plata fuera de snake_case', N'0',
       CAST((SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'plata' AND t.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%') +
            (SELECT COUNT(*) FROM sys.columns c JOIN sys.tables t ON t.object_id = c.object_id JOIN sys.schemas s ON s.schema_id = t.schema_id
             WHERE s.name = N'plata' AND c.name COLLATE Latin1_General_BIN2 LIKE N'%[^a-z0-9_]%') AS NVARCHAR(30));

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
    EXEC plata.sp_registrar_cliente
         @nombre_completo     = N'   paulina   prueba qa  ',
         @email               = '  PAULINA.QA@Correo.COM ',
         @telefono            = '4771234567',
         @ciudad              = N'leon',
         @cliente_id_generado = @nuevo_id OUTPUT;
    SELECT @nuevo_id AS id_generado;                                      -- esperado: CLI-041
    SELECT * FROM plata.dim_cliente WHERE cliente_id = @nuevo_id;           -- nombre en mayúsculas, email en minúsculas
ROLLBACK TRANSACTION;
GO

PRINT '--- SP1 caso de error: email duplicado ---';
BEGIN TRY
    EXEC plata.sp_registrar_cliente @nombre_completo = N'Cliente Repetido', @email = 'MARIA.NAVARRO1@correo.com', @ciudad = N'León';
END TRY
BEGIN CATCH
    SELECT N'SP1 - duplicado' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP1 caso de error: ciudad inexistente ---';
BEGIN TRY
    EXEC plata.sp_registrar_cliente @nombre_completo = N'Cliente Foráneo', @email = 'foraneo@correo.com', @ciudad = N'Monterrey';
END TRY
BEGIN CATCH
    SELECT N'SP1 - ciudad inválida' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP2 consulta por ID (acepta espacios y minúsculas) ---';
EXEC plata.sp_consultar_cliente @cliente_id = '  cli-001 ';   -- 7 pedidos
EXEC plata.sp_consultar_cliente @cliente_id = 'CLI-038';      -- cliente sin compras: 0 / SIN COMPRAS
BEGIN TRY
    EXEC plata.sp_consultar_cliente @cliente_id = 'CLI-999';
END TRY
BEGIN CATCH
    SELECT N'SP2 - ID inexistente' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

PRINT '--- SP3 historial por rango de fechas ---';
EXEC plata.sp_historial_pedidos_cliente @cliente_id = 'CLI-001', @fecha_inicio = '20260801', @fecha_fin = '20260807';  -- 4 pedidos
EXEC plata.sp_historial_pedidos_cliente @cliente_id = 'CLI-001';                                                      -- historial completo: 7
BEGIN TRY
    EXEC plata.sp_historial_pedidos_cliente @cliente_id = 'CLI-001', @fecha_inicio = '20260831', @fecha_fin = '20260801';
END TRY
BEGIN CATCH
    SELECT N'SP3 - rango inválido' AS prueba, ERROR_MESSAGE() AS mensaje_esperado;
END CATCH;
GO

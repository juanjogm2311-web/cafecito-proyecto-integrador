/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3 - BD_Cafecito
   Entrega 2 · Semana 9 (P9) · Metadatos con propiedades extendidas
   Script 15 · METADATOS CONSOLIDADO DEL EQUIPO (13 tablas + 5 vistas)
   Uso: integración final y repositorio de GitHub (Entrega 3). Reúne las 5 partes P9.
   Integrante : Juan José Gómez Montúfar  (Líder de proyecto / integración)
   Matrícula  : 196549-9
   Fecha      : 30/10/2026
   Prerrequisito: haber ejecutado 10, 11, 12 y 13 (paquete común).
   ===================================================================== */
USE BD_Cafecito;
GO
SET NOCOUNT ON;
GO

/* BLOQUE 1 · Limpieza previa */
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
              FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto'), (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido'), (N'dbo', N'fact_clima_diario'), (N'dbo', N'fact_entrega'), (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw'), (N'stg', N'Registros_Rechazados')) AS x(esquema, tabla)
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

/* BLOQUE 2 · Propiedades extendidas */
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

/* ---- 2.4 · dbo.dim_cliente ---- */
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

/* ---- 2.5 · dbo.fact_pedido ---- */
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

/* ---- 2.6 · dbo.fact_clima_diario ---- */
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

/* ---- 2.7 · dbo.fact_entrega ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Tabla transaccional de entregas a domicilio (relación 1 a 1 con el pedido) con demora y calificación del cliente; base del análisis de logística y satisfacción.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'CSV_Entregas_ECommerce.csv -> stg.Entregas_Raw (script 03) -> limpieza fases 2 a 4 (script 05) -> dbo.fact_entrega. Las entregas sin pedido se envían a stg.Registros_Rechazados.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del envío con formato ENV-NNN (Llave Primaria).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'envio_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Pedido entregado (Llave Foránea hacia fact_pedido.pedido_id; no se repite, relación 1 a 1).',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'pedido_id';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha en que se realizó la entrega.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'fecha_entrega';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Minutos de demora de la entrega (mayor o igual a 0); si faltaba se imputó con la mediana.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'minutos_demora';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Calificación del cliente de 1 a 5; si faltaba se imputó con la moda.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'calificacion_cliente';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que los minutos de demora fueron imputados.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'demora_imputada';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Indicador (1 = sí, 0 = no) de que la calificación del cliente fue imputada.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'fact_entrega',
    @level2type = N'COLUMN', @level2name = N'calificacion_imputada';
PRINT N'Documentada: dbo.fact_entrega (7 columnas).';
GO

/* ---- 2.8 · stg.Clientes_Raw ---- */
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

/* ---- 2.9 · stg.Ventas_Raw ---- */
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

/* ---- 2.10 · stg.Clima_JSON_Raw ---- */
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

/* ---- 2.11 · stg.Clima_Raw ---- */
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

/* ---- 2.12 · stg.Entregas_Raw ---- */
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

/* ---- 2.13 · stg.Registros_Rechazados ---- */
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Bitácora de registros descartados durante la integración por incumplir reglas de calidad o integridad.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados';
EXEC sys.sp_addextendedproperty @name = N'linaje_origen', @value = N'Alimentada por la validación relacional (LEFT JOIN) de la fase 4 del script 05; conserva lo que no pasó las reglas de integridad.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador único del registro rechazado.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados',
    @level2type = N'COLUMN', @level2name = N'ID_Rechazo';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Sistema o archivo de donde proviene el registro rechazado.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados',
    @level2type = N'COLUMN', @level2name = N'Origen';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Identificador del registro rechazado en el sistema de origen.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados',
    @level2type = N'COLUMN', @level2name = N'Llave_Registro';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Descripción de la regla o motivo por el que el registro fue rechazado.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados',
    @level2type = N'COLUMN', @level2name = N'Motivo';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Fecha y hora en que se registró el rechazo.',
    @level0type = N'SCHEMA', @level0name = N'stg',
    @level1type = N'TABLE', @level1name = N'Registros_Rechazados',
    @level2type = N'COLUMN', @level2name = N'Fecha_Rechazo';
PRINT N'Documentada: stg.Registros_Rechazados (5 columnas).';
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

/* BLOQUE 3 · Verificación global */
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
WHERE EXISTS (SELECT 1 FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto'), (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido'), (N'dbo', N'fact_clima_diario'), (N'dbo', N'fact_entrega'), (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw'), (N'stg', N'Registros_Rechazados')) AS x(esquema, tabla)
              WHERE x.esquema = s.name AND x.tabla = t.name)
ORDER BY s.name, t.name;
GO

-- 5.2 Cobertura de descripciones
SELECT x.esquema, x.tabla,
       COUNT(c.column_id)  AS columnas_totales,
       COUNT(ep.major_id)  AS columnas_documentadas,
       CASE WHEN COUNT(c.column_id) = COUNT(ep.major_id) THEN N'✔ 100 %' ELSE N'✘ INCOMPLETO' END AS cobertura
FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto'), (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido'), (N'dbo', N'fact_clima_diario'), (N'dbo', N'fact_entrega'), (N'stg', N'Clientes_Raw'), (N'stg', N'Ventas_Raw'), (N'stg', N'Clima_JSON_Raw'), (N'stg', N'Clima_Raw'), (N'stg', N'Entregas_Raw'), (N'stg', N'Registros_Rechazados')) AS x(esquema, tabla)
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
FROM (VALUES (N'dbo', N'dim_ciudad'), (N'dbo', N'dim_sucursal'), (N'dbo', N'dim_categoria_producto'), (N'dbo', N'dim_cliente'), (N'dbo', N'fact_pedido'), (N'dbo', N'fact_clima_diario'), (N'dbo', N'fact_entrega')) AS x(esquema, tabla)
JOIN sys.schemas AS s ON s.name = x.esquema
JOIN sys.tables  AS t ON t.schema_id = s.schema_id AND t.name = x.tabla
ORDER BY x.tabla;
GO

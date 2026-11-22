/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   Script 11 · VISTAS ANALÍTICAS con nomenclatura estándar (reemplaza al 06)
   Responsable: Antonio Hernández Ontiveros (BI & Analytics Specialist)
   Misma lógica y mismos resultados que el script 06; solo cambian los nombres.
   Prerrequisito: script 10.
   ===================================================================== */
USE BD_Cafecito;
GO

/* VISTA 1 · OPERATIVA */
CREATE OR ALTER VIEW dbo.vw_ventas_operativa
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
FROM dbo.fact_pedido                AS p
INNER JOIN dbo.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
INNER JOIN dbo.dim_ciudad           AS ci ON ci.ciudad_id    = s.ciudad_id
INNER JOIN dbo.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
LEFT  JOIN dbo.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id;
GO

/* VISTA 2 · ANALÍTICA 360° DEL CLIENTE */
CREATE OR ALTER VIEW dbo.vw_analitica_360_cliente
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
FROM dbo.dim_cliente                AS c
INNER JOIN dbo.dim_ciudad           AS cc ON cc.ciudad_id    = c.ciudad_id
LEFT  JOIN dbo.fact_pedido          AS p  ON p.cliente_id    = c.cliente_id
LEFT  JOIN dbo.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
LEFT  JOIN dbo.dim_ciudad           AS cs ON cs.ciudad_id    = s.ciudad_id
LEFT  JOIN dbo.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
LEFT  JOIN dbo.fact_clima_diario    AS cl ON cl.fecha        = p.fecha
                                         AND cl.ciudad_id    = s.ciudad_id
LEFT  JOIN dbo.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id;
GO

/* VISTA 3 · KPI CONSUMO vs CLIMA */
CREATE OR ALTER VIEW dbo.vw_kpi_consumo_por_clima
AS
SELECT  cl.condicion_climatica,
        ca.nombre_categoria                                                   AS categoria,
        COUNT(*)                                                              AS num_pedidos,
        SUM(p.monto_total)                                                    AS venta_total_mxn,
        CAST(AVG(p.monto_total) AS DECIMAL(10,2))                             AS ticket_promedio_mxn,
        CAST(AVG(cl.temperatura_c) AS DECIMAL(4,1))                           AS temp_promedio_c,
        CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cl.condicion_climatica)
             AS DECIMAL(5,2))                                                 AS pct_pedidos_en_ese_clima
FROM dbo.fact_pedido                AS p
INNER JOIN dbo.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
INNER JOIN dbo.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
INNER JOIN dbo.fact_clima_diario    AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
GROUP BY cl.condicion_climatica, ca.nombre_categoria;
GO

/* VISTA 4 · KPI LOGÍSTICA Y SATISFACCIÓN vs CLIMA */
CREATE OR ALTER VIEW dbo.vw_kpi_logistica_por_clima
AS
SELECT  cl.condicion_climatica,
        COUNT(*)                                                              AS num_entregas,
        CAST(AVG(CAST(e.minutos_demora AS DECIMAL(10,2))) AS DECIMAL(10,2))   AS demora_promedio_min,
        MAX(e.minutos_demora)                                                 AS demora_maxima_min,
        CAST(AVG(CAST(e.calificacion_cliente AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS calificacion_promedio,
        CAST(100.0 * SUM(CASE WHEN e.calificacion_cliente <= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_clientes_insatisfechos,
        CAST(100.0 * SUM(CASE WHEN e.minutos_demora > 45      THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_entregas_tardias,
        SUM(CAST(e.demora_imputada AS INT) + CAST(e.calificacion_imputada AS INT)) AS valores_imputados
FROM dbo.fact_entrega         AS e
INNER JOIN dbo.fact_pedido    AS p  ON p.pedido_id   = e.pedido_id
INNER JOIN dbo.dim_sucursal   AS s  ON s.sucursal_id = p.sucursal_id
INNER JOIN dbo.fact_clima_diario AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
GROUP BY cl.condicion_climatica;
GO

/* VISTA 5 · RESUMEN EJECUTIVO POR SUCURSAL */
CREATE OR ALTER VIEW dbo.vw_kpi_resumen_sucursal
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
FROM dbo.dim_sucursal       AS s
INNER JOIN dbo.dim_ciudad   AS ci ON ci.ciudad_id  = s.ciudad_id
LEFT  JOIN dbo.fact_pedido  AS p  ON p.sucursal_id = s.sucursal_id
LEFT  JOIN dbo.fact_entrega AS e  ON e.pedido_id   = p.pedido_id
GROUP BY s.sucursal_id, s.nombre_sucursal, ci.nombre_ciudad;
GO

/* ---------- Consultas de demostración (para capturas) ---------- */
SELECT TOP (10) * FROM dbo.vw_ventas_operativa ORDER BY fecha, hora;
SELECT TOP (10) * FROM dbo.vw_analitica_360_cliente WHERE pedido_id IS NOT NULL ORDER BY fecha_hora;
SELECT * FROM dbo.vw_analitica_360_cliente WHERE pedido_id IS NULL;
SELECT * FROM dbo.vw_kpi_consumo_por_clima ORDER BY condicion_climatica, num_pedidos DESC;
SELECT * FROM dbo.vw_kpi_logistica_por_clima ORDER BY demora_promedio_min DESC;
SELECT * FROM dbo.vw_kpi_resumen_sucursal ORDER BY venta_total_mxn DESC;
GO

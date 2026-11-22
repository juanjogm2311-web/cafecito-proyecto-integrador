/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 06 · VISTAS ANALÍTICAS CORPORATIVAS
   Responsable: Antonio Hernández Ontiveros (BI & Analytics Specialist)
   ===================================================================== */
USE BD_Cafecito;
GO

/* ---------------------------------------------------------------------
   VISTA 1 · OPERATIVA: pedidos ya limpios y sin anomalías, con nombres
   legibles en lugar de códigos.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_Ventas_Operativa
AS
SELECT  p.ID_Pedido,
        p.Fecha,
        CONVERT(CHAR(5), p.Fecha_Hora, 108)                 AS Hora,
        DATEPART(HOUR, p.Fecha_Hora)                        AS Hora_Del_Dia,
        s.ID_Sucursal,
        s.Nombre_Sucursal,
        ci.Nombre_Ciudad                                    AS Ciudad_Sucursal,
        ca.Nombre_Categoria                                 AS Categoria,
        ca.Temperatura_Servicio,
        p.Monto_Total,
        CASE WHEN e.ID_Envio IS NULL THEN N'RECOGE EN SUCURSAL'
             ELSE N'ENTREGA A DOMICILIO' END                AS Canal_Venta
FROM dbo.Pedido                     AS p
INNER JOIN dbo.Sucursal             AS s  ON s.ID_Sucursal   = p.ID_Sucursal
INNER JOIN dbo.Ciudad               AS ci ON ci.ID_Ciudad    = s.ID_Ciudad
INNER JOIN dbo.Categoria_Producto   AS ca ON ca.ID_Categoria = p.ID_Categoria
LEFT  JOIN dbo.Entrega              AS e  ON e.ID_Pedido     = p.ID_Pedido;
GO

/* ---------------------------------------------------------------------
   VISTA 2 · ANALÍTICA 360°: parte de la tabla MAESTRA de clientes y
   cruza todas las transaccionales (pedido, entrega) + clima del día y
   ciudad de la sucursal. LEFT JOIN para no perder clientes sin compras
   ni pedidos sin entrega (recogidos en sucursal).
   Es el "Datamart Cafecito" del diagrama de integración.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_Analitica_360_Cliente
AS
SELECT  c.ID_Cliente,
        c.Nombre_Completo,
        c.Email,
        ISNULL(c.Telefono, 'SIN TELÉFONO')                  AS Telefono,
        cc.Nombre_Ciudad                                    AS Ciudad_Cliente,
        p.ID_Pedido,
        p.Fecha_Hora,
        p.Fecha                                             AS Fecha_Pedido,
        s.Nombre_Sucursal,
        cs.Nombre_Ciudad                                    AS Ciudad_Sucursal,
        ca.Nombre_Categoria                                 AS Categoria,
        p.Monto_Total,
        cl.Condicion_Climatica,
        cl.Temperatura_C,
        cl.Humedad_Pct,
        CASE WHEN cl.Temperatura_C IS NULL THEN NULL
             WHEN cl.Temperatura_C < 18   THEN N'FRÍO (<18 °C)'
             WHEN cl.Temperatura_C <= 25  THEN N'TEMPLADO (18-25 °C)'
             ELSE N'CALUROSO (>25 °C)' END                  AS Rango_Temperatura,
        e.ID_Envio,
        e.Fecha_Entrega,
        e.Minutos_Demora,
        e.Calificacion_Cliente,
        CASE WHEN e.ID_Envio IS NULL            THEN NULL
             WHEN e.Minutos_Demora > 45         THEN N'SÍ' ELSE N'NO' END       AS Entrega_Tardia,
        CASE WHEN e.ID_Envio IS NULL            THEN NULL
             WHEN e.Calificacion_Cliente <= 2   THEN N'INSATISFECHO'
             WHEN e.Calificacion_Cliente = 3    THEN N'NEUTRAL'
             ELSE N'SATISFECHO' END                                            AS Nivel_Satisfaccion,
        COALESCE(e.Demora_Imputada, 0)                      AS Demora_Imputada,
        COALESCE(e.Calificacion_Imputada, 0)                AS Calificacion_Imputada
FROM dbo.Cliente                    AS c
INNER JOIN dbo.Ciudad               AS cc ON cc.ID_Ciudad    = c.ID_Ciudad
LEFT  JOIN dbo.Pedido               AS p  ON p.ID_Cliente    = c.ID_Cliente
LEFT  JOIN dbo.Sucursal             AS s  ON s.ID_Sucursal   = p.ID_Sucursal
LEFT  JOIN dbo.Ciudad               AS cs ON cs.ID_Ciudad    = s.ID_Ciudad
LEFT  JOIN dbo.Categoria_Producto   AS ca ON ca.ID_Categoria = p.ID_Categoria
LEFT  JOIN dbo.Clima_Diario         AS cl ON cl.Fecha        = p.Fecha
                                         AND cl.ID_Ciudad    = s.ID_Ciudad      -- cruce temporal + geográfico
LEFT  JOIN dbo.Entrega              AS e  ON e.ID_Pedido     = p.ID_Pedido;
GO

/* ---------------------------------------------------------------------
   VISTA 3 · KPI CONSUMO vs CLIMA (P1)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_KPI_Consumo_por_Clima
AS
SELECT  cl.Condicion_Climatica,
        ca.Nombre_Categoria                                                   AS Categoria,
        COUNT(*)                                                              AS Num_Pedidos,
        SUM(p.Monto_Total)                                                    AS Venta_Total_MXN,
        CAST(AVG(p.Monto_Total) AS DECIMAL(10,2))                             AS Ticket_Promedio_MXN,
        CAST(AVG(cl.Temperatura_C) AS DECIMAL(4,1))                           AS Temp_Promedio_C,
        CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cl.Condicion_Climatica)
             AS DECIMAL(5,2))                                                 AS Pct_Pedidos_En_Ese_Clima
FROM dbo.Pedido                   AS p
INNER JOIN dbo.Sucursal           AS s  ON s.ID_Sucursal   = p.ID_Sucursal
INNER JOIN dbo.Categoria_Producto AS ca ON ca.ID_Categoria = p.ID_Categoria
INNER JOIN dbo.Clima_Diario       AS cl ON cl.Fecha = p.Fecha AND cl.ID_Ciudad = s.ID_Ciudad
GROUP BY cl.Condicion_Climatica, ca.Nombre_Categoria;
GO

/* ---------------------------------------------------------------------
   VISTA 4 · KPI LOGÍSTICA Y SATISFACCIÓN vs CLIMA (P2 y P3)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_KPI_Logistica_por_Clima
AS
SELECT  cl.Condicion_Climatica,
        COUNT(*)                                                              AS Num_Entregas,
        CAST(AVG(CAST(e.Minutos_Demora AS DECIMAL(10,2))) AS DECIMAL(10,2))   AS Demora_Promedio_Min,
        MAX(e.Minutos_Demora)                                                 AS Demora_Maxima_Min,
        CAST(AVG(CAST(e.Calificacion_Cliente AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS Calificacion_Promedio,
        CAST(100.0 * SUM(CASE WHEN e.Calificacion_Cliente <= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS Pct_Clientes_Insatisfechos,
        CAST(100.0 * SUM(CASE WHEN e.Minutos_Demora > 45      THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS Pct_Entregas_Tardias,
        SUM(CAST(e.Demora_Imputada AS INT) + CAST(e.Calificacion_Imputada AS INT)) AS Valores_Imputados
FROM dbo.Entrega              AS e
INNER JOIN dbo.Pedido         AS p  ON p.ID_Pedido   = e.ID_Pedido
INNER JOIN dbo.Sucursal       AS s  ON s.ID_Sucursal = p.ID_Sucursal
INNER JOIN dbo.Clima_Diario   AS cl ON cl.Fecha = p.Fecha AND cl.ID_Ciudad = s.ID_Ciudad
GROUP BY cl.Condicion_Climatica;
GO

/* ---------------------------------------------------------------------
   VISTA 5 · RESUMEN EJECUTIVO POR SUCURSAL (P4)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_KPI_Resumen_Sucursal
AS
SELECT  s.ID_Sucursal,
        s.Nombre_Sucursal,
        ci.Nombre_Ciudad                                                      AS Ciudad,
        COUNT(p.ID_Pedido)                                                    AS Num_Pedidos,
        COUNT(DISTINCT p.ID_Cliente)                                          AS Clientes_Distintos,
        SUM(p.Monto_Total)                                                    AS Venta_Total_MXN,
        CAST(AVG(p.Monto_Total) AS DECIMAL(10,2))                             AS Ticket_Promedio_MXN,
        COUNT(e.ID_Envio)                                                     AS Num_Entregas,
        CAST(100.0 * COUNT(e.ID_Envio) / NULLIF(COUNT(p.ID_Pedido), 0) AS DECIMAL(5,2)) AS Pct_Pedidos_A_Domicilio,
        CAST(AVG(CAST(e.Minutos_Demora AS DECIMAL(10,2))) AS DECIMAL(10,2))   AS Demora_Promedio_Min,
        CAST(AVG(CAST(e.Calificacion_Cliente AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS Calificacion_Promedio
FROM dbo.Sucursal           AS s
INNER JOIN dbo.Ciudad       AS ci ON ci.ID_Ciudad  = s.ID_Ciudad
LEFT  JOIN dbo.Pedido       AS p  ON p.ID_Sucursal = s.ID_Sucursal
LEFT  JOIN dbo.Entrega      AS e  ON e.ID_Pedido   = p.ID_Pedido
GROUP BY s.ID_Sucursal, s.Nombre_Sucursal, ci.Nombre_Ciudad;
GO

/* ---------- Consultas de demostración (para capturas) ---------- */
SELECT TOP (10) * FROM dbo.vw_Ventas_Operativa ORDER BY Fecha, Hora;
SELECT TOP (10) * FROM dbo.vw_Analitica_360_Cliente WHERE ID_Pedido IS NOT NULL ORDER BY Fecha_Hora;
SELECT * FROM dbo.vw_Analitica_360_Cliente WHERE ID_Pedido IS NULL;             -- clientes sin compras
SELECT * FROM dbo.vw_KPI_Consumo_por_Clima ORDER BY Condicion_Climatica, Num_Pedidos DESC;
SELECT * FROM dbo.vw_KPI_Logistica_por_Clima ORDER BY Demora_Promedio_Min DESC;
SELECT * FROM dbo.vw_KPI_Resumen_Sucursal ORDER BY Venta_Total_MXN DESC;
GO

/*
CAFECITO · CAPAS MEDALLÓN (INTERFAZ DE COMPATIBILIDAD)
Ejecutar DESPUÉS de 01-04.
Importante: el desarrollo original usa stg (crudo) y dbo (modelo limpio
y vistas). Este script agrega bronce/plata/oro como vistas de acceso,
sin mover ni duplicar físicamente los datos.
*/
USE BD_Cafecito;
GO
IF SCHEMA_ID(N'bronce') IS NULL EXEC(N'CREATE SCHEMA bronce AUTHORIZATION dbo;');
IF SCHEMA_ID(N'plata')  IS NULL EXEC(N'CREATE SCHEMA plata AUTHORIZATION dbo;');
IF SCHEMA_ID(N'oro')    IS NULL EXEC(N'CREATE SCHEMA oro AUTHORIZATION dbo;');
GO

/* BRONCE: datos crudos de staging */
CREATE OR ALTER VIEW bronce.clientes_raw AS SELECT * FROM stg.Clientes_Raw;
GO
CREATE OR ALTER VIEW bronce.ventas_raw AS SELECT * FROM stg.Ventas_Raw;
GO
CREATE OR ALTER VIEW bronce.clima_raw AS SELECT * FROM stg.Clima_Raw;
GO
CREATE OR ALTER VIEW bronce.entregas_raw AS SELECT * FROM stg.Entregas_Raw;
GO
CREATE OR ALTER VIEW bronce.clima_json_raw AS SELECT * FROM stg.Clima_JSON_Raw;
GO

/* PLATA: entidades ya estandarizadas y validadas */
CREATE OR ALTER VIEW plata.dim_cliente AS SELECT * FROM dbo.dim_cliente;
GO
CREATE OR ALTER VIEW plata.dim_ciudad AS SELECT * FROM dbo.dim_ciudad;
GO
CREATE OR ALTER VIEW plata.dim_sucursal AS SELECT * FROM dbo.dim_sucursal;
GO
CREATE OR ALTER VIEW plata.dim_categoria_producto AS SELECT * FROM dbo.dim_categoria_producto;
GO
CREATE OR ALTER VIEW plata.fact_pedido AS SELECT * FROM dbo.fact_pedido;
GO
CREATE OR ALTER VIEW plata.fact_entrega AS SELECT * FROM dbo.fact_entrega;
GO
CREATE OR ALTER VIEW plata.fact_clima_diario AS SELECT * FROM dbo.fact_clima_diario;
GO

/* ORO: vistas preparadas para consumo analítico */
CREATE OR ALTER VIEW oro.vw_ventas_operativa AS SELECT * FROM dbo.vw_ventas_operativa;
GO
CREATE OR ALTER VIEW oro.vw_analitica_360_cliente AS SELECT * FROM dbo.vw_analitica_360_cliente;
GO
CREATE OR ALTER VIEW oro.vw_kpi_consumo_por_clima AS SELECT * FROM dbo.vw_kpi_consumo_por_clima;
GO
CREATE OR ALTER VIEW oro.vw_kpi_logistica_por_clima AS SELECT * FROM dbo.vw_kpi_logistica_por_clima;
GO
CREATE OR ALTER VIEW oro.vw_kpi_resumen_sucursal AS SELECT * FROM dbo.vw_kpi_resumen_sucursal;
GO

PRINT N'Capas bronce, plata y oro disponibles como vistas de compatibilidad.';
GO

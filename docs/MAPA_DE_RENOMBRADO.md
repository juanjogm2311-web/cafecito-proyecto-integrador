# Mapa de renombrado (antes → después)

Estándar: minúsculas, `snake_case`, prefijos `dim_` (catálogos) y `fact_` (transaccionales), llaves `<entidad>_id`, sin abreviaturas. El esquema `stg` no se renombra.

## Tablas

| Antes | Después |
|---|---|
| `dbo.Ciudad` | `dbo.dim_ciudad` |
| `dbo.Sucursal` | `dbo.dim_sucursal` |
| `dbo.Categoria_Producto` | `dbo.dim_categoria_producto` |
| `dbo.Cliente` | `dbo.dim_cliente` |
| `dbo.Pedido` | `dbo.fact_pedido` |
| `dbo.Clima_Diario` | `dbo.fact_clima_diario` |
| `dbo.Entrega` | `dbo.fact_entrega` |

## Columnas

**dim_ciudad**

| Antes | Después |
|---|---|
| `ID_Ciudad` | `ciudad_id` |
| `Nombre_Ciudad` | `nombre_ciudad` |
| `Estado` | `estado` |

**dim_sucursal**

| Antes | Después |
|---|---|
| `ID_Sucursal` | `sucursal_id` |
| `Nombre_Sucursal` | `nombre_sucursal` |
| `ID_Ciudad` | `ciudad_id` |

**dim_categoria_producto**

| Antes | Después |
|---|---|
| `ID_Categoria` | `categoria_id` |
| `Nombre_Categoria` | `nombre_categoria` |
| `Temperatura_Servicio` | `temperatura_servicio` |

**dim_cliente**

| Antes | Después |
|---|---|
| `ID_Cliente` | `cliente_id` |
| `Nombre_Completo` | `nombre_completo` |
| `Email` | `email` |
| `Telefono` | `telefono` |
| `ID_Ciudad` | `ciudad_id` |
| `Fecha_Registro` | `fecha_registro` |

**fact_pedido**

| Antes | Después |
|---|---|
| `ID_Pedido` | `pedido_id` |
| `ID_Cliente` | `cliente_id` |
| `ID_Sucursal` | `sucursal_id` |
| `ID_Categoria` | `categoria_id` |
| `Fecha_Hora` | `fecha_hora` |
| `Fecha` | `fecha` |
| `Monto_Total` | `monto_total` |

**fact_clima_diario**

| Antes | Después |
|---|---|
| `ID_Clima` | `clima_id` |
| `Fecha` | `fecha` |
| `ID_Ciudad` | `ciudad_id` |
| `Temperatura_C` | `temperatura_c` |
| `Condicion_Climatica` | `condicion_climatica` |
| `Humedad_Pct` | `humedad_pct` |
| `Temperatura_Imputada` | `temperatura_imputada` |

**fact_entrega**

| Antes | Después |
|---|---|
| `ID_Envio` | `envio_id` |
| `ID_Pedido` | `pedido_id` |
| `Fecha_Entrega` | `fecha_entrega` |
| `Minutos_Demora` | `minutos_demora` |
| `Calificacion_Cliente` | `calificacion_cliente` |
| `Demora_Imputada` | `demora_imputada` |
| `Calificacion_Imputada` | `calificacion_imputada` |

## Constraints e índices

| Antes | Después |
|---|---|
| `PK_Ciudad` | `pk_dim_ciudad` |
| `PK_Sucursal` | `pk_dim_sucursal` |
| `PK_Categoria_Producto` | `pk_dim_categoria_producto` |
| `PK_Cliente` | `pk_dim_cliente` |
| `PK_Pedido` | `pk_fact_pedido` |
| `PK_Clima_Diario` | `pk_fact_clima_diario` |
| `PK_Entrega` | `pk_fact_entrega` |
| `UQ_Ciudad_Nombre` | `uq_dim_ciudad_nombre` |
| `UQ_Categoria_Nombre` | `uq_dim_categoria_producto_nombre` |
| `UQ_Cliente_Email` | `uq_dim_cliente_email` |
| `UQ_Clima_Fecha_Ciudad` | `uq_fact_clima_diario_fecha_ciudad` |
| `UQ_Entrega_Pedido` | `uq_fact_entrega_pedido` |
| `FK_Sucursal_Ciudad` | `fk_dim_sucursal_ciudad` |
| `FK_Cliente_Ciudad` | `fk_dim_cliente_ciudad` |
| `FK_Pedido_Cliente` | `fk_fact_pedido_cliente` |
| `FK_Pedido_Sucursal` | `fk_fact_pedido_sucursal` |
| `FK_Pedido_Categoria` | `fk_fact_pedido_categoria` |
| `FK_Clima_Ciudad` | `fk_fact_clima_diario_ciudad` |
| `FK_Entrega_Pedido` | `fk_fact_entrega_pedido` |
| `CK_Categoria_TempServicio` | `ck_dim_categoria_producto_temperatura` |
| `CK_Cliente_Email` | `ck_dim_cliente_email` |
| `CK_Pedido_Monto` | `ck_fact_pedido_monto` |
| `CK_Clima_Condicion` | `ck_fact_clima_diario_condicion` |
| `CK_Clima_Humedad` | `ck_fact_clima_diario_humedad` |
| `CK_Entrega_Demora` | `ck_fact_entrega_demora` |
| `CK_Entrega_Calif` | `ck_fact_entrega_calificacion` |
| `DF_Clima_TempImp` | `df_fact_clima_diario_temp_imputada` |
| `DF_Entrega_DemImp` | `df_fact_entrega_demora_imputada` |
| `DF_Entrega_CalImp` | `df_fact_entrega_calificacion_imputada` |
| `IX_Pedido_Fecha` | `ix_fact_pedido_fecha` |
| `IX_Pedido_Cliente` | `ix_fact_pedido_cliente` |

## Vistas y procedimientos

| Antes | Después |
|---|---|
| `vw_Ventas_Operativa` | `vw_ventas_operativa` |
| `vw_Analitica_360_Cliente` | `vw_analitica_360_cliente` |
| `vw_KPI_Consumo_por_Clima` | `vw_kpi_consumo_por_clima` |
| `vw_KPI_Logistica_por_Clima` | `vw_kpi_logistica_por_clima` |
| `vw_KPI_Resumen_Sucursal` | `vw_kpi_resumen_sucursal` |
| `sp_Registrar_Cliente` | `sp_registrar_cliente` |
| `sp_Consultar_Cliente` | `sp_consultar_cliente` |
| `sp_Historial_Pedidos_Cliente` | `sp_historial_pedidos_cliente` |
| (nuevo) | `sp_obtener_diccionario_datos` |

## Parámetros de los procedimientos

| Antes | Después |
|---|---|
| `@Nombre_Completo`, `@Email`, `@Telefono`, `@Ciudad`, `@ID_Generado` | `@nombre_completo`, `@email`, `@telefono`, `@ciudad`, `@cliente_id_generado` |
| `@ID_Cliente` | `@cliente_id` |
| `@FechaInicio`, `@FechaFin` | `@fecha_inicio`, `@fecha_fin` |

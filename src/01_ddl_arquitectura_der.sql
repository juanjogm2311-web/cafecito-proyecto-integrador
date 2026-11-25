/* =====================================================================
   CAFECITO · PROYECTO INTEGRADOR · EQUIPO 1 · GRUPO O3
   src/01_ddl_arquitectura_der.sql
   Base de datos, esquemas de la arquitectura Medallón (bronce, plata, oro),
   tablas, llaves PK/FK, restricciones CHECK/UNIQUE y catálogos.
   Responsable: André Campos Díaz (Arquitecto de Datos / SQL Specialist)

   Estándar: minúsculas, snake_case, prefijos dim_ / fact_, llaves <entidad>_id.
   Las tablas de bronce conservan los nombres de columna del origen (espejo de la fuente).
   ATENCIÓN: este script ELIMINA y recrea la base BD_Cafecito (instalación limpia).
   ===================================================================== */
USE master;
GO
IF DB_ID(N'BD_Cafecito') IS NOT NULL
BEGIN
    ALTER DATABASE BD_Cafecito SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Cafecito;
END
GO
CREATE DATABASE BD_Cafecito;
GO
ALTER DATABASE BD_Cafecito SET COMPATIBILITY_LEVEL = 150;  -- necesario para OPENJSON, TRIM, STRING_AGG
GO
USE BD_Cafecito;
GO
CREATE SCHEMA bronce AUTHORIZATION dbo;   -- ingesta: datos crudos tal como llegan del origen
GO
CREATE SCHEMA plata  AUTHORIZATION dbo;   -- transformación y calidad: modelo relacional limpio
GO
CREATE SCHEMA oro    AUTHORIZATION dbo;   -- consumo: vistas 360° y KPIs para BI
GO

/* ---------------------------------------------------------------------
   1) CAPA BRONCE (bronce): todo como texto, igual que llega del origen.
      ID_Carga = orden de llegada (sirve para deduplicar reintentos).
   --------------------------------------------------------------------- */
CREATE TABLE bronce.clientes_raw (
    ID_Carga        INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_clientes_raw PRIMARY KEY,
    ID_Cliente      NVARCHAR(20)  NULL,
    Nombre          NVARCHAR(150) NULL,
    Email           NVARCHAR(150) NULL,
    Telefono        NVARCHAR(30)  NULL,
    Ciudad          NVARCHAR(60)  NULL,
    Fecha_Registro  NVARCHAR(30)  NULL,
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT df_clientes_raw_fc DEFAULT SYSDATETIME()
);

-- Origen 1: BD_Ventas_Cafecito (tabla Ventas_Cafecito del e-commerce)
CREATE TABLE bronce.ventas_raw (
    ID_Carga        INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_ventas_raw PRIMARY KEY,
    ID_Pedido       NVARCHAR(20)  NULL,
    ID_Cliente      NVARCHAR(20)  NULL,
    Fecha_Hora      NVARCHAR(30)  NULL,
    ID_Sucursal     NVARCHAR(20)  NULL,
    Tipo_Producto   NVARCHAR(60)  NULL,
    Monto_Total     NVARCHAR(30)  NULL,
    Sucursal_Ciudad NVARCHAR(60)  NULL,
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT df_ventas_raw_fc DEFAULT SYSDATETIME()
);

-- Origen 2: API_Clima_Historico.json
-- (a) respuesta completa de la API tal cual llegó (para auditar tipos del JSON)
CREATE TABLE bronce.clima_json_raw (
    ID_Respuesta    INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_clima_json_raw PRIMARY KEY,
    Respuesta_JSON  NVARCHAR(MAX) NOT NULL CONSTRAINT ck_clima_json_valido CHECK (ISJSON(Respuesta_JSON) = 1),
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT df_clima_json_fc DEFAULT SYSDATETIME()
);
-- (b) respuesta "aplanada" en filas (una por fecha/ciudad)
CREATE TABLE bronce.clima_raw (
    ID_Carga            INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_clima_raw PRIMARY KEY,
    Fecha_Consulta      NVARCHAR(30) NULL,
    Ciudad              NVARCHAR(60) NULL,
    Temperatura_C       NVARCHAR(20) NULL,
    Condicion_Climatica NVARCHAR(60) NULL,
    Humedad_Pct         NVARCHAR(20) NULL,
    Fecha_Carga         DATETIME2(0) NOT NULL CONSTRAINT df_clima_raw_fc DEFAULT SYSDATETIME()
);

-- Origen 3: CSV_Entregas_ECommerce.csv
CREATE TABLE bronce.entregas_raw (
    ID_Carga             INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_entregas_raw PRIMARY KEY,
    ID_Envio             NVARCHAR(20) NULL,
    ID_Pedido            NVARCHAR(20) NULL,
    Fecha_Entrega        NVARCHAR(30) NULL,
    Minutos_Demora       NVARCHAR(20) NULL,
    Calificacion_Cliente NVARCHAR(20) NULL,
    Fecha_Carga          DATETIME2(0) NOT NULL CONSTRAINT df_entregas_raw_fc DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   2) CAPA PLATA (plata): modelo relacional limpio, 3FN
   --------------------------------------------------------------------- */
-- ===== TABLAS MAESTRAS =====
CREATE TABLE plata.dim_ciudad (
    ciudad_id     TINYINT      NOT NULL CONSTRAINT pk_dim_ciudad PRIMARY KEY,
    nombre_ciudad NVARCHAR(50) NOT NULL CONSTRAINT uq_dim_ciudad_nombre UNIQUE,
    estado        NVARCHAR(50) NOT NULL
);

CREATE TABLE plata.dim_sucursal (
    sucursal_id     VARCHAR(10)  NOT NULL CONSTRAINT pk_dim_sucursal PRIMARY KEY,
    nombre_sucursal NVARCHAR(80) NOT NULL,
    ciudad_id       TINYINT      NOT NULL
        CONSTRAINT fk_dim_sucursal_ciudad REFERENCES plata.dim_ciudad (ciudad_id)
);

CREATE TABLE plata.dim_categoria_producto (
    categoria_id         TINYINT      NOT NULL CONSTRAINT pk_dim_categoria_producto PRIMARY KEY,
    nombre_categoria     NVARCHAR(30) NOT NULL CONSTRAINT uq_dim_categoria_producto_nombre UNIQUE,
    temperatura_servicio NVARCHAR(10) NOT NULL
        CONSTRAINT ck_dim_categoria_producto_temperatura CHECK (temperatura_servicio IN (N'CALIENTE', N'FRÍA', N'N/A'))
);

CREATE TABLE plata.dim_cliente (
    cliente_id      VARCHAR(10)   NOT NULL CONSTRAINT pk_dim_cliente PRIMARY KEY,
    nombre_completo NVARCHAR(100) NOT NULL,
    email           VARCHAR(120)  NOT NULL CONSTRAINT uq_dim_cliente_email UNIQUE,
    telefono        VARCHAR(15)   NULL,
    ciudad_id       TINYINT       NOT NULL
        CONSTRAINT fk_dim_cliente_ciudad REFERENCES plata.dim_ciudad (ciudad_id),
    fecha_registro  DATE          NOT NULL,
    CONSTRAINT ck_dim_cliente_email CHECK (email LIKE '%_@_%._%')
);

-- ===== TABLAS TRANSACCIONALES =====
CREATE TABLE plata.fact_pedido (
    pedido_id    VARCHAR(10)   NOT NULL CONSTRAINT pk_fact_pedido PRIMARY KEY,
    cliente_id   VARCHAR(10)   NOT NULL
        CONSTRAINT fk_fact_pedido_cliente   REFERENCES plata.dim_cliente (cliente_id),
    sucursal_id  VARCHAR(10)   NOT NULL
        CONSTRAINT fk_fact_pedido_sucursal  REFERENCES plata.dim_sucursal (sucursal_id),
    categoria_id TINYINT       NOT NULL
        CONSTRAINT fk_fact_pedido_categoria REFERENCES plata.dim_categoria_producto (categoria_id),
    fecha_hora   DATETIME      NOT NULL,
    fecha        AS CAST(fecha_hora AS DATE) PERSISTED,   -- llave temporal para cruzar con el clima
    monto_total  DECIMAL(10,2) NOT NULL CONSTRAINT ck_fact_pedido_monto CHECK (monto_total >= 0)
);
CREATE INDEX ix_fact_pedido_fecha   ON plata.fact_pedido (fecha);
CREATE INDEX ix_fact_pedido_cliente ON plata.fact_pedido (cliente_id, fecha_hora);

CREATE TABLE plata.fact_clima_diario (
    clima_id             INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_fact_clima_diario PRIMARY KEY,
    fecha                DATE         NOT NULL,
    ciudad_id            TINYINT      NOT NULL
        CONSTRAINT fk_fact_clima_diario_ciudad REFERENCES plata.dim_ciudad (ciudad_id),
    temperatura_c        DECIMAL(4,1) NOT NULL,
    condicion_climatica  NVARCHAR(30) NOT NULL
        CONSTRAINT ck_fact_clima_diario_condicion CHECK (condicion_climatica IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO')),
    humedad_pct          TINYINT      NULL
        CONSTRAINT ck_fact_clima_diario_humedad CHECK (humedad_pct BETWEEN 0 AND 100),
    temperatura_imputada BIT          NOT NULL CONSTRAINT df_fact_clima_diario_temp_imputada DEFAULT (0),
    CONSTRAINT uq_fact_clima_diario_fecha_ciudad UNIQUE (fecha, ciudad_id)
);

CREATE TABLE plata.fact_entrega (
    envio_id              VARCHAR(10) NOT NULL CONSTRAINT pk_fact_entrega PRIMARY KEY,
    pedido_id             VARCHAR(10) NOT NULL,
    fecha_entrega         DATE        NOT NULL,
    minutos_demora        INT         NOT NULL CONSTRAINT ck_fact_entrega_demora CHECK (minutos_demora >= 0),
    calificacion_cliente  TINYINT     NOT NULL CONSTRAINT ck_fact_entrega_calificacion  CHECK (calificacion_cliente BETWEEN 1 AND 5),
    demora_imputada       BIT         NOT NULL CONSTRAINT df_fact_entrega_demora_imputada DEFAULT (0),
    calificacion_imputada BIT         NOT NULL CONSTRAINT df_fact_entrega_calificacion_imputada DEFAULT (0),
    CONSTRAINT uq_fact_entrega_pedido UNIQUE (pedido_id),                                  -- relación 1:1
    CONSTRAINT fk_fact_entrega_pedido FOREIGN KEY (pedido_id) REFERENCES plata.fact_pedido (pedido_id)
);
GO

-- ===== CONTROL DE CALIDAD DEL PIPELINE =====
-- Registros que NO pasan las reglas de integridad (cuarentena)
CREATE TABLE plata.registros_rechazados (
    rechazo_id     INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_registros_rechazados PRIMARY KEY,
    origen         NVARCHAR(30)  NOT NULL,
    llave_registro NVARCHAR(30)  NOT NULL,
    motivo         NVARCHAR(200) NOT NULL,
    fecha_rechazo  DATETIME2(0)  NOT NULL CONSTRAINT df_registros_rechazados_fecha DEFAULT SYSDATETIME()
);
-- Bitácora: evidencia de cada paso de limpieza
CREATE TABLE plata.bitacora_limpieza (
    paso_id   INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_bitacora_limpieza PRIMARY KEY,
    fase      NVARCHAR(30)  NOT NULL,
    tabla     NVARCHAR(40)  NOT NULL,
    accion    NVARCHAR(200) NOT NULL,
    registros INT           NOT NULL,
    fecha     DATETIME2(0)  NOT NULL CONSTRAINT df_bitacora_limpieza_fecha DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   3) CATÁLOGOS (datos de referencia ya limpios)
   --------------------------------------------------------------------- */
INSERT INTO plata.dim_ciudad (ciudad_id, nombre_ciudad, estado) VALUES
    (1, N'LEÓN',       N'GUANAJUATO'),
    (2, N'SILAO',      N'GUANAJUATO'),
    (3, N'GUANAJUATO', N'GUANAJUATO');

INSERT INTO plata.dim_sucursal (sucursal_id, nombre_sucursal, ciudad_id) VALUES
    ('SUC-01', N'CAFECITO CENTRO LEÓN',     1),
    ('SUC-02', N'CAFECITO CAMPESTRE LEÓN',  1),
    ('SUC-03', N'CAFECITO SILAO',           2),
    ('SUC-04', N'CAFECITO GUANAJUATO CENTRO', 3);

INSERT INTO plata.dim_categoria_producto (categoria_id, nombre_categoria, temperatura_servicio) VALUES
    (1, N'BEBIDA CALIENTE', N'CALIENTE'),
    (2, N'BEBIDA FRÍA',     N'FRÍA'),
    (3, N'REPOSTERÍA',      N'N/A');

-- Cliente genérico para pedidos que llegan sin cliente (se usa con COALESCE en la Fase 4)
INSERT INTO plata.dim_cliente (cliente_id, nombre_completo, email, telefono, ciudad_id, fecha_registro) VALUES
    ('CLI-000', N'CLIENTE NO IDENTIFICADO', 'sin.correo@cafecito.mx', NULL, 1, '20250101');
GO

PRINT 'BD_Cafecito creada: esquemas bronce, plata y oro; tablas, llaves y catálogos listos.';
GO

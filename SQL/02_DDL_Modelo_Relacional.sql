/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 02 · DDL: tablas de staging + modelo relacional + catálogos
   Responsable: André Campos Díaz (Data Architect / SQL Specialist)
   ===================================================================== */
USE BD_Cafecito;
GO

/* ---------------------------------------------------------------------
   1) CAPA STAGING (stg): todo como texto, igual que llega del origen.
      ID_Carga = orden de llegada (sirve para deduplicar reintentos).
   --------------------------------------------------------------------- */
CREATE TABLE stg.Clientes_Raw (
    ID_Carga        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clientes_Raw PRIMARY KEY,
    ID_Cliente      NVARCHAR(20)  NULL,
    Nombre          NVARCHAR(150) NULL,
    Email           NVARCHAR(150) NULL,
    Telefono        NVARCHAR(30)  NULL,
    Ciudad          NVARCHAR(60)  NULL,
    Fecha_Registro  NVARCHAR(30)  NULL,
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT DF_Clientes_Raw_FC DEFAULT SYSDATETIME()
);

-- Origen 1: BD_Ventas_Cafecito (tabla Ventas_Cafecito del e-commerce)
CREATE TABLE stg.Ventas_Raw (
    ID_Carga        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ventas_Raw PRIMARY KEY,
    ID_Pedido       NVARCHAR(20)  NULL,
    ID_Cliente      NVARCHAR(20)  NULL,
    Fecha_Hora      NVARCHAR(30)  NULL,
    ID_Sucursal     NVARCHAR(20)  NULL,
    Tipo_Producto   NVARCHAR(60)  NULL,
    Monto_Total     NVARCHAR(30)  NULL,
    Sucursal_Ciudad NVARCHAR(60)  NULL,
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT DF_Ventas_Raw_FC DEFAULT SYSDATETIME()
);

-- Origen 2: API_Clima_Historico.json
-- (a) respuesta completa de la API tal cual llegó (para auditar tipos del JSON)
CREATE TABLE stg.Clima_JSON_Raw (
    ID_Respuesta    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clima_JSON_Raw PRIMARY KEY,
    Respuesta_JSON  NVARCHAR(MAX) NOT NULL CONSTRAINT CK_Clima_JSON_Valido CHECK (ISJSON(Respuesta_JSON) = 1),
    Fecha_Carga     DATETIME2(0)  NOT NULL CONSTRAINT DF_Clima_JSON_FC DEFAULT SYSDATETIME()
);
-- (b) respuesta "aplanada" en filas (una por fecha/ciudad)
CREATE TABLE stg.Clima_Raw (
    ID_Carga            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clima_Raw PRIMARY KEY,
    Fecha_Consulta      NVARCHAR(30) NULL,
    Ciudad              NVARCHAR(60) NULL,
    Temperatura_C       NVARCHAR(20) NULL,
    Condicion_Climatica NVARCHAR(60) NULL,
    Humedad_Pct         NVARCHAR(20) NULL,
    Fecha_Carga         DATETIME2(0) NOT NULL CONSTRAINT DF_Clima_Raw_FC DEFAULT SYSDATETIME()
);

-- Origen 3: CSV_Entregas_ECommerce.csv
CREATE TABLE stg.Entregas_Raw (
    ID_Carga             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Entregas_Raw PRIMARY KEY,
    ID_Envio             NVARCHAR(20) NULL,
    ID_Pedido            NVARCHAR(20) NULL,
    Fecha_Entrega        NVARCHAR(30) NULL,
    Minutos_Demora       NVARCHAR(20) NULL,
    Calificacion_Cliente NVARCHAR(20) NULL,
    Fecha_Carga          DATETIME2(0) NOT NULL CONSTRAINT DF_Entregas_Raw_FC DEFAULT SYSDATETIME()
);

-- Bitácora de registros que NO pasan las reglas de integridad
CREATE TABLE stg.Registros_Rechazados (
    ID_Rechazo     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Registros_Rechazados PRIMARY KEY,
    Origen         NVARCHAR(30)  NOT NULL,
    Llave_Registro NVARCHAR(30)  NOT NULL,
    Motivo         NVARCHAR(200) NOT NULL,
    Fecha_Rechazo  DATETIME2(0)  NOT NULL CONSTRAINT DF_Rechazos_FR DEFAULT SYSDATETIME()
);
GO

/* ---------------------------------------------------------------------
   2) MODELO RELACIONAL (dbo)
   --------------------------------------------------------------------- */
-- ===== TABLAS MAESTRAS =====
CREATE TABLE dbo.Ciudad (
    ID_Ciudad     TINYINT      NOT NULL CONSTRAINT PK_Ciudad PRIMARY KEY,
    Nombre_Ciudad NVARCHAR(50) NOT NULL CONSTRAINT UQ_Ciudad_Nombre UNIQUE,
    Estado        NVARCHAR(50) NOT NULL
);

CREATE TABLE dbo.Sucursal (
    ID_Sucursal     VARCHAR(10)  NOT NULL CONSTRAINT PK_Sucursal PRIMARY KEY,
    Nombre_Sucursal NVARCHAR(80) NOT NULL,
    ID_Ciudad       TINYINT      NOT NULL
        CONSTRAINT FK_Sucursal_Ciudad REFERENCES dbo.Ciudad (ID_Ciudad)
);

CREATE TABLE dbo.Categoria_Producto (
    ID_Categoria         TINYINT      NOT NULL CONSTRAINT PK_Categoria_Producto PRIMARY KEY,
    Nombre_Categoria     NVARCHAR(30) NOT NULL CONSTRAINT UQ_Categoria_Nombre UNIQUE,
    Temperatura_Servicio NVARCHAR(10) NOT NULL
        CONSTRAINT CK_Categoria_TempServicio CHECK (Temperatura_Servicio IN (N'CALIENTE', N'FRÍA', N'N/A'))
);

CREATE TABLE dbo.Cliente (
    ID_Cliente      VARCHAR(10)   NOT NULL CONSTRAINT PK_Cliente PRIMARY KEY,
    Nombre_Completo NVARCHAR(100) NOT NULL,
    Email           VARCHAR(120)  NOT NULL CONSTRAINT UQ_Cliente_Email UNIQUE,
    Telefono        VARCHAR(15)   NULL,
    ID_Ciudad       TINYINT       NOT NULL
        CONSTRAINT FK_Cliente_Ciudad REFERENCES dbo.Ciudad (ID_Ciudad),
    Fecha_Registro  DATE          NOT NULL,
    CONSTRAINT CK_Cliente_Email CHECK (Email LIKE '%_@_%._%')
);

-- ===== TABLAS TRANSACCIONALES =====
CREATE TABLE dbo.Pedido (
    ID_Pedido    VARCHAR(10)   NOT NULL CONSTRAINT PK_Pedido PRIMARY KEY,
    ID_Cliente   VARCHAR(10)   NOT NULL
        CONSTRAINT FK_Pedido_Cliente   REFERENCES dbo.Cliente (ID_Cliente),
    ID_Sucursal  VARCHAR(10)   NOT NULL
        CONSTRAINT FK_Pedido_Sucursal  REFERENCES dbo.Sucursal (ID_Sucursal),
    ID_Categoria TINYINT       NOT NULL
        CONSTRAINT FK_Pedido_Categoria REFERENCES dbo.Categoria_Producto (ID_Categoria),
    Fecha_Hora   DATETIME      NOT NULL,
    Fecha        AS CAST(Fecha_Hora AS DATE) PERSISTED,   -- llave temporal para cruzar con el clima
    Monto_Total  DECIMAL(10,2) NOT NULL CONSTRAINT CK_Pedido_Monto CHECK (Monto_Total >= 0)
);
CREATE INDEX IX_Pedido_Fecha   ON dbo.Pedido (Fecha);
CREATE INDEX IX_Pedido_Cliente ON dbo.Pedido (ID_Cliente, Fecha_Hora);

CREATE TABLE dbo.Clima_Diario (
    ID_Clima             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clima_Diario PRIMARY KEY,
    Fecha                DATE         NOT NULL,
    ID_Ciudad            TINYINT      NOT NULL
        CONSTRAINT FK_Clima_Ciudad REFERENCES dbo.Ciudad (ID_Ciudad),
    Temperatura_C        DECIMAL(4,1) NOT NULL,
    Condicion_Climatica  NVARCHAR(30) NOT NULL
        CONSTRAINT CK_Clima_Condicion CHECK (Condicion_Climatica IN (N'LLUVIA INTENSA', N'CALUROSO', N'NUBLADO', N'TEMPLADO')),
    Humedad_Pct          TINYINT      NULL
        CONSTRAINT CK_Clima_Humedad CHECK (Humedad_Pct BETWEEN 0 AND 100),
    Temperatura_Imputada BIT          NOT NULL CONSTRAINT DF_Clima_TempImp DEFAULT (0),
    CONSTRAINT UQ_Clima_Fecha_Ciudad UNIQUE (Fecha, ID_Ciudad)
);

CREATE TABLE dbo.Entrega (
    ID_Envio              VARCHAR(10) NOT NULL CONSTRAINT PK_Entrega PRIMARY KEY,
    ID_Pedido             VARCHAR(10) NOT NULL,
    Fecha_Entrega         DATE        NOT NULL,
    Minutos_Demora        INT         NOT NULL CONSTRAINT CK_Entrega_Demora CHECK (Minutos_Demora >= 0),
    Calificacion_Cliente  TINYINT     NOT NULL CONSTRAINT CK_Entrega_Calif  CHECK (Calificacion_Cliente BETWEEN 1 AND 5),
    Demora_Imputada       BIT         NOT NULL CONSTRAINT DF_Entrega_DemImp DEFAULT (0),
    Calificacion_Imputada BIT         NOT NULL CONSTRAINT DF_Entrega_CalImp DEFAULT (0),
    CONSTRAINT UQ_Entrega_Pedido UNIQUE (ID_Pedido),                                  -- relación 1:1
    CONSTRAINT FK_Entrega_Pedido FOREIGN KEY (ID_Pedido) REFERENCES dbo.Pedido (ID_Pedido)
);
GO

/* ---------------------------------------------------------------------
   3) CATÁLOGOS (datos de referencia ya limpios)
   --------------------------------------------------------------------- */
INSERT INTO dbo.Ciudad (ID_Ciudad, Nombre_Ciudad, Estado) VALUES
    (1, N'LEÓN',       N'GUANAJUATO'),
    (2, N'SILAO',      N'GUANAJUATO'),
    (3, N'GUANAJUATO', N'GUANAJUATO');

INSERT INTO dbo.Sucursal (ID_Sucursal, Nombre_Sucursal, ID_Ciudad) VALUES
    ('SUC-01', N'CAFECITO CENTRO LEÓN',     1),
    ('SUC-02', N'CAFECITO CAMPESTRE LEÓN',  1),
    ('SUC-03', N'CAFECITO SILAO',           2),
    ('SUC-04', N'CAFECITO GUANAJUATO CENTRO', 3);

INSERT INTO dbo.Categoria_Producto (ID_Categoria, Nombre_Categoria, Temperatura_Servicio) VALUES
    (1, N'BEBIDA CALIENTE', N'CALIENTE'),
    (2, N'BEBIDA FRÍA',     N'FRÍA'),
    (3, N'REPOSTERÍA',      N'N/A');

-- Cliente genérico para pedidos que llegan sin cliente (se usa con COALESCE en la Fase 4)
INSERT INTO dbo.Cliente (ID_Cliente, Nombre_Completo, Email, Telefono, ID_Ciudad, Fecha_Registro) VALUES
    ('CLI-000', N'CLIENTE NO IDENTIFICADO', 'sin.correo@cafecito.mx', NULL, 1, '20250101');
GO

PRINT 'Tablas, llaves y catálogos creados correctamente.';
GO

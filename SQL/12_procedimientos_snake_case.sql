/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1 - GRUPO O3
   Script 12 · PROCEDIMIENTOS ALMACENADOS con nomenclatura estándar (reemplaza al 07)
   Responsable: André Campos Díaz (Data Architect / SQL Specialist)
   Misma lógica que el script 07. Cambian nombres de objetos, columnas y parámetros:
     @Nombre_Completo -> @nombre_completo   @ID_Generado -> @cliente_id_generado
     @ID_Cliente -> @cliente_id             @FechaInicio/@FechaFin -> @fecha_inicio/@fecha_fin
   Prerrequisito: script 10.
   ===================================================================== */
USE BD_Cafecito;
GO

/* SP 1 · INSERCIÓN CONTROLADA CON VALIDACIÓN */
CREATE OR ALTER PROCEDURE dbo.sp_registrar_cliente
    @nombre_completo     NVARCHAR(100),
    @email               VARCHAR(120),
    @telefono            VARCHAR(15)  = NULL,
    @ciudad              NVARCHAR(50),
    @cliente_id_generado VARCHAR(10)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Limpieza previa de cadenas
    DECLARE @nombre_limpio NVARCHAR(100) = UPPER(TRIM(@nombre_completo)),
            @email_limpio  VARCHAR(120)  = LOWER(TRIM(@email)),
            @tel_limpio    VARCHAR(15)   = NULLIF(TRIM(@telefono), ''),
            @ciudad_id     TINYINT;

    SELECT @ciudad_id = ciudad_id
    FROM dbo.dim_ciudad
    WHERE nombre_ciudad COLLATE Latin1_General_CI_AI = TRIM(@ciudad) COLLATE Latin1_General_CI_AI;

    BEGIN TRY
        -- 2) Validaciones
        IF @nombre_limpio IS NULL OR @nombre_limpio = N''
            RAISERROR('El nombre del cliente es obligatorio.', 16, 1);

        IF @email_limpio IS NULL OR @email_limpio NOT LIKE '%_@_%._%'
            RAISERROR('El email "%s" no tiene un formato válido.', 16, 1, @email_limpio);

        IF @ciudad_id IS NULL
            RAISERROR('La ciudad indicada no existe en el catálogo (LEÓN, SILAO, GUANAJUATO).', 16, 1);

        IF EXISTS (SELECT 1 FROM dbo.dim_cliente WHERE email = @email_limpio)
            RAISERROR('Ya existe un cliente registrado con el email "%s". No se insertó el duplicado.', 16, 1, @email_limpio);

        -- 3) Inserción
        BEGIN TRANSACTION;

            SELECT @cliente_id_generado = 'CLI-' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(cliente_id, 5, 6) AS INT)), 0) + 1 AS VARCHAR(6)), 3)
            FROM dbo.dim_cliente WITH (UPDLOCK, HOLDLOCK);

            INSERT INTO dbo.dim_cliente (cliente_id, nombre_completo, email, telefono, ciudad_id, fecha_registro)
            VALUES (@cliente_id_generado, @nombre_limpio, @email_limpio, @tel_limpio, @ciudad_id, CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;

        SELECT N'Cliente registrado correctamente' AS resultado, @cliente_id_generado AS cliente_id,
               @nombre_limpio AS nombre, @email_limpio AS email;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- re-lanza el error original al usuario
    END CATCH
END;
GO

/* SP 2 · CONSULTA BÁSICA DE ENTIDAD POR ID (acepta espacios y minúsculas) */
CREATE OR ALTER PROCEDURE dbo.sp_consultar_cliente
    @cliente_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id VARCHAR(10) = UPPER(TRIM(@cliente_id));

    IF NOT EXISTS (SELECT 1 FROM dbo.dim_cliente WHERE cliente_id = @id)
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
    FROM dbo.dim_cliente      AS c
    INNER JOIN dbo.dim_ciudad AS ci ON ci.ciudad_id = c.ciudad_id
    LEFT JOIN (SELECT cliente_id, COUNT(*) AS num_pedidos, SUM(monto_total) AS total_comprado, MAX(fecha) AS ultima_compra
               FROM dbo.fact_pedido GROUP BY cliente_id) AS r
           ON r.cliente_id = c.cliente_id
    WHERE c.cliente_id = @id;
END;
GO

/* SP 3 · HISTORIAL DE PEDIDOS DE UN CLIENTE */
CREATE OR ALTER PROCEDURE dbo.sp_historial_pedidos_cliente
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

    IF NOT EXISTS (SELECT 1 FROM dbo.dim_cliente WHERE cliente_id = @id)
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
    FROM dbo.dim_cliente                AS c
    INNER JOIN dbo.fact_pedido          AS p  ON p.cliente_id    = c.cliente_id
    INNER JOIN dbo.dim_categoria_producto AS ca ON ca.categoria_id = p.categoria_id
    INNER JOIN dbo.dim_sucursal         AS s  ON s.sucursal_id   = p.sucursal_id
    LEFT  JOIN dbo.fact_clima_diario    AS cl ON cl.fecha = p.fecha AND cl.ciudad_id = s.ciudad_id
    LEFT  JOIN dbo.fact_entrega         AS e  ON e.pedido_id     = p.pedido_id
    WHERE c.cliente_id = @id
      AND p.fecha BETWEEN @fecha_inicio AND @fecha_fin
    ORDER BY p.fecha_hora;
END;
GO

PRINT 'Procedimientos almacenados creados. Las pruebas están en el script 14.';
GO

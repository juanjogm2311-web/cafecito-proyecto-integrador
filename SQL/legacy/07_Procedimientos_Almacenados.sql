/* =====================================================================
   PROYECTO INTEGRADOR - EQUIPO 1
   Script 07 · PROCEDIMIENTOS ALMACENADOS
   Responsable: André Campos Díaz (Data Architect / SQL Specialist)
   ===================================================================== */
USE BD_Cafecito;
GO

/* ---------------------------------------------------------------------
   SP 1 · INSERCIÓN CONTROLADA CON VALIDACIÓN
   - Limpia los parámetros (TRIM, UPPER para nombre, LOWER para email).
   - Valida obligatorios, formato de email, ciudad existente.
   - Evita duplicados con IF EXISTS (por email) + RAISERROR.
   - Genera el siguiente ID (CLI-041, CLI-042, ...).
   - TRY...CATCH con transacción: si algo falla, no se guarda nada.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_Registrar_Cliente
    @Nombre_Completo NVARCHAR(100),
    @Email           VARCHAR(120),
    @Telefono        VARCHAR(15)  = NULL,
    @Ciudad          NVARCHAR(50),
    @ID_Generado     VARCHAR(10)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Limpieza previa de cadenas
    DECLARE @Nombre_Limpio NVARCHAR(100) = UPPER(TRIM(@Nombre_Completo)),
            @Email_Limpio  VARCHAR(120)  = LOWER(TRIM(@Email)),
            @Tel_Limpio    VARCHAR(15)   = NULLIF(TRIM(@Telefono), ''),
            @ID_Ciudad     TINYINT;

    SELECT @ID_Ciudad = ID_Ciudad
    FROM dbo.Ciudad
    WHERE Nombre_Ciudad COLLATE Latin1_General_CI_AI = TRIM(@Ciudad) COLLATE Latin1_General_CI_AI;

    BEGIN TRY
        -- 2) Validaciones
        IF @Nombre_Limpio IS NULL OR @Nombre_Limpio = N''
            RAISERROR('El nombre del cliente es obligatorio.', 16, 1);

        IF @Email_Limpio IS NULL OR @Email_Limpio NOT LIKE '%_@_%._%'
            RAISERROR('El email "%s" no tiene un formato válido.', 16, 1, @Email_Limpio);

        IF @ID_Ciudad IS NULL
            RAISERROR('La ciudad indicada no existe en el catálogo (LEÓN, SILAO, GUANAJUATO).', 16, 1);

        IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE Email = @Email_Limpio)
            RAISERROR('Ya existe un cliente registrado con el email "%s". No se insertó el duplicado.', 16, 1, @Email_Limpio);

        -- 3) Inserción
        BEGIN TRANSACTION;

            SELECT @ID_Generado = 'CLI-' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(ID_Cliente, 5, 6) AS INT)), 0) + 1 AS VARCHAR(6)), 3)
            FROM dbo.Cliente WITH (UPDLOCK, HOLDLOCK);

            INSERT INTO dbo.Cliente (ID_Cliente, Nombre_Completo, Email, Telefono, ID_Ciudad, Fecha_Registro)
            VALUES (@ID_Generado, @Nombre_Limpio, @Email_Limpio, @Tel_Limpio, @ID_Ciudad, CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;

        SELECT N'Cliente registrado correctamente' AS Resultado, @ID_Generado AS ID_Cliente,
               @Nombre_Limpio AS Nombre, @Email_Limpio AS Email;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- re-lanza el error original al usuario
    END CATCH
END;
GO

/* ---------------------------------------------------------------------
   SP 2 · CONSULTA BÁSICA DE ENTIDAD POR ID
   - Acepta el ID con espacios o minúsculas (' cli-001 ').
   - Devuelve datos estandarizados y valores por defecto (ISNULL/COALESCE).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_Consultar_Cliente
    @ID_Cliente VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ID VARCHAR(10) = UPPER(TRIM(@ID_Cliente));

    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ID_Cliente = @ID)
    BEGIN
        RAISERROR('No existe un cliente con ID %s.', 16, 1, @ID);
        RETURN;
    END

    SELECT  c.ID_Cliente,
            UPPER(TRIM(c.Nombre_Completo))                 AS Nombre_Completo,
            LOWER(TRIM(c.Email))                           AS Email,
            ISNULL(c.Telefono, 'SIN TELÉFONO')             AS Telefono,
            ci.Nombre_Ciudad                               AS Ciudad,
            c.Fecha_Registro,
            COALESCE(r.Num_Pedidos, 0)                     AS Num_Pedidos,
            COALESCE(r.Total_Comprado, 0)                  AS Total_Comprado_MXN,
            COALESCE(CONVERT(VARCHAR(10), r.Ultima_Compra, 23), 'SIN COMPRAS') AS Ultima_Compra
    FROM dbo.Cliente     AS c
    INNER JOIN dbo.Ciudad AS ci ON ci.ID_Ciudad = c.ID_Ciudad
    LEFT JOIN (SELECT ID_Cliente, COUNT(*) AS Num_Pedidos, SUM(Monto_Total) AS Total_Comprado, MAX(Fecha) AS Ultima_Compra
               FROM dbo.Pedido GROUP BY ID_Cliente) AS r
           ON r.ID_Cliente = c.ID_Cliente
    WHERE c.ID_Cliente = @ID;
END;
GO

/* ---------------------------------------------------------------------
   SP 3 · HISTORIAL DE PEDIDOS POR CLIENTE Y RANGO DE FECHAS
   - INNER JOIN maestra (Cliente) <-> transaccional (Pedido).
   - Se enriquece con categoría, sucursal, clima y entrega.
   - Si no se mandan fechas, toma todo el historial.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_Historial_Pedidos_Cliente
    @ID_Cliente  VARCHAR(10),
    @FechaInicio DATE = NULL,
    @FechaFin    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ID VARCHAR(10) = UPPER(TRIM(@ID_Cliente));
    SET @FechaInicio = ISNULL(@FechaInicio, '19000101');
    SET @FechaFin    = ISNULL(@FechaFin,    '99991231');

    IF @FechaInicio > @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor que la fecha fin.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ID_Cliente = @ID)
    BEGIN
        RAISERROR('No existe un cliente con ID %s.', 16, 1, @ID);
        RETURN;
    END

    SELECT  c.ID_Cliente,
            c.Nombre_Completo,
            p.ID_Pedido,
            p.Fecha_Hora,
            ca.Nombre_Categoria                              AS Categoria,
            s.Nombre_Sucursal,
            p.Monto_Total,
            ISNULL(cl.Condicion_Climatica, N'SIN DATO')      AS Clima_Del_Dia,
            cl.Temperatura_C,
            COALESCE(e.ID_Envio, N'RECOGIÓ EN SUCURSAL')     AS ID_Envio,   -- COALESCE (ISNULL recortaría el texto a VARCHAR(10))
            e.Minutos_Demora,
            e.Calificacion_Cliente
    FROM dbo.Cliente                    AS c
    INNER JOIN dbo.Pedido               AS p  ON p.ID_Cliente    = c.ID_Cliente
    INNER JOIN dbo.Categoria_Producto   AS ca ON ca.ID_Categoria = p.ID_Categoria
    INNER JOIN dbo.Sucursal             AS s  ON s.ID_Sucursal   = p.ID_Sucursal
    LEFT  JOIN dbo.Clima_Diario         AS cl ON cl.Fecha = p.Fecha AND cl.ID_Ciudad = s.ID_Ciudad
    LEFT  JOIN dbo.Entrega              AS e  ON e.ID_Pedido     = p.ID_Pedido
    WHERE c.ID_Cliente = @ID
      AND p.Fecha BETWEEN @FechaInicio AND @FechaFin
    ORDER BY p.Fecha_Hora;
END;
GO

PRINT 'Procedimientos almacenados creados. Las pruebas están en el script 08.';
GO

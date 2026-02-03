
/* ============================================================================
   SP: procUpdateTransaccionesCompra
   - Devuelve INT: TransaccionCompraId
   - No truena si no existe otra tabla
============================================================================ */
CREATE   PROCEDURE dbo.procUpdateTransaccionesCompra
    @CompraId      INT,
    @UsuarioId     INT = 0,        -- puedes mandar este...
    @loginId       INT = 0,        -- ...o este (por compatibilidad)
    @Descripcion   NVARCHAR(300) = NULL,
    @InventarioId  INT = NULL,
    @Cantidad      DECIMAL(18,4) = 0,
    @CostoUnitario DECIMAL(18,4) = 0,
    @CostoTotal    DECIMAL(18,4) = 0,
    @FechaCreacion DATE = NULL,

    @Crear         BIT = 0,
    @Actualizar    BIT = 0,
    @Borrar        BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid INT = CASE WHEN ISNULL(@UsuarioId,0) > 0 THEN @UsuarioId ELSE ISNULL(@loginId,0) END;
    IF (@uid <= 0)
    BEGIN
        RAISERROR('UsuarioId/loginId requerido.', 16, 1);
        RETURN;
    END

    IF (@CompraId IS NULL OR @CompraId <= 0)
    BEGIN
        RAISERROR('CompraId inválido.', 16, 1);
        RETURN;
    END

    IF (@FechaCreacion IS NULL)
        SET @FechaCreacion = CAST(GETDATE() AS DATE);

    DECLARE @op VARCHAR(20) =
        CASE
            WHEN ISNULL(@Borrar,0) = 1 THEN 'BORRAR'
            WHEN ISNULL(@Actualizar,0) = 1 THEN 'ACTUALIZAR'
            ELSE 'CREAR'
        END;

    INSERT INTO dbo.TblTransaccionesCompras
    (
        CompraId, UsuarioId, Operacion, Descripcion, InventarioId,
        Cantidad, CostoUnitario, CostoTotal, FechaCompra
    )
    VALUES
    (
        @CompraId, @uid, @op, @Descripcion, @InventarioId,
        ISNULL(@Cantidad,0), ISNULL(@CostoUnitario,0), ISNULL(@CostoTotal,0), @FechaCreacion
    );

    -- IMPORTANTE: tu C# hace QuerySingleAsync<int>, así que regresamos int pelón:
    SELECT CAST(SCOPE_IDENTITY() AS INT);
END
GO


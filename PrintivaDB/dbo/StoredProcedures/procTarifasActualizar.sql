
/* =========================================================
   9) SP: ACTUALIZAR TARIFA (por TarifaId)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasActualizar
    @TarifaId INT,
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @Nombre NVARCHAR(80) = NULL,
    @Orden INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SET @Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN');

        DECLARE @chg TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            OrdenDespues INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET
            Monto = @Monto,
            Moneda = @Moneda,
            Nombre = COALESCE(@Nombre, t.Nombre),
            Orden  = COALESCE(@Orden, t.Orden),
            FechaActualizacion = GETUTCDATE()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            inserted.Nombre,
            deleted.Orden,
            inserted.Orden,
            deleted.Monto,
            deleted.Moneda,
            inserted.Monto,
            inserted.Moneda,
            deleted.EstaActivo,
            inserted.EstaActivo
        INTO @chg
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @chg)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            'UPDATE',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @chg;

        SELECT 'success' AS result, 'Tarifa actualizada.' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


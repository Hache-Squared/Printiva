

/* =========================================================
   6) SP: ELIMINACIÓN LÓGICA + LOG
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasEliminar
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @del TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenDespues INT NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET EstaActivo = 0,
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            deleted.Orden,
            deleted.Monto,
            deleted.Moneda,
            deleted.EstaActivo,
            inserted.Nombre,
            inserted.Orden,
            inserted.Monto,
            inserted.Moneda,
            inserted.EstaActivo
        INTO @del
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @del)
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
            'DELETE_LOGICO',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @del;

        SELECT 'success' AS result, 'Tarifa eliminada (lógica).' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


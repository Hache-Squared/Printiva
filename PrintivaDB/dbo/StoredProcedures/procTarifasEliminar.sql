

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
            InventarioTipoId INT NULL,
            InventarioNombreId INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
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
            inserted.InventarioTipoId,
            inserted.InventarioNombreId,
            deleted.Monto,
            deleted.Moneda,
            inserted.Monto,
            inserted.Moneda,
            deleted.EstaActivo,
            inserted.EstaActivo
        INTO @del
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.UsuarioId = @loginId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @del)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa o no pertenece al usuario.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            Accion, MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            'DELETE_LOGICO', MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
        FROM @del;

        SELECT 'success' AS result, 'Tarifa eliminada (lógica).' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


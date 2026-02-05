CREATE   PROCEDURE dbo.procDesactivarReceta
    @loginId   INT = 0,
    @RecetaId  INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result     VARCHAR(100) = '';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@RecetaId,0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM dbo.TblRecetas r (NOLOCK) WHERE r.RecetaId = @elementoId)
            RAISERROR('Receta no encontrada.', 16, 1);

        BEGIN TRAN;

        UPDATE dbo.TblRecetasInventarios
        SET EstaActivo = 0
        WHERE RecetaId = @elementoId;

        UPDATE dbo.TblRecetas
        SET EstaActivo = 0
        WHERE RecetaId = @elementoId;

        COMMIT;

        SET @result = 'success';
        SET @message = 'Receta desactivada';

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


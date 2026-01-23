CREATE OR ALTER PROCEDURE dbo.procProduccionCambiarEstatusItem
    @ProduccionItemId INT,
    @HaciaEstatusId INT,
    @Notas NVARCHAR(500) = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = 'Estatus actualizado.';
    DECLARE @elementoId INT = @ProduccionItemId;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.TblProduccionItems pr (NOLOCK) WHERE pr.ProduccionItemId=@ProduccionItemId AND pr.UsuarioId=@loginId AND pr.EstaActivo=1)
            THROW 50000, 'Item de producción no encontrado.', 1;

        DECLARE @DesdeId INT = (SELECT ProduccionEstatusId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

        IF NOT EXISTS (
            SELECT 1 FROM dbo.TblProduccionEstatusTransiciones (NOLOCK)
            WHERE DesdeEstatusId=@DesdeId AND HaciaEstatusId=@HaciaEstatusId
        )
            THROW 50000, 'Transición no permitida.', 1;

        DECLARE @PedidoId INT = (SELECT PedidoId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);
        DECLARE @PedidoItemId INT = (SELECT PedidoItemId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

        UPDATE dbo.TblProduccionItems
        SET ProduccionEstatusId = @HaciaEstatusId,
            Notas = NULLIF(@Notas,''),
            FechaActualizacion = GETDATE()
        WHERE ProduccionItemId = @ProduccionItemId;

        INSERT INTO dbo.TblProduccionBitacora
        (ProduccionItemId, PedidoId, PedidoItemId, UsuarioId, DesdeEstatusId, HaciaEstatusId, Notas)
        VALUES
        (@ProduccionItemId, @PedidoId, @PedidoItemId, @loginId, @DesdeId, @HaciaEstatusId, NULLIF(@Notas,''));

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

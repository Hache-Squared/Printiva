
CREATE OR ALTER PROCEDURE dbo.procPedidoCambiarEstatus
@PedidoId INT = 0,
@HaciaEstatusId INT = 0,
@Notas VARCHAR(500) = '',
@loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId)
        BEGIN
            SET @message = 'Pedido no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus e (NOLOCK) WHERE e.PedidoEstatusId = @HaciaEstatusId)
        BEGIN
            SET @message = 'Estatus destino no existe.';
            RAISERROR(@message, 16, 1);
        END

        DECLARE @DesdeEstatusId INT = (SELECT p.PedidoEstatusId FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId);

        IF(@DesdeEstatusId = @HaciaEstatusId)
        BEGIN
            SET @message = 'El pedido ya se encuentra en ese estatus.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblPedidosEstatusTransiciones t (NOLOCK)
            WHERE t.DesdeEstatusId = @DesdeEstatusId
            AND t.HaciaEstatusId = @HaciaEstatusId
        )
        BEGIN
            SET @message = 'Transición no permitida.';
            RAISERROR(@message, 16, 1);
        END

        DECLARE @AprobadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Aprobado');

        IF(@HaciaEstatusId = @AprobadoId)
        BEGIN
            DECLARE @CotizacionAceptadaId INT = (SELECT TOP 1 CotizacionEstatusId FROM dbo.TblCotizacionesEstatus (NOLOCK) WHERE Nombre='Aceptada');

            IF(@CotizacionAceptadaId IS NULL)
            BEGIN
                SET @message = 'No existe el estatus Aceptada en cotizaciones.';
                RAISERROR(@message, 16, 1);
            END

            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblCotizaciones c (NOLOCK)
                WHERE c.PedidoId = @PedidoId
                AND c.CotizacionEstatusId = @CotizacionAceptadaId
                AND ISNULL(c.EstaActivo,1) = 1
            )
            BEGIN
                SET @message = 'Para aprobar se requiere una cotización en estatus Aceptada.';
                RAISERROR(@message, 16, 1);
            END
        END

        DECLARE @EnProduccionPedidoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre=N'En producción');

        IF @EnProduccionPedidoId IS NOT NULL AND @HaciaEstatusId = @EnProduccionPedidoId
        BEGIN
            EXEC dbo.procProduccionInitPorPedido @PedidoId=@PedidoId, @loginId=@loginId;
        END

        UPDATE p
            SET p.PedidoEstatusId = @HaciaEstatusId
        FROM dbo.TblPedidos p
        WHERE p.PedidoId = @PedidoId;

        INSERT INTO dbo.TblPedidosBitacora(PedidoId, UsuarioId, DesdeEstatusId, HaciaEstatusId, Notas)
        VALUES(@PedidoId, @loginId, @DesdeEstatusId, @HaciaEstatusId, NULLIF(@Notas,''));

        SET @result = 'success';
        SET @message = 'Estatus actualizado';
        SET @elementoId = @PedidoId;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF(ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
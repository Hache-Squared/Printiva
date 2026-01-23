
CREATE OR ALTER PROCEDURE dbo.procPedidoAccionesDisponibles
@PedidoId INT = 0,
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

        DECLARE @DesdeEstatusId INT = (SELECT p.PedidoEstatusId FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId);

        DECLARE @AprobadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Aprobado');
        DECLARE @CanceladoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Cancelado');
        DECLARE @EntregadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Entregado');

        DECLARE @CotizacionAceptadaId INT = (SELECT TOP 1 CotizacionEstatusId FROM dbo.TblCotizacionesEstatus (NOLOCK) WHERE Nombre='Aceptada');

        DECLARE @TieneCotizacionAceptada BIT = 0;

        IF(@CotizacionAceptadaId IS NOT NULL)
        BEGIN
            IF EXISTS(
                SELECT 1
                FROM dbo.TblCotizaciones c (NOLOCK)
                WHERE c.PedidoId = @PedidoId
                AND c.CotizacionEstatusId = @CotizacionAceptadaId
                AND ISNULL(c.EstaActivo,1) = 1
            )
            SET @TieneCotizacionAceptada = 1;
        END

        SELECT
            'mover' AS AccionCodigo,
            CONCAT('Mover a: ', eh.Nombre) AS AccionTexto,
            t.HaciaEstatusId,
            CAST(CASE WHEN t.HaciaEstatusId IN (@CanceladoId, @EntregadoId) THEN 1 ELSE 0 END AS BIT) AS RequiereConfirmacion,
            CAST(
                CASE
                    WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 1
                    ELSE 0
                END
            AS BIT) AS Bloqueada,
            CASE
                WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 'Requiere una cotización en estatus Aceptada.'
                ELSE ''
            END AS Motivo
        FROM dbo.TblPedidosEstatusTransiciones t (NOLOCK)
        INNER JOIN dbo.TblPedidoEstatus eh (NOLOCK)
            ON t.HaciaEstatusId = eh.PedidoEstatusId
        WHERE t.DesdeEstatusId = @DesdeEstatusId
        ORDER BY eh.PedidoEstatusId ASC;

    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF(ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END

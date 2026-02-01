
CREATE   PROCEDURE dbo.procPedidoAccionesDisponibles
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

        DECLARE @OrdPost INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Post-proceso' AND EstaActivo=1);
        DECLARE @OrdListo INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Listo para entrega' AND EstaActivo=1);
        DECLARE @OrdEnt INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Entregado' AND EstaActivo=1);

        DECLARE @MinOrd INT =
        (
            SELECT MIN(pe.Orden)
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK) ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
            WHERE pr.PedidoId=@PedidoId AND pr.EstaActivo=1
        );

        /* Si no hay items de producción, bloqueamos avanzar a etapas finales */
        DECLARE @PuedePost BIT = IIF(@MinOrd IS NOT NULL AND @OrdPost IS NOT NULL AND @MinOrd >= @OrdPost, 1, 0);
        DECLARE @PuedeListo BIT = IIF(@MinOrd IS NOT NULL AND @OrdListo IS NOT NULL AND @MinOrd >= @OrdListo, 1, 0);
        DECLARE @PuedeEnt BIT = IIF(@MinOrd IS NOT NULL AND @OrdEnt IS NOT NULL AND @MinOrd >= @OrdEnt, 1, 0);
        DECLARE @PostProcesoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'Post-proceso');
        DECLARE @ListoEntregaId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'Listo para entrega');
        -- opcional, por si luego lo usas
        DECLARE @EnProduccionId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'En producción');

        SELECT
            'mover' AS AccionCodigo,
            CONCAT('Mover a: ', eh.Nombre) AS AccionTexto,
            t.HaciaEstatusId,
            CAST(CASE WHEN t.HaciaEstatusId IN (@CanceladoId, @EntregadoId) THEN 1 ELSE 0 END AS BIT) AS RequiereConfirmacion,
            CAST(
                CASE
                    WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 1
                    WHEN @PostProcesoId IS NOT NULL AND t.HaciaEstatusId = @PostProcesoId AND @PuedePost = 0 THEN 1
                    WHEN @ListoEntregaId IS NOT NULL AND t.HaciaEstatusId = @ListoEntregaId AND @PuedeListo = 0 THEN 1
                    WHEN t.HaciaEstatusId = @EntregadoId AND @PuedeEnt = 0 THEN 1
                    ELSE 0
                END
            AS BIT) AS Bloqueada,
            CASE
                WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 'Requiere una cotización en estatus Aceptada.'
                WHEN @PostProcesoId IS NOT NULL AND t.HaciaEstatusId = @PostProcesoId AND @PuedePost = 0 THEN 'Aún hay items que no están en Post-proceso (Producción).'
                WHEN @ListoEntregaId IS NOT NULL AND t.HaciaEstatusId = @ListoEntregaId AND @PuedeListo = 0 THEN 'Aún hay items que no están Listos para entrega (Producción).'
                WHEN t.HaciaEstatusId = @EntregadoId AND @PuedeEnt = 0 THEN 'Aún hay items que no están Entregados (Producción).'
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
GO


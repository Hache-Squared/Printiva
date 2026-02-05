CREATE   PROCEDURE dbo.procPedidoOcultarEnKanban
    @loginId  INT = 0,
    @PedidoId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result     VARCHAR(100) = '';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@PedidoId,0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblPedidos p (NOLOCK)
            WHERE p.PedidoId = @elementoId
              AND p.UsuarioId = @loginId
              AND p.EstaActivo = 1
        )
            RAISERROR('Pedido no encontrado.', 16, 1);

        DECLARE @EntregadoId INT = (
            SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus WITH (NOLOCK) WHERE Nombre = 'Entregado'
        );
        DECLARE @CanceladoId INT = (
            SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus WITH (NOLOCK) WHERE Nombre = 'Cancelado'
        );

        IF EXISTS (
            SELECT 1
            FROM dbo.TblPedidos p (NOLOCK)
            WHERE p.PedidoId = @elementoId
              AND p.PedidoEstatusId NOT IN (ISNULL(@EntregadoId,-1), ISNULL(@CanceladoId,-1))
        )
            RAISERROR('Solo puedes ocultar pedidos Entregados o Cancelados.', 16, 1);

        UPDATE dbo.TblPedidos
        SET MostrarEnKanban = 0
        WHERE PedidoId = @elementoId;

        SET @result = 'success';
        SET @message = 'Pedido ocultado del kanban';

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


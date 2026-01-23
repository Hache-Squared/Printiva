CREATE OR ALTER PROCEDURE dbo.procReemplazarPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
        RETURN;

    DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
END
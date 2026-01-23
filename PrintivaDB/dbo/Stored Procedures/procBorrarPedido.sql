CREATE OR ALTER PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
        DELETE FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
    END
END
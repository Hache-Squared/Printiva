CREATE OR ALTER PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        UPDATE dbo.TblPedidoItems
            SET EstaActivo = 0 
        WHERE PedidoId = @pedidoId;

        UPDATE dbo.TblPedidos 
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
    END
END
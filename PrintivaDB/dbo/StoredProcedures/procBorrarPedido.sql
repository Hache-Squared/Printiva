CREATE   PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId)
    BEGIN
        UPDATE dbo.TblPedidoItems
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId;

        UPDATE dbo.TblPedidos
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId;
    END
END
GO


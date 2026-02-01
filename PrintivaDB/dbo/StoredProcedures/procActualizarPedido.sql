CREATE OR ALTER PROCEDURE dbo.procActualizarPedido
    @loginId INT,
    @pedidoId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TblPedidos
    SET ClienteId = @clienteId,
        PedidoEstatusId = @pedidoEstatusId,
        FechaEntregaEstimada = @fechaEntregaEstimada,
        Notas = @notas,
        TotalEstimado = @totalEstimado
    WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
END
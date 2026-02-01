CREATE   PROCEDURE dbo.procCrearPedido
    @loginId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TblPedidos (UsuarioId, ClienteId, PedidoEstatusId, FechaEntregaEstimada, Notas, TotalEstimado)
    VALUES (@loginId, @clienteId, @pedidoEstatusId, @fechaEntregaEstimada, @notas, @totalEstimado);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS PedidoId;
END
GO


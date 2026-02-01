CREATE   PROCEDURE dbo.procObtenerPedidos
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PedidoId,
        p.UsuarioId,
        p.ClienteId,
        c.Nombre AS ClienteNombre,
        p.PedidoEstatusId,
        e.Nombre AS EstatusNombre,
        p.FechaCreacion,
        p.FechaEntregaEstimada,
        p.Notas,
        p.TotalEstimado
    FROM dbo.TblPedidos p
    INNER JOIN dbo.TblClientes c ON c.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus e ON e.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR p.PedidoId = @elementoObtenerId)
      AND p.EstaActivo = 1 
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO


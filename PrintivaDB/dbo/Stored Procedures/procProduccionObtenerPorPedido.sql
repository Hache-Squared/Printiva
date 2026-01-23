CREATE OR ALTER PROCEDURE dbo.procProduccionObtenerPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND p.UsuarioId=@loginId)
    BEGIN
        SELECT TOP 0 0 AS ProduccionItemId;
        RETURN;
    END

    SELECT
        pr.ProduccionItemId,
        pr.PedidoId,
        pr.PedidoItemId,
        pr.ProductoId,
        prod.Nombre AS ProductoNombre,
        pr.Cantidad,
        pr.ProduccionEstatusId,
        pe.Nombre AS EstatusNombre,
        pe.BadgeClass,
        pr.Notas,
        pr.FechaCreacion,
        pr.FechaActualizacion
    FROM dbo.TblProduccionItems pr (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK) ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
    INNER JOIN dbo.TblProductos prod (NOLOCK) ON prod.ProductoId = pr.ProductoId
    WHERE pr.PedidoId = @PedidoId
      AND pr.UsuarioId = @loginId
      AND pr.EstaActivo = 1
    ORDER BY pe.Orden ASC, pr.ProduccionItemId ASC;
END
GO

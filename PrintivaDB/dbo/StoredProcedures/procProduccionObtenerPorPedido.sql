CREATE   PROCEDURE dbo.procProduccionObtenerPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        RAISERROR('Usuario no encontrado.', 16, 1);

    IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND p.UsuarioId=@loginId)
        RAISERROR('Pedido no encontrado.', 16, 1);

    SELECT
        pr.ProduccionItemId,
        pr.PedidoId,
        pr.PedidoItemId,
        pr.ProductoId,
        p.Nombre AS ProductoNombre,
        pi.Cantidad,

        pr.ProduccionEstatusId,
        pe.Nombre AS EstatusNombre,
        pe.BadgeClass,

        pr.Notas,
        pr.FechaCreacion,
        pr.FechaActualizacion,

        pr.ImpresoraId,
        imp.Nombre AS ImpresoraNombre,
        pr.NotasOperativas,
        pr.PesoEstimadoGr,
        pr.PesoRealGr,
        pr.FechaInicio,
        pr.FechaFin,
        pr.InventarioAplicado
    FROM dbo.TblProduccionItems pr (NOLOCK)
    INNER JOIN dbo.TblPedidoItems pi (NOLOCK)
        ON pi.PedidoItemId = pr.PedidoItemId
    INNER JOIN dbo.TblProductos p (NOLOCK)
        ON p.ProductoId = pr.ProductoId
    INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK)
        ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
    LEFT JOIN dbo.TblImpresoras imp (NOLOCK)
        ON imp.ImpresoraId = pr.ImpresoraId
       AND imp.UsuarioId = @loginId  -- seguridad
    WHERE pr.PedidoId = @PedidoId
      AND ISNULL(pr.EstaActivo,1) = 1
    ORDER BY pe.Orden ASC, pr.ProduccionItemId ASC;
END
GO


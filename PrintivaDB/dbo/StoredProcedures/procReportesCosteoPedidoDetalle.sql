CREATE   PROCEDURE dbo.procReportesCosteoPedidoDetalle
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WITH (NOLOCK) WHERE PedidoId=@PedidoId AND UsuarioId=@loginId)
    BEGIN
        SELECT TOP 0 0 AS InventarioId, '' AS InsumoNombre, '' AS UnidadNombre, 0 AS Cantidad, 0 AS CostoUnitario, 0 AS CostoTotal;
        RETURN;
    END

    SELECT
        c.InventarioId,
        MAX(c.InsumoNombre) AS InsumoNombre,
        MAX(c.UnidadNombre) AS UnidadNombre,
        SUM(c.Cantidad) AS Cantidad,

        MAX(ISNULL(inv.CostoUnitario,0)) AS CostoUnitario,
        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoTotal
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    WHERE c.PedidoId = @PedidoId
    GROUP BY c.InventarioId
    ORDER BY SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) DESC;
END
GO


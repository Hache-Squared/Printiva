CREATE OR ALTER PROCEDURE dbo.procObtenerPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        SELECT TOP 0
            null as PedidoItemId,
            null as PedidoId,
            null as ProductoId,
            CAST(NULL AS NVARCHAR(200)) AS ProductoNombre,
            null as Cantidad,
            null as PrecioUnitarioEstimado,
            null as Notas;
        RETURN;
    END

    SELECT
        i.PedidoItemId,
        i.PedidoId,
        i.ProductoId,
        p.Nombre AS ProductoNombre,
        i.Cantidad,
        i.PrecioUnitarioEstimado,
        i.Notas
    FROM dbo.TblPedidoItems i
    INNER JOIN dbo.TblProductos p ON p.ProductoId = i.ProductoId
    WHERE i.PedidoId = @pedidoId
    AND i.EstaActivo = 1 
    ORDER BY i.PedidoItemId;
END
CREATE   PROCEDURE dbo.procReportesProduccionDashboard
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Items por estatus de producción (del usuario dueño)
    SELECT
        e.ProduccionEstatusId,
        e.Nombre,
        e.Orden,
        COUNT(*) AS Items
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus e WITH (NOLOCK)
        ON e.ProduccionEstatusId = i.ProduccionEstatusId
    WHERE i.UsuarioId = @loginId
      AND i.EstaActivo = 1
    GROUP BY e.ProduccionEstatusId, e.Nombre, e.Orden
    ORDER BY e.Orden;

    -- Pedidos por estatus (del usuario dueño)
    SELECT
        pe.PedidoEstatusId,
        pe.Nombre,
        COUNT(*) AS Pedidos
    FROM dbo.TblPedidos p WITH (NOLOCK)
    INNER JOIN dbo.TblPedidoEstatus pe WITH (NOLOCK)
        ON pe.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.UsuarioId = @loginId
      AND ISNULL(p.EstaActivo,1)=1
    GROUP BY pe.PedidoEstatusId, pe.Nombre
    ORDER BY pe.PedidoEstatusId;

    -- WIP: items no entregados (toma el id de “Entregado” en producción)
    DECLARE @EntregadoProdId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus WITH (NOLOCK)
        WHERE EstaActivo=1 AND Nombre LIKE N'Entreg%'
        ORDER BY Orden DESC
    );

    SELECT
        COUNT(*) AS ItemsTotales,
        SUM(CASE WHEN @EntregadoProdId IS NOT NULL AND i.ProduccionEstatusId <> @EntregadoProdId THEN 1 ELSE 0 END) AS ItemsWIP
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    WHERE i.UsuarioId=@loginId AND i.EstaActivo=1;
END
GO


CREATE   PROCEDURE dbo.procReportesCosteoPedidos
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -30, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    SELECT
        p.PedidoId,
        CONCAT( ISNULL(cli.Nombre, ''), ' ', ISNULL(cli.ApellidoPaterno, ''), ' ', ISNULL(cli.ApellidoMaterno, '')) AS ClienteNombre,
        p.TotalEstimado,

        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoReal,
        (ISNULL(p.TotalEstimado,0) - SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0))) AS Diferencia,

        MIN(c.Fecha) AS PrimerConsumo,
        MAX(c.Fecha) AS UltimoConsumo
    FROM dbo.TblPedidos p WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        ON c.PedidoId = p.PedidoId
       AND c.Fecha >= @DesdeDT
       AND c.Fecha <  @HastaDT
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    LEFT JOIN dbo.TblClientes cli 
        ON cli.ClienteId = p.ClienteId
    WHERE ISNULL(p.EstaActivo,1)=1
      AND (@PedidoId IS NULL OR p.PedidoId=@PedidoId)
    GROUP BY p.PedidoId, cli.Nombre, cli.ApellidoPaterno, cli.ApellidoMaterno, p.TotalEstimado
    ORDER BY p.PedidoId DESC;
END
GO


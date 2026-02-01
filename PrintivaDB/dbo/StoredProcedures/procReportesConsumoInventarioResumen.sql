CREATE   PROCEDURE dbo.procReportesConsumoInventarioResumen
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @InventarioId INT = NULL,
    @UsuarioId INT = NULL,
    @ProductoId INT = NULL,
    @RecetaId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT
        COUNT(*) AS Movimientos,
        COUNT(DISTINCT PedidoId) AS Pedidos,
        COUNT(DISTINCT InventarioId) AS Insumos,
        SUM(Cantidad) AS TotalConsumido
    FROM Base;

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT TOP 10
        InventarioId,
        MAX(InsumoNombre) AS InsumoNombre,
        MAX(UnidadNombre) AS UnidadNombre,
        SUM(Cantidad) AS Consumido,
        COUNT(*) AS Movimientos
    FROM Base
    GROUP BY InventarioId
    ORDER BY SUM(Cantidad) DESC;
END
GO


CREATE   PROCEDURE dbo.procReportesConsumoInventarioDetalle
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

    -- defaults: últimos 7 días
    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2)); -- inclusive día completo

    SELECT
        c.Fecha,
        c.PedidoId,
        c.PedidoItemId,
        c.ProduccionItemId,
        c.UsuarioId,

        c.ProductoId,
        c.CantidadItem,

        c.RecetaId,
        c.RecetaNombre,

        c.InventarioId,
        c.InsumoNombre,
        c.UnidadNombre,

        c.Cantidad,
        c.DisponibleAntes,
        c.DisponibleDespues,

        c.DesdeEstatusId,
        de.Nombre AS DesdeEstatusNombre,
        c.HaciaEstatusId,
        he.Nombre AS HaciaEstatusNombre,

        c.Notas
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionEstatus de WITH (NOLOCK) ON de.ProduccionEstatusId = c.DesdeEstatusId
    LEFT JOIN dbo.TblProduccionEstatus he WITH (NOLOCK) ON he.ProduccionEstatusId = c.HaciaEstatusId
    WHERE c.Fecha >= @DesdeDT
      AND c.Fecha <  @HastaDT
      AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
      AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
      AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
      AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
      AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    ORDER BY c.Fecha DESC, c.ProduccionInventarioConsumoId DESC;
END
GO


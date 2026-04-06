CREATE OR ALTER PROCEDURE dbo.procObtenerCotizaciones
@ElementoObtenerId INT = 0,
@PedidoId INT = 0,
@loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @elementoId INT = ISNULL(@ElementoObtenerId, 0);

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Usuarios u WITH (NOLOCK)
        WHERE u.Id = @loginId
    )
    BEGIN
        RAISERROR('Usuario no encontrado.', 16, 1);
        RETURN;
    END

    CREATE TABLE #TempData
    (
        CotizacionId INT,
        PedidoId INT,
        CotizacionEstatusId INT,
        CotizacionEstatus VARCHAR(100),
        FechaCreacion DATETIME,
        FechaVigencia DATETIME,
        Notas VARCHAR(MAX),
        TotalModelado DECIMAL(18,2),
        TotalProduccion DECIMAL(18,2),
        TotalCotizado DECIMAL(18,2),
        TotalPagado DECIMAL(18,2),
        Saldo DECIMAL(18,2)
    );

    INSERT INTO #TempData
    (
        CotizacionId,
        PedidoId,
        CotizacionEstatusId,
        CotizacionEstatus,
        FechaCreacion,
        FechaVigencia,
        Notas,
        TotalModelado,
        TotalProduccion,
        TotalCotizado,
        TotalPagado,
        Saldo
    )
    SELECT
        c.CotizacionId,
        c.PedidoId,
        c.CotizacionEstatusId,
        ce.Nombre,
        c.FechaCreacion,
        c.FechaVigencia,
        c.Notas,
        ISNULL(sums.TotalModelado, 0),
        ISNULL(sums.TotalProduccion, 0),
        ISNULL(sums.TotalGeneral, 0),
        ISNULL(pagos.TotalPagado, 0),
        CAST(ISNULL(sums.TotalGeneral, 0) - ISNULL(pagos.TotalPagado, 0) AS DECIMAL(18,2))
    FROM dbo.TblCotizaciones c WITH (NOLOCK)
    INNER JOIN dbo.TblCotizacionesEstatus ce WITH (NOLOCK)
        ON c.CotizacionEstatusId = ce.CotizacionEstatusId
    OUTER APPLY
    (
        SELECT
            CAST(ISNULL(SUM(CASE WHEN i.ConceptoTipoId = 1 THEN ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0) ELSE 0 END), 0) AS DECIMAL(18,2)) AS TotalModelado,
            CAST(ISNULL(SUM(CASE WHEN i.ConceptoTipoId = 2 THEN ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0) ELSE 0 END), 0) AS DECIMAL(18,2)) AS TotalProduccion,
            CAST(ISNULL(SUM(ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0)), 0) AS DECIMAL(18,2)) AS SubtotalCotizado,
            CAST(ROUND(ISNULL(SUM(ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0)), 0) * 0.16, 2) AS DECIMAL(18,2)) AS IvaCotizado,
            CAST(
                ISNULL(SUM(ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0)), 0)
                + ROUND(ISNULL(SUM(ISNULL(i.Cantidad, 0) * ISNULL(i.PrecioUnitario, 0)), 0) * 0.16, 2)
                AS DECIMAL(18,2)
            ) AS TotalGeneral
        FROM dbo.TblCotizacionItems i WITH (NOLOCK)
        WHERE i.CotizacionId = c.CotizacionId
          AND i.EstaActivo = 1
    ) sums
    OUTER APPLY
    (
        SELECT CAST(ISNULL(SUM(p.Monto), 0) AS DECIMAL(18,2)) AS TotalPagado
        FROM dbo.TblPagos p WITH (NOLOCK)
        WHERE p.CotizacionId = c.CotizacionId
          AND p.EstaActivo = 1
    ) pagos
    WHERE c.EstaActivo = 1
      AND (@PedidoId = 0 OR c.PedidoId = @PedidoId);

    IF (@elementoId = 0)
    BEGIN
        SELECT *
        FROM #TempData
        ORDER BY CotizacionId DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #TempData
        WHERE CotizacionId = @elementoId;
    END

    DROP TABLE IF EXISTS #TempData;
END
GO
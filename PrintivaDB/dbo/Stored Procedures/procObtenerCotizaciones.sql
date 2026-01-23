CREATE OR ALTER PROCEDURE dbo.procObtenerCotizaciones
@ElementoObtenerId INT = 0,
@PedidoId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @elementoId INT = ISNULL(@ElementoObtenerId,0);

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	CREATE TABLE #TempData(
		CotizacionId INT,
		PedidoId INT,
		CotizacionEstatusId INT,
		CotizacionEstatus VARCHAR(100),
		FechaCreacion DATETIME,
		FechaVigencia DATETIME,
		Notas VARCHAR(MAX),
		TotalModelado DECIMAL(10,2),
		TotalProduccion DECIMAL(10,2),
		TotalCotizado DECIMAL(10,2),
		TotalPagado DECIMAL(10,2),
		Saldo DECIMAL(10,2)
	);

	INSERT INTO #TempData(
		CotizacionId, PedidoId, CotizacionEstatusId, CotizacionEstatus,
		FechaCreacion, FechaVigencia, Notas,
		TotalModelado, TotalProduccion, TotalCotizado, TotalPagado, Saldo
	)
	SELECT
		c.CotizacionId,
		c.PedidoId,
		c.CotizacionEstatusId,
		ce.Nombre,
		c.FechaCreacion,
		c.FechaVigencia,
		c.Notas,
		ISNULL(sums.TotalModelado,0),
		ISNULL(sums.TotalProduccion,0),
		ISNULL(sums.TotalCotizado,0),
		ISNULL(pagos.TotalPagado,0),
		ISNULL(sums.TotalCotizado,0) - ISNULL(pagos.TotalPagado,0)
	FROM dbo.TblCotizaciones c (NOLOCK)
	INNER JOIN dbo.TblCotizacionesEstatus ce (NOLOCK)
		ON c.CotizacionEstatusId = ce.CotizacionEstatusId
	OUTER APPLY (
		SELECT
			SUM(CASE WHEN i.ConceptoTipoId = 1 THEN i.Cantidad * i.PrecioUnitario ELSE 0 END) AS TotalModelado,
			SUM(CASE WHEN i.ConceptoTipoId = 2 THEN i.Cantidad * i.PrecioUnitario ELSE 0 END) AS TotalProduccion,
			SUM(i.Cantidad * i.PrecioUnitario) AS TotalCotizado
		FROM dbo.TblCotizacionItems i (NOLOCK)
		WHERE i.CotizacionId = c.CotizacionId
		AND i.EstaActivo = 1
	) sums
	OUTER APPLY (
		SELECT SUM(p.Monto) AS TotalPagado
		FROM dbo.TblPagos p (NOLOCK)
		WHERE p.CotizacionId = c.CotizacionId
		AND p.EstaActivo = 1
	) pagos
	WHERE c.EstaActivo = 1
	AND (@PedidoId = 0 OR c.PedidoId = @PedidoId);

	IF(@elementoId = 0)
	BEGIN
		SELECT * FROM #TempData ORDER BY CotizacionId DESC;
	END
	ELSE
	BEGIN
		SELECT * FROM #TempData WHERE CotizacionId = @elementoId;
	END

	DROP TABLE IF EXISTS #TempData;
END
GO

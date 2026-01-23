CREATE OR ALTER PROCEDURE dbo.procObtenerPagos
@CotizacionId INT = 0,
@ElementoObtenerId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @elementoId INT = ISNULL(@ElementoObtenerId,0);

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
	BEGIN
		RAISERROR('Cotizacion no encontrada.',16,1);
	END

	IF(@elementoId = 0)
	BEGIN
		SELECT
			p.PagoId,
			p.CotizacionId,
			p.PagoTipoId,
			pt.Nombre AS PagoTipo,
			p.Monto,
			p.FechaPago,
			p.Metodo,
			p.Referencia,
			p.Notas
		FROM dbo.TblPagos p (NOLOCK)
		INNER JOIN dbo.TblPagoTipos pt (NOLOCK)
			ON p.PagoTipoId = pt.PagoTipoId
		WHERE p.CotizacionId = @CotizacionId
		AND p.EstaActivo = 1
		ORDER BY p.FechaPago DESC, p.PagoId DESC;
	END
	ELSE
	BEGIN
		SELECT
			p.PagoId,
			p.CotizacionId,
			p.PagoTipoId,
			pt.Nombre AS PagoTipo,
			p.Monto,
			p.FechaPago,
			p.Metodo,
			p.Referencia,
			p.Notas
		FROM dbo.TblPagos p (NOLOCK)
		INNER JOIN dbo.TblPagoTipos pt (NOLOCK)
			ON p.PagoTipoId = pt.PagoTipoId
		WHERE p.PagoId = @elementoId
		AND p.CotizacionId = @CotizacionId
		AND p.EstaActivo = 1;
	END
END
GO

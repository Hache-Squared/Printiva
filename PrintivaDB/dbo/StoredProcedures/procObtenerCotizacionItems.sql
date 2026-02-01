CREATE OR ALTER PROCEDURE dbo.procObtenerCotizacionItems
@CotizacionId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
	BEGIN
		RAISERROR('Cotizacion no encontrada.',16,1);
	END

	SELECT
		i.CotizacionItemId,
		i.CotizacionId,
		i.ConceptoTipoId,
		ct.Nombre AS ConceptoTipo,
		i.ProductoId,
		p.Nombre AS ProductoNombre,
		i.Concepto,
		i.Cantidad,
		i.PrecioUnitario,
		i.Notas
	FROM dbo.TblCotizacionItems i (NOLOCK)
	INNER JOIN dbo.TblCotizacionConceptoTipos ct (NOLOCK)
		ON i.ConceptoTipoId = ct.ConceptoTipoId
	LEFT JOIN dbo.TblProductos p (NOLOCK)
		ON i.ProductoId = p.ProductoId
	WHERE i.CotizacionId = @CotizacionId
	AND i.EstaActivo = 1
	ORDER BY i.CotizacionItemId ASC;
END
GO

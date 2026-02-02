
/* =========================================================
   7) SP: OBTENER TARIFAS POR IMPRESORA (UI sección Impresoras)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerPorImpresora
    @ImpresoraId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,
        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,
        t.ImpresoraId,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
      AND t.ImpresoraId = @ImpresoraId
    ORDER BY c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO


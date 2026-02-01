

/* =========================================================
   3) SP: LISTAR TARIFAS ACTIVAS DEL USUARIO
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerPorUsuario
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,
        t.ImpresoraId,
        t.InventarioTipoId,
        t.InventarioNombreId,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
    ORDER BY c.Orden ASC, c.Nombre ASC, t.TarifaId DESC;
END
GO


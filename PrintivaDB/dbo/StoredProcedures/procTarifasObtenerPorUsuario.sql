

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
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,

        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,

        t.ImpresoraId,
        t.InventarioId,

        t.InventarioTipoId,
        t.InventarioNombreId,

        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.EstaActivo = 1
    ORDER BY
        c.Orden ASC,
        t.ImpresoraId ASC,
        t.InventarioId ASC,
        t.Orden ASC,
        t.TarifaId DESC;
END
GO


CREATE   PROCEDURE dbo.procTarifasObtenerPorInventario
    @InventarioId INT,
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
        t.InventarioId,
        t.ImpresoraId, -- 👈 agrega para poder detectar globales en UI
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio,
        CAST(CASE WHEN t.InventarioId IS NULL AND t.ImpresoraId IS NULL THEN 1 ELSE 0 END AS BIT) AS EsGlobal
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
      AND c.EstaActivo = 1
      AND (
            -- específicas del inventario
            (t.InventarioId = @InventarioId AND t.ImpresoraId IS NULL)

            -- globales de inventarios
            OR (t.InventarioId IS NULL AND t.ImpresoraId IS NULL AND c.Codigo = 'MATERIAL_GENERAL_INV_GLOBAL')
      )
    ORDER BY
        EsGlobal DESC,
        c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO


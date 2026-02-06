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
        t.ImpresoraId,
        invNom.Nombre AS InventarioNombre,
        prn.Nombre AS ImpresoraNombre,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio,
        CAST(CASE WHEN t.InventarioId IS NULL AND t.ImpresoraId IS NULL THEN 1 ELSE 0 END AS BIT) AS EsGlobal
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId

    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = t.InventarioId
    LEFT JOIN dbo.TblInventariosNombres invNom
        ON invNom.InventarioNombreId = inv.InventarioNombreId

    LEFT JOIN dbo.TblImpresoras prn WITH (NOLOCK)
        ON prn.ImpresoraId = t.ImpresoraId

    WHERE t.EstaActivo = 1
      AND c.EstaActivo = 1
      AND (
            (t.InventarioId = @InventarioId AND t.ImpresoraId IS NULL)
            OR (t.InventarioId IS NULL AND t.ImpresoraId IS NULL AND c.Codigo = 'MATERIAL_GENERAL_INV_GLOBAL')
      )
    ORDER BY
        EsGlobal DESC,
        c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO


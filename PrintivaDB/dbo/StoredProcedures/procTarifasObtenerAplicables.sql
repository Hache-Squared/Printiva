
/* =========================================================
   13) SP: OBTENER TARIFAS APLICABLES (para cálculo + desglose)
   - Regresa TODAS las tarifas activas que aplican al scope pedido
   - Si mandas InventarioId, traerá:
        (InventarioId exacto) + (globales InventarioId NULL)
     Si mandas ImpresoraId, traerá:
        (ImpresoraId exacto) + (globales ImpresoraId NULL)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerAplicables
    @TarifaConceptoCodigo VARCHAR(40),
    @ImpresoraId INT = NULL,
    @InventarioId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TarifaConceptoId INT;

    SELECT @TarifaConceptoId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

    IF @TarifaConceptoId IS NULL
    BEGIN
        SELECT 'error' AS result, 'Concepto de tarifa inválido o inactivo.' AS message;
        RETURN;
    END

    SELECT
        'success' AS result,
        'OK' AS message,
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,
        t.ImpresoraId,
        t.InventarioId,
        t.Monto,
        t.Moneda
    FROM dbo.TblTarifas t WITH (NOLOCK)
    WHERE t.TarifaConceptoId = @TarifaConceptoId
      AND t.EstaActivo = 1
      AND (
            (@InventarioId IS NOT NULL AND (t.InventarioId = @InventarioId OR t.InventarioId IS NULL) AND t.ImpresoraId IS NULL)
            OR
            (@ImpresoraId IS NOT NULL AND (t.ImpresoraId = @ImpresoraId OR t.ImpresoraId IS NULL) AND t.InventarioId IS NULL)
            OR
            (@InventarioId IS NULL AND @ImpresoraId IS NULL AND t.InventarioId IS NULL AND t.ImpresoraId IS NULL)
      )
    ORDER BY
        CASE WHEN @InventarioId IS NOT NULL AND t.InventarioId = @InventarioId THEN 2
             WHEN @ImpresoraId IS NOT NULL AND t.ImpresoraId = @ImpresoraId THEN 2
             ELSE 1 END DESC,
        t.Orden ASC,
        t.TarifaId DESC;
END
GO


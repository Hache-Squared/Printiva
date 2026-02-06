

/* =========================================================
   5) SP: OBTENER TARIFA (PRIORIDAD POR ESPECIFICIDAD)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtener
    @TarifaConceptoCodigo VARCHAR(40),
    @ImpresoraId INT = NULL,
    @InventarioTipoId INT = NULL,
    @InventarioNombreId INT = NULL,
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
        SELECT NULL AS TarifaId, NULL AS Monto, NULL AS Moneda,
               'error' AS result, 'Concepto de tarifa inválido o inactivo.' AS message;
        RETURN;
    END

    SELECT TOP(1)
        t.TarifaId, t.Monto, t.Moneda,
        'success' AS result, 'OK' AS message
    FROM dbo.TblTarifas t WITH (NOLOCK)
    WHERE t.TarifaConceptoId = @TarifaConceptoId
      AND t.EstaActivo = 1
      AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
      AND (t.InventarioTipoId IS NULL OR t.InventarioTipoId = @InventarioTipoId)
      AND (t.InventarioNombreId IS NULL OR t.InventarioNombreId = @InventarioNombreId)
    ORDER BY
      CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
      CASE WHEN t.InventarioNombreId = @InventarioNombreId THEN 2 WHEN t.InventarioNombreId IS NULL THEN 1 ELSE 0 END DESC,
      CASE WHEN t.InventarioTipoId = @InventarioTipoId THEN 2 WHEN t.InventarioTipoId IS NULL THEN 1 ELSE 0 END DESC,
      t.TarifaId DESC;
END
GO


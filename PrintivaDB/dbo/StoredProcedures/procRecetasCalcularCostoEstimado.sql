/* =========================================================
   FASE 1: Motor de costos estimado por Receta (corregido)
   - MATERIAL_GR  (scope por InventarioTipoId / InventarioNombreId)
   - PRINT_HOUR   (scope por ImpresoraId o global)
   - POST_HOUR    (global)
   - MARGIN_PCT   (global)
   ========================================================= */
CREATE   PROCEDURE dbo.procRecetasCalcularCostoEstimado
    @RecetaId INT,
    @ImpresoraId INT = NULL,
    @loginId INT,
    @SoloResumen BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Validaciones */
    IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u WITH (NOLOCK) WHERE u.Id = @loginId)
    BEGIN
        SELECT 'error' AS result, 'Usuario no encontrado.' AS message;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TblRecetas r WITH (NOLOCK) WHERE r.RecetaId = @RecetaId AND r.EstaActivo = 1)
    BEGIN
        SELECT 'error' AS result, 'Receta no encontrada o inactiva.' AS message;
        RETURN;
    END

    /* 2) Conceptos */
    DECLARE
        @ConceptoMaterialId INT,
        @ConceptoPrintId INT,
        @ConceptoPostId INT,
        @ConceptoMarginId INT;

    SELECT @ConceptoMaterialId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'MATERIAL_GR' AND EstaActivo = 1;

    SELECT @ConceptoPrintId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'PRINT_HOUR' AND EstaActivo = 1;

    SELECT @ConceptoPostId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'POST_HOUR' AND EstaActivo = 1;

    SELECT @ConceptoMarginId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'MARGIN_PCT' AND EstaActivo = 1;

    IF @ConceptoMaterialId IS NULL
    BEGIN
        SELECT 'error' AS result, 'No existe el concepto MATERIAL_GR.' AS message;
        RETURN;
    END

    /* 3) Tiempos receta */
    DECLARE @TiempoImpresionMin INT = 0, @TiempoPostMin INT = 0;

    SELECT
        @TiempoImpresionMin = ISNULL(r.TiempoImpresionMin, 0),
        @TiempoPostMin      = ISNULL(r.TiempoPostMin, 0)
    FROM dbo.TblRecetas r WITH (NOLOCK)
    WHERE r.RecetaId = @RecetaId;

    /* 4) Material detalle (a temp table para reutilizar) */
    IF OBJECT_ID('tempdb..#MaterialDetalle') IS NOT NULL DROP TABLE #MaterialDetalle;

    SELECT
        ri.RecetaId,
        ri.InventarioId,
        CAST(ri.Cantidad AS DECIMAL(18,4)) AS Gramos,

        i.InventarioTipoId,
        it.Nombre AS InventarioTipoNombre,

        i.InventarioNombreId,
        inn.Nombre AS InventarioNombre,

        i.InventarioMarcaId,
        im.Nombre AS InventarioMarcaNombre,

        i.InventarioColorId,
        ic.Nombre AS InventarioColorNombre,

        i.InventarioUnidadId,
        iu.Nombre AS InventarioUnidadNombre,

        tar.Monto  AS CostoPorGramo,
        tar.Moneda AS Moneda,
        CAST(CASE WHEN tar.Monto IS NULL THEN 0 ELSE (ri.Cantidad * tar.Monto) END AS DECIMAL(18,4)) AS CostoLinea,
        CASE WHEN tar.Monto IS NULL THEN 1 ELSE 0 END AS FaltaTarifa
    INTO #MaterialDetalle
    FROM dbo.TblRecetasInventarios ri WITH (NOLOCK)
    INNER JOIN dbo.TblInventarios i WITH (NOLOCK)
        ON i.InventarioId = ri.InventarioId
    LEFT JOIN dbo.TblInventariosTipos it WITH (NOLOCK)
        ON it.InventarioTipoId = i.InventarioTipoId
    LEFT JOIN dbo.TblInventariosNombres inn WITH (NOLOCK)
        ON inn.InventarioNombreId = i.InventarioNombreId
    LEFT JOIN dbo.TblInventariosMarcas im WITH (NOLOCK)
        ON im.InventarioMarcaId = i.InventarioMarcaId
    LEFT JOIN dbo.TblInventariosColores ic WITH (NOLOCK)
        ON ic.InventarioColorId = i.InventarioColorId
    LEFT JOIN dbo.TblInventariosUnidades iu WITH (NOLOCK)
        ON iu.InventarioUnidadId = i.InventarioUnidadId
    OUTER APPLY (
        SELECT TOP(1) t.Monto, t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.TarifaConceptoId = @ConceptoMaterialId
          AND t.EstaActivo = 1
          AND (t.InventarioTipoId IS NULL OR t.InventarioTipoId = i.InventarioTipoId)
          AND (t.InventarioNombreId IS NULL OR t.InventarioNombreId = i.InventarioNombreId)
        ORDER BY
          CASE WHEN t.InventarioNombreId = i.InventarioNombreId THEN 2 WHEN t.InventarioNombreId IS NULL THEN 1 ELSE 0 END DESC,
          CASE WHEN t.InventarioTipoId = i.InventarioTipoId THEN 2 WHEN t.InventarioTipoId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC
    ) tar
    WHERE ri.RecetaId = @RecetaId
      AND ri.EstaActivo = 1;

    DECLARE
        @TotalMaterial DECIMAL(18,4) = 0,
        @ItemsSinTarifa INT = 0,
        @MonedasDistintas INT = 0;

    SELECT
        @TotalMaterial = ISNULL(SUM(CostoLinea), 0),
        @ItemsSinTarifa = ISNULL(SUM(FaltaTarifa), 0),
        @MonedasDistintas = COUNT(DISTINCT ISNULL(Moneda,''))
    FROM #MaterialDetalle;

    /* 5) Tarifas de impresión/post/margen */
    DECLARE
        @PrintRate DECIMAL(18,4) = NULL, @PrintMoneda CHAR(3) = NULL,
        @PostRate  DECIMAL(18,4) = NULL, @PostMoneda  CHAR(3) = NULL,
        @MarginPct DECIMAL(18,4) = NULL;

    -- PRINT_HOUR (por impresora o global)
    IF @ConceptoPrintId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @PrintRate = t.Monto,
            @PrintMoneda = t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.TarifaConceptoId = @ConceptoPrintId
          AND t.EstaActivo = 1
          AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY
          CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC;
    END

    -- POST_HOUR (global; si luego quieres override por impresora, ya tienes el campo)
    IF @ConceptoPostId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @PostRate = t.Monto,
            @PostMoneda = t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.TarifaConceptoId = @ConceptoPostId
          AND t.EstaActivo = 1
          AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY
          CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC;
    END

    -- MARGIN_PCT (global)
    IF @ConceptoMarginId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @MarginPct = t.Monto
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.TarifaConceptoId = @ConceptoMarginId
          AND t.EstaActivo = 1
          AND t.ImpresoraId IS NULL
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY t.TarifaId DESC;
    END

    /* 6) Cálculos */
    DECLARE @CostoImpresion DECIMAL(18,4) =
        CASE WHEN @PrintRate IS NULL THEN 0
             ELSE CAST((@TiempoImpresionMin / 60.0) * @PrintRate AS DECIMAL(18,4)) END;

    DECLARE @CostoPost DECIMAL(18,4) =
        CASE WHEN @PostRate IS NULL THEN 0
             ELSE CAST((@TiempoPostMin / 60.0) * @PostRate AS DECIMAL(18,4)) END;

    DECLARE @CostoExtra DECIMAL(18,4) = 0;
    DECLARE @CostoTotal DECIMAL(18,4) = CAST(@TotalMaterial + @CostoImpresion + @CostoPost + @CostoExtra AS DECIMAL(18,4));

    DECLARE @MargenUsado DECIMAL(18,4) = ISNULL(@MarginPct, 0);

    DECLARE @PrecioSugerido DECIMAL(18,4) =
        CASE
          WHEN @MargenUsado >= 100 OR @MargenUsado < 0 THEN NULL
          ELSE CAST(@CostoTotal / (1 - (@MargenUsado / 100.0)) AS DECIMAL(18,4))
        END;

    DECLARE @MonedaFinal CHAR(3) = COALESCE(@PrintMoneda, @PostMoneda, (SELECT TOP 1 Moneda FROM #MaterialDetalle WHERE Moneda IS NOT NULL), 'MXN');

    DECLARE @Warnings NVARCHAR(500) = N'';
    IF @ItemsSinTarifa > 0 SET @Warnings += N'Faltan tarifas MATERIAL_GR para algunos insumos. ';
    IF @PrintRate IS NULL SET @Warnings += N'Falta tarifa PRINT_HOUR (global o por impresora). ';
    IF @PostRate IS NULL  SET @Warnings += N'Falta tarifa POST_HOUR. ';
    IF @MarginPct IS NULL SET @Warnings += N'Falta tarifa MARGIN_PCT (se usó 0%). ';
    IF @MonedasDistintas > 1 SET @Warnings += N'Hay más de una moneda en material. ';

    /* 7) Output */
    IF @SoloResumen = 0
    BEGIN
        SELECT *
        FROM #MaterialDetalle
        ORDER BY FaltaTarifa DESC, InventarioTipoId, InventarioId;
    END

    SELECT
        'success' AS result,
        'OK' AS message,
        @RecetaId AS RecetaId,
        @ImpresoraId AS ImpresoraId,
        @TiempoImpresionMin AS TiempoImpresionMin,
        @TiempoPostMin AS TiempoPostMin,
        @TotalMaterial AS CostoMaterial,
        @CostoImpresion AS CostoImpresion,
        @CostoPost AS CostoPost,
        @CostoExtra AS CostoExtra,
        @CostoTotal AS CostoTotal,
        @MargenUsado AS MargenPctUsado,
        @PrecioSugerido AS PrecioSugerido,
        @MonedaFinal AS Moneda,
        @ItemsSinTarifa AS ItemsSinTarifaMaterial,
        @Warnings AS Warnings;
END
GO


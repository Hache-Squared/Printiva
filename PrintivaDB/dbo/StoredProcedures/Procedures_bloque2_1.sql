
CREATE OR ALTER PROCEDURE dbo.procProduccionCosteoMaterialUpsert
    @ProduccionItemId INT,
    @Moneda VARCHAR(3),
    @Total DECIMAL(18,4),
    @DetallesJson NVARCHAR(MAX),
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20)='success';
    DECLARE @message VARCHAR(MAX)='Costeo guardado.';
    DECLARE @costeoId INT;

    BEGIN TRY
        IF (@ProduccionItemId <= 0) THROW 50000, 'ProduccionItemId inválido.', 1;
        IF (@Moneda IS NULL OR LEN(@Moneda) <> 3) THROW 50000, 'Moneda inválida.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblProduccionItems pi WITH (NOLOCK)
            WHERE pi.ProduccionItemId=@ProduccionItemId
              AND pi.EstaActivo=1
        )
            THROW 50000, 'Item de producción no encontrado.', 1;

        BEGIN TRAN;

        -- Upsert header (único por item+tipo)
        SELECT TOP (1) @costeoId = ProduccionCosteoId
        FROM dbo.TblProduccionCosteos WITH (UPDLOCK, HOLDLOCK)
        WHERE ProduccionItemId=@ProduccionItemId
          AND TipoCodigo='MATERIAL'
          AND EstaActivo=1
        ORDER BY Fecha DESC, ProduccionCosteoId DESC;

        IF (@costeoId IS NULL)
        BEGIN
            INSERT INTO dbo.TblProduccionCosteos(ProduccionItemId, UsuarioId, TipoCodigo, Moneda, Total)
            VALUES (@ProduccionItemId, @loginId, 'MATERIAL', @Moneda, @Total);

            SET @costeoId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.TblProduccionCosteos
               SET Moneda=@Moneda,
                   Total=@Total,
                   Fecha=SYSDATETIME()
            WHERE ProduccionCosteoId=@costeoId;
        END

        -- Reemplazar detalle (idempotente)
        DELETE FROM dbo.TblProduccionCosteosDetalle
        WHERE ProduccionCosteoId=@costeoId;

        IF (ISNULL(@DetallesJson,'') <> '')
        BEGIN
            INSERT INTO dbo.TblProduccionCosteosDetalle
            (
                ProduccionCosteoId, ConceptoCodigo, InventarioId, ImpresoraId,
                TarifaId, TarifaNombre, TarifaOrden,
                MontoTarifa, Cantidad, Subtotal, Moneda
            )
            SELECT
                @costeoId,
                j.ConceptoCodigo,
                j.InventarioId,
                j.ImpresoraId,
                j.TarifaId,
                j.TarifaNombre,
                j.TarifaOrden,
                j.MontoTarifa,
                j.Cantidad,
                j.Subtotal,
                j.Moneda
            FROM OPENJSON(@DetallesJson)
            WITH
            (
                ConceptoCodigo VARCHAR(50) '$.ConceptoCodigo',
                InventarioId INT '$.InventarioId',
                ImpresoraId INT '$.ImpresoraId',
                TarifaId INT '$.TarifaId',
                TarifaNombre NVARCHAR(200) '$.TarifaNombre',
                TarifaOrden INT '$.TarifaOrden',
                MontoTarifa DECIMAL(18,4) '$.MontoTarifa',
                Cantidad DECIMAL(18,4) '$.Cantidad',
                Subtotal DECIMAL(18,4) '$.Subtotal',
                Moneda VARCHAR(3) '$.Moneda'
            ) j;
        END

        COMMIT;

        SELECT @result [result], @message [message], @costeoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @result='fail';
        SET @message=CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], NULL [elementoId];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procProduccionInitPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = 'Producción inicializada.';
    DECLARE @elementoId INT = @PedidoId;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            THROW 50000, 'Usuario no encontrado.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND ISNULL(p.EstaActivo,1)=1)
            THROW 50000, 'Pedido no encontrado.', 1;

        DECLARE @Now DATETIME2(0) = CAST(SYSDATETIME() AS DATETIME2(0));

        DECLARE @EnProdId INT =
            (SELECT TOP 1 ProduccionEstatusId
             FROM dbo.TblProduccionEstatus (NOLOCK)
             WHERE EstaActivo=1 AND Nombre=N'En producción'
             ORDER BY Orden ASC);

        IF @EnProdId IS NULL
            SET @EnProdId = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus (NOLOCK) WHERE EstaActivo=1 ORDER BY Orden ASC);

        /* Inserta solo los faltantes */
        INSERT INTO dbo.TblProduccionItems
            (PedidoId, PedidoItemId, UsuarioId, ProductoId, Cantidad, ProduccionEstatusId, FechaInicio)
        SELECT
            pi.PedidoId,
            pi.PedidoItemId,
            p.UsuarioId,
            pi.ProductoId,
            pi.Cantidad,
            @EnProdId,
            -- si nace en En producción, arranca timer
            @Now
        FROM dbo.TblPedidoItems pi (NOLOCK)
        INNER JOIN dbo.TblPedidos p (NOLOCK) ON p.PedidoId = pi.PedidoId
        LEFT JOIN dbo.TblProduccionItems pr (NOLOCK) ON pr.PedidoItemId = pi.PedidoItemId
        WHERE pi.PedidoId = @PedidoId
          AND pr.ProduccionItemId IS NULL;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procProduccionObtenerConsumosAplicadosPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pi WITH (NOLOCK)
        WHERE pi.ProduccionItemId=@ProduccionItemId
          AND pi.EstaActivo=1
    )
    BEGIN
        -- Devuelve vacío para no romper UI
        SELECT TOP 0
            CAST(0 AS INT) AS InventarioId,
            CAST(0 AS DECIMAL(18,4)) AS CantidadUsada;
        RETURN;
    END

    SELECT
        c.InventarioId,
        CAST(SUM(c.Cantidad) AS DECIMAL(18,4)) AS CantidadUsada
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    WHERE c.ProduccionItemId=@ProduccionItemId
    GROUP BY c.InventarioId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procProduccionObtenerImpresoraIdPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        pr.ImpresoraId
    FROM dbo.TblProduccionItems pr WITH (NOLOCK)
    WHERE pr.ProduccionItemId = @ProduccionItemId
      AND pr.EstaActivo = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.procProduccionObtenerPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        RAISERROR('Usuario no encontrado.', 16, 1);

    IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND ISNULL(p.EstaActivo,1)=1)
        RAISERROR('Pedido no encontrado.', 16, 1);

    SELECT
        pr.ProduccionItemId,
        pr.PedidoId,
        pr.PedidoItemId,
        pr.ProductoId,
        p.Nombre AS ProductoNombre,
        pi.Cantidad,

        pr.ProduccionEstatusId,
        pe.Nombre AS EstatusNombre,
        pe.BadgeClass,

        pr.Notas,
        pr.FechaCreacion,
        pr.FechaActualizacion,

        pr.ImpresoraId,
        imp.Nombre AS ImpresoraNombre,
        pr.NotasOperativas,
        pr.PesoEstimadoGr,
        pr.PesoRealGr,
        pr.FechaInicio,
        pr.FechaFin,
        pr.InventarioAplicado
    FROM dbo.TblProduccionItems pr (NOLOCK)
    INNER JOIN dbo.TblPedidoItems pi (NOLOCK)
        ON pi.PedidoItemId = pr.PedidoItemId
    INNER JOIN dbo.TblProductos p (NOLOCK)
        ON p.ProductoId = pr.ProductoId
    INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK)
        ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
    LEFT JOIN dbo.TblImpresoras imp (NOLOCK)
        ON imp.ImpresoraId = pr.ImpresoraId
    WHERE pr.PedidoId = @PedidoId
      AND ISNULL(pr.EstaActivo,1) = 1
    ORDER BY pe.Orden ASC, pr.ProduccionItemId ASC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procProduccionRecetasDisponiblesPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pr (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.EstaActivo=1
    )
    BEGIN
        SELECT TOP 0
            0 AS RecetaId,
            '' AS Nombre,
            '' AS TiempoImpresion,
            CAST(0 AS BIT) AS IsSelected;
        RETURN;
    END

    DECLARE @ProductoId INT = (SELECT ProductoId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);
    DECLARE @SelectedId INT = (SELECT RecetaId  FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

    SELECT
        r.RecetaId,
        r.Nombre,
        r.TiempoImpresion,
        CAST(CASE WHEN r.RecetaId = @SelectedId THEN 1 ELSE 0 END AS BIT) AS IsSelected
    FROM dbo.TblRecetas r (NOLOCK)
    WHERE r.ProductoId = @ProductoId
      AND r.EstaActivo = 1
    ORDER BY r.RecetaId DESC;
END
GO

/* =========================================================
   FASE 1: Motor de costos estimado por Receta (corregido)
   - MATERIAL_GR  (scope por InventarioTipoId / InventarioNombreId)
   - PRINT_HOUR   (scope por ImpresoraId o global)
   - POST_HOUR    (global)
   - MARGIN_PCT   (global)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procRecetasCalcularCostoEstimado
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

CREATE OR ALTER PROCEDURE dbo.procReemplazarPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId)
        RETURN;

    DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReplicarReceta
    @loginId           INT = 0,
    @RecetaIdOrigen    INT = 0,
    @NombreNuevo       VARCHAR(200) = NULL,   -- opcional
    @ProductoIdNuevo   INT = NULL             -- opcional: si quieres clonar a otro producto
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result     VARCHAR(100) = '';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblRecetas r (NOLOCK)
            WHERE r.RecetaId = @RecetaIdOrigen AND r.EstaActivo = 1
        )
            RAISERROR('Receta origen no encontrada o inactiva.', 16, 1);

        DECLARE
            @NombreFinal       VARCHAR(200),
            @NombreBase        VARCHAR(200),
            @ProductoIdFinal   INT,
            @TiempoImpresion   VARCHAR(200),
            @TiempoImpMin      INT,
            @TiempoPostMin     INT;

        SELECT
            @ProductoIdFinal = COALESCE(@ProductoIdNuevo, r.ProductoId),
            @TiempoImpresion = r.TiempoImpresion,
            @TiempoImpMin    = COALESCE(r.TiempoImpresionMin, TRY_CONVERT(INT, NULLIF(r.TiempoImpresion,'')), 0),
            @TiempoPostMin   = COALESCE(r.TiempoPostMin, 0),
            @NombreBase      = r.Nombre
        FROM dbo.TblRecetas r
        WHERE r.RecetaId = @RecetaIdOrigen;

        -- Nombre: si no mandas, genera " (copia)" y asegura unicidad
        IF (NULLIF(@NombreNuevo,'') IS NULL)
        BEGIN
            SET @NombreBase  = CONCAT(@NombreBase, ' (copia)');
            SET @NombreFinal = @NombreBase;

            DECLARE @i INT = 2;
            WHILE EXISTS (SELECT 1 FROM dbo.TblRecetas WHERE Nombre = @NombreFinal)
            BEGIN
                SET @NombreFinal = CONCAT(@NombreBase, ' ', @i);
                SET @i += 1;
            END
        END
        ELSE
        BEGIN
            SET @NombreFinal = @NombreNuevo;

            -- si quieres que truene cuando el nombre existe, deja esto así:
            IF EXISTS (SELECT 1 FROM dbo.TblRecetas WHERE Nombre = @NombreFinal)
                RAISERROR('Nombre ya existe actualmente.', 16, 1);

            -- (si prefieres auto-sufijo también aquí, te lo ajusto)
        END

        BEGIN TRAN;

        INSERT INTO dbo.TblRecetas
        (
            Nombre,
            ProductoId,
            TiempoImpresion,
            TiempoImpresionMin,
            TiempoPostMin,
            EstaActivo
        )
        VALUES
        (
            @NombreFinal,
            @ProductoIdFinal,
            ISNULL(@TiempoImpresion,''),
            ISNULL(@TiempoImpMin,0),
            ISNULL(@TiempoPostMin,0),
            1
        );

        SET @elementoId = SCOPE_IDENTITY();

        -- Copiar materiales (solo activos)
        INSERT INTO dbo.TblRecetasInventarios (RecetaId, InventarioId, Cantidad, EstaActivo)
        SELECT
            @elementoId,
            ri.InventarioId,
            ri.Cantidad,
            1
        FROM dbo.TblRecetasInventarios ri
        WHERE ri.RecetaId = @RecetaIdOrigen
          AND ri.EstaActivo = 1;

        COMMIT;

        SET @result = 'success';
        SET @message = 'Receta replicada';

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesComprasHistorico
(
    @loginId INT,
    @desde   DATE = NULL,
    @hasta   DATE = NULL,

    @compraId INT = NULL,
    @categoriaId INT = NULL,
    @tipoId INT = NULL,
    @inventarioId INT = NULL,

    @soloActivos BIT = NULL,         -- NULL = todos
    @soloInventario BIT = NULL,      -- NULL = todos, 1 = solo afectó stock, 0 = solo NO afectó stock

    @topN INT = 10,
    @q NVARCHAR(200) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @q = NULLIF(LTRIM(RTRIM(@q)), '');
    IF (@topN IS NULL OR @topN <= 0) SET @topN = 10;

    IF OBJECT_ID('tempdb..#base') IS NOT NULL DROP TABLE #base;

    ;WITH BaseRaw AS
    (
        SELECT
            c.CompraId,
            CAST(c.FechaCreacion AS datetime2(7)) AS FechaCreacion,

            c.Descripcion AS CompraDescripcion,
            c.CompraCategoriaId,
            cat.Nombre AS CategoriaNombre,

            c.CompraTipoId,
            t.Nombre AS TipoNombre,
            CAST(t.EsInventario AS bit) AS EsInventario,

            c.FilamentoTipoId,
            ft.Nombre AS FilamentoTipoNombre,

            c.InventarioId,

            -- inventario actual (si existe)
            CAST(inv.Cantidad AS decimal(18,4)) AS InventarioCantidadActual,
            u.Nombre AS InventarioUnidadNombre,

            CONCAT(
                ISNULL(NULLIF(nom.Nombre,''), CONCAT('InventarioId=', inv.InventarioId)),
                CASE WHEN col.Nombre IS NOT NULL THEN CONCAT(' - ', col.Nombre) ELSE '' END,
                CASE WHEN mar.Nombre IS NOT NULL THEN CONCAT(' · ', mar.Nombre) ELSE '' END,
                CASE WHEN it.Nombre  IS NOT NULL THEN CONCAT(' · ', it.Nombre)  ELSE '' END
            ) AS InventarioDisplay,

            CAST(ISNULL(c.Cantidad,0) AS decimal(18,4)) AS CompraCantidad,
            CAST(ISNULL(c.CostoUnitario,0) AS decimal(18,2)) AS CompraCostoUnitario,
            CAST(ISNULL(c.CostoTotal,0) AS decimal(18,2)) AS CompraCostoTotal,

            c.EstaActivo,

            -- Última transacción (si existe)
            tx.TransaccionCompraId,
            tx.Operacion,
            tx.Descripcion AS TransaccionDescripcion,
            CAST(tx.Cantidad AS decimal(18,4)) AS TxCantidad,
            CAST(tx.CostoUnitario AS decimal(18,2)) AS TxCostoUnitario,
            CAST(tx.CostoTotal AS decimal(18,2)) AS TxCostoTotal,
            tx.FechaCompra,
            CAST(tx.FechaLog AS datetime2(7)) AS FechaLog
        FROM dbo.TblCompras c
        INNER JOIN dbo.TblComprasCategorias cat ON cat.CompraCategoriaId = c.CompraCategoriaId
        INNER JOIN dbo.TblComprasTipos t ON t.CompraTipoId = c.CompraTipoId
        LEFT JOIN dbo.TblFilamentosTipos ft ON ft.FilamentoTipoId = c.FilamentoTipoId

        LEFT JOIN dbo.TblInventarios inv ON inv.InventarioId = c.InventarioId
        LEFT JOIN dbo.TblInventariosUnidades u ON u.InventarioUnidadId = inv.InventarioUnidadId
        LEFT JOIN dbo.TblInventariosNombres nom ON nom.InventarioNombreId = inv.InventarioNombreId
        LEFT JOIN dbo.TblInventariosColores col ON col.InventarioColorId = inv.InventarioColorId
        LEFT JOIN dbo.TblInventariosMarcas mar ON mar.InventarioMarcaId = inv.InventarioMarcaId
        LEFT JOIN dbo.TblInventariosTipos it ON it.InventarioTipoId = inv.InventarioTipoId

        OUTER APPLY
        (
            SELECT TOP 1 tc.*
            FROM dbo.TblTransaccionesCompras tc
            WHERE tc.CompraId = c.CompraId
            ORDER BY tc.FechaLog DESC, tc.TransaccionCompraId DESC
        ) tx

        WHERE
            (@compraId IS NULL OR c.CompraId = @compraId)
            AND (@categoriaId IS NULL OR c.CompraCategoriaId = @categoriaId)
            AND (@tipoId IS NULL OR c.CompraTipoId = @tipoId)
            AND (@inventarioId IS NULL OR c.InventarioId = @inventarioId)
            AND (@soloActivos IS NULL OR c.EstaActivo = @soloActivos)

            AND (
                @soloInventario IS NULL
                OR (@soloInventario = 1 AND t.EsInventario = 1 AND c.InventarioId IS NOT NULL)
                OR (@soloInventario = 0 AND NOT (t.EsInventario = 1 AND c.InventarioId IS NOT NULL))
            )

            AND (@desde IS NULL OR CAST(c.FechaCreacion AS date) >= @desde)
            AND (@hasta IS NULL OR CAST(c.FechaCreacion AS date) <= @hasta)

            AND (
                @q IS NULL
                OR ISNULL(c.Descripcion,'') LIKE '%' + @q + '%'
                OR ISNULL(tx.Descripcion,'') LIKE '%' + @q + '%'
                OR cat.Nombre LIKE '%' + @q + '%'
                OR t.Nombre LIKE '%' + @q + '%'
                OR ISNULL(nom.Nombre,'') LIKE '%' + @q + '%'
                OR CAST(c.CompraId AS NVARCHAR(30)) LIKE '%' + @q + '%'
            )
    )
    SELECT
        r.*,

        CAST(r.FechaCreacion AS date) AS FechaCompraFinal,
        CAST(ISNULL(r.FechaLog, r.FechaCreacion) AS datetime2(7)) AS FechaLogFinal,

        -- valores finales: TX si existe, si no, compra
        CAST(ISNULL(r.TxCantidad, r.CompraCantidad) AS decimal(18,4)) AS CantidadFinal,
        CAST(ISNULL(r.TxCostoUnitario, r.CompraCostoUnitario) AS decimal(18,2)) AS CostoUnitarioFinal,
        CAST(ISNULL(r.TxCostoTotal, r.CompraCostoTotal) AS decimal(18,2)) AS CostoTotalFinal,

        CAST(CASE WHEN r.EsInventario = 1 AND r.InventarioId IS NOT NULL THEN 1 ELSE 0 END AS bit) AS AfectoInventario,

        CAST(NULL AS decimal(18,4)) AS InventarioAntes,
        CAST(NULL AS decimal(18,4)) AS InventarioDespues
    INTO #base
    FROM BaseRaw r;

    /* Inventario antes/después (estimado) */
    UPDATE b
    SET b.InventarioAntes   = mv.DisponibleAntes,
        b.InventarioDespues = mv.DisponibleDespues
    FROM #base b
    OUTER APPLY
    (
        SELECT TOP 1 m.DisponibleAntes, m.DisponibleDespues
        FROM dbo.TblInventariosMovimientos m
        WHERE m.CompraId = b.CompraId
        AND m.InventarioId = b.InventarioId
        AND m.DisponibleAntes IS NOT NULL
        ORDER BY m.FechaCreacion DESC, m.InventarioMovimientoId DESC
    ) mv;

    /* RS1: KPIs */
    SELECT
        COUNT(1) AS Compras,
        SUM(CASE WHEN AfectoInventario = 1 THEN 1 ELSE 0 END) AS ComprasInventario,
        SUM(CASE WHEN AfectoInventario = 0 THEN 1 ELSE 0 END) AS ComprasNoInventario,

        CAST(SUM(CostoTotalFinal) AS decimal(18,2)) AS GastoTotal,
        CAST(SUM(CASE WHEN AfectoInventario = 1 THEN CostoTotalFinal ELSE 0 END) AS decimal(18,2)) AS GastoInventario,
        CAST(SUM(CASE WHEN AfectoInventario = 0 THEN CostoTotalFinal ELSE 0 END) AS decimal(18,2)) AS GastoNoInventario,

        CAST(SUM(CASE WHEN AfectoInventario = 1 THEN CantidadFinal ELSE 0 END) AS decimal(18,4)) AS CantidadTotalInventario
    FROM #base;

    /* RS2: Top categorías */
    SELECT TOP (@topN)
        CompraCategoriaId AS CategoriaId,
        MAX(CategoriaNombre) AS CategoriaNombre,
        COUNT(1) AS Compras,
        CAST(SUM(CostoTotalFinal) AS decimal(18,2)) AS Total
    FROM #base
    GROUP BY CompraCategoriaId
    ORDER BY Total DESC, Compras DESC;

    /* RS3: Top tipos */
    SELECT TOP (@topN)
        CompraTipoId AS TipoId,
        MAX(TipoNombre) AS TipoNombre,
        MAX(CAST(EsInventario AS int)) AS EsInventario,
        COUNT(1) AS Compras,
        CAST(SUM(CostoTotalFinal) AS decimal(18,2)) AS Total
    FROM #base
    GROUP BY CompraTipoId
    ORDER BY Total DESC, Compras DESC;

    /* RS4: Top inventarios comprados */
    SELECT TOP (@topN)
        InventarioId,
        MAX(InventarioDisplay) AS InventarioNombre,
        MAX(InventarioUnidadNombre) AS UnidadNombre,
        COUNT(1) AS Compras,
        CAST(SUM(CantidadFinal) AS decimal(18,4)) AS Cantidad,
        CAST(SUM(CostoTotalFinal) AS decimal(18,2)) AS Total
    FROM #base
    WHERE AfectoInventario = 1 AND InventarioId IS NOT NULL
    GROUP BY InventarioId
    ORDER BY Total DESC, Cantidad DESC;

    /* RS5: Detalle */
    SELECT
        CompraId,
        FechaCompraFinal,
        FechaLogFinal,

        CompraCategoriaId,
        CategoriaNombre,

        CompraTipoId,
        TipoNombre,
        EsInventario,

        AfectoInventario,

        CompraDescripcion,
        FilamentoTipoId,
        FilamentoTipoNombre,

        InventarioId,
        InventarioDisplay AS InventarioNombre,
        InventarioUnidadNombre,

        CantidadFinal,
        CostoUnitarioFinal,
        CostoTotalFinal,

        InventarioCantidadActual,
        InventarioAntes,
        InventarioDespues,

        Operacion,
        TransaccionDescripcion,
        EstaActivo
    FROM #base
    ORDER BY FechaCompraFinal DESC, CompraId DESC;

    /* RS6-8: catálogos filtros */
    SELECT CompraCategoriaId AS Id, Nombre
    FROM dbo.TblComprasCategorias
    WHERE EstaActivo = 1
    ORDER BY Nombre;

    SELECT CompraTipoId AS Id, Nombre
    FROM dbo.TblComprasTipos
    WHERE EstaActivo = 1
    ORDER BY Nombre;

    SELECT
        inv.InventarioId AS Id,
        CONCAT(
            ISNULL(NULLIF(nom.Nombre,''), CONCAT('InventarioId=',inv.InventarioId)),
            CASE WHEN col.Nombre IS NOT NULL THEN CONCAT(' - ', col.Nombre) ELSE '' END,
            CASE WHEN mar.Nombre IS NOT NULL THEN CONCAT(' · ', mar.Nombre) ELSE '' END,
            CASE WHEN it.Nombre  IS NOT NULL THEN CONCAT(' · ', it.Nombre)  ELSE '' END
        ) AS Nombre
    FROM dbo.TblInventarios inv
    LEFT JOIN dbo.TblInventariosNombres nom ON nom.InventarioNombreId = inv.InventarioNombreId
    LEFT JOIN dbo.TblInventariosColores col ON col.InventarioColorId = inv.InventarioColorId
    LEFT JOIN dbo.TblInventariosMarcas mar ON mar.InventarioMarcaId = inv.InventarioMarcaId
    LEFT JOIN dbo.TblInventariosTipos it ON it.InventarioTipoId = inv.InventarioTipoId
    WHERE inv.EstaActivo = 1
      AND EXISTS (
          SELECT 1
          FROM dbo.TblCompras c
          WHERE c.InventarioId = inv.InventarioId
      )
    ORDER BY Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesConsumoInventarioDetalle
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @InventarioId INT = NULL,
    @UsuarioId INT = NULL,
    @ProductoId INT = NULL,
    @RecetaId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- defaults: últimos 7 días
    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2)); -- inclusive día completo

    SELECT
        c.Fecha,
        c.PedidoId,
        c.PedidoItemId,
        c.ProduccionItemId,
        c.UsuarioId,

        c.ProductoId,
        c.CantidadItem,

        c.RecetaId,
        c.RecetaNombre,

        c.InventarioId,
        c.InsumoNombre,
        c.UnidadNombre,

        c.Cantidad,
        c.DisponibleAntes,
        c.DisponibleDespues,

        c.DesdeEstatusId,
        de.Nombre AS DesdeEstatusNombre,
        c.HaciaEstatusId,
        he.Nombre AS HaciaEstatusNombre,

        c.Notas
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionEstatus de WITH (NOLOCK) ON de.ProduccionEstatusId = c.DesdeEstatusId
    LEFT JOIN dbo.TblProduccionEstatus he WITH (NOLOCK) ON he.ProduccionEstatusId = c.HaciaEstatusId
    WHERE c.Fecha >= @DesdeDT
      AND c.Fecha <  @HastaDT
      AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
      AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
      AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
      AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    ORDER BY c.Fecha DESC, c.ProduccionInventarioConsumoId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesConsumoInventarioResumen
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @InventarioId INT = NULL,
    @UsuarioId INT = NULL,
    @ProductoId INT = NULL,
    @RecetaId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT
        COUNT(*) AS Movimientos,
        COUNT(DISTINCT PedidoId) AS Pedidos,
        COUNT(DISTINCT InventarioId) AS Insumos,
        SUM(Cantidad) AS TotalConsumido
    FROM Base;

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT TOP 10
        InventarioId,
        MAX(InsumoNombre) AS InsumoNombre,
        MAX(UnidadNombre) AS UnidadNombre,
        SUM(Cantidad) AS Consumido,
        COUNT(*) AS Movimientos
    FROM Base
    GROUP BY InventarioId
    ORDER BY SUM(Cantidad) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesCosteoPedidoDetalle
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WITH (NOLOCK) WHERE PedidoId=@PedidoId)
    BEGIN
        SELECT TOP 0 0 AS InventarioId, '' AS InsumoNombre, '' AS UnidadNombre, 0 AS Cantidad, 0 AS CostoUnitario, 0 AS CostoTotal;
        RETURN;
    END

    SELECT
        c.InventarioId,
        MAX(c.InsumoNombre) AS InsumoNombre,
        MAX(c.UnidadNombre) AS UnidadNombre,
        SUM(c.Cantidad) AS Cantidad,

        MAX(ISNULL(inv.CostoUnitario,0)) AS CostoUnitario,
        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoTotal
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    WHERE c.PedidoId = @PedidoId
    GROUP BY c.InventarioId
    ORDER BY SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesCosteoPedidos
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -30, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    SELECT
        p.PedidoId,
        cli.Nombre ClienteNombre,
        p.TotalEstimado,

        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoReal,
        (ISNULL(p.TotalEstimado,0) - SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0))) AS Diferencia,

        MIN(c.Fecha) AS PrimerConsumo,
        MAX(c.Fecha) AS UltimoConsumo
    FROM dbo.TblPedidos p WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        ON c.PedidoId = p.PedidoId
       AND c.Fecha >= @DesdeDT
       AND c.Fecha <  @HastaDT
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    LEFT JOIN dbo.TblClientes cli 
        ON cli.ClienteId = p.ClienteId
    WHERE ISNULL(p.EstaActivo,1)=1
      AND (@PedidoId IS NULL OR p.PedidoId=@PedidoId)
    GROUP BY p.PedidoId, cli.Nombre, p.TotalEstimado
    ORDER BY p.PedidoId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesCotizacionesSeguimiento
  @loginId             INT,
  @desde               DATE          = NULL,
  @hasta               DATE          = NULL,
  @clienteId           INT           = NULL,
  @cotizacionEstatusId INT           = NULL,
  @soloConvertidas     BIT           = 0,
  @soloUltimaPorPedido BIT           = 0,
  @minMonto            DECIMAL(18,2) = NULL,
  @q                   NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SET @q = NULLIF(LTRIM(RTRIM(@q)), '');

  -----------------------------------------------------------------------
  -- Resolver IDs por NOMBRE (sin hardcode)
  -----------------------------------------------------------------------
  DECLARE
    @EstatusBorradorId   INT = NULL,
    @EstatusEnviadaId    INT = NULL,
    @EstatusAceptadaId   INT = NULL,
    @EstatusRechazadaId  INT = NULL,
    @EstatusCanceladaId  INT = NULL;

  SELECT @EstatusBorradorId = CotizacionEstatusId
  FROM dbo.TblCotizacionesEstatus
  WHERE Nombre COLLATE Latin1_General_CI_AI = N'Borrador' COLLATE Latin1_General_CI_AI;

  SELECT @EstatusEnviadaId = CotizacionEstatusId
  FROM dbo.TblCotizacionesEstatus
  WHERE Nombre COLLATE Latin1_General_CI_AI = N'Enviada' COLLATE Latin1_General_CI_AI;

  SELECT @EstatusAceptadaId = CotizacionEstatusId
  FROM dbo.TblCotizacionesEstatus
  WHERE Nombre COLLATE Latin1_General_CI_AI = N'Aceptada' COLLATE Latin1_General_CI_AI;

  SELECT @EstatusRechazadaId = CotizacionEstatusId
  FROM dbo.TblCotizacionesEstatus
  WHERE Nombre COLLATE Latin1_General_CI_AI = N'Rechazada' COLLATE Latin1_General_CI_AI;

  SELECT @EstatusCanceladaId = CotizacionEstatusId
  FROM dbo.TblCotizacionesEstatus
  WHERE Nombre COLLATE Latin1_General_CI_AI = N'Cancelada' COLLATE Latin1_General_CI_AI;

  IF OBJECT_ID('tempdb..#filtered') IS NOT NULL DROP TABLE #filtered;

  ;WITH base AS
  (
    SELECT
      c.CotizacionId,
      c.PedidoId,
      p.ClienteId,
      cl.Nombre AS ClienteNombre,

      c.CotizacionEstatusId,
      ce.Nombre AS CotizacionEstatusNombre,

      CAST(c.FechaCreacion AS datetime2(0)) AS CotizacionFechaCreacion,
      CAST(c.FechaVigencia AS datetime2(0)) AS FechaVigencia,
      c.Notas,

      p.PedidoEstatusId,
      pe.Nombre AS PedidoEstatusNombre,
      CAST(p.FechaCreacion AS datetime2(0)) AS PedidoFechaCreacion,
      CAST(p.FechaEntregaEstimada AS datetime2(0)) AS FechaEntregaEstimada,

      ROW_NUMBER() OVER (PARTITION BY c.PedidoId ORDER BY c.FechaCreacion DESC, c.CotizacionId DESC) AS rnPedido
    FROM dbo.TblCotizaciones c
    INNER JOIN dbo.TblPedidos p ON p.PedidoId = c.PedidoId
    INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
    INNER JOIN dbo.TblCotizacionesEstatus ce ON ce.CotizacionEstatusId = c.CotizacionEstatusId
    INNER JOIN dbo.TblPedidoEstatus pe ON pe.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.EstaActivo = 1
      AND c.EstaActivo = 1
      AND (@clienteId IS NULL OR p.ClienteId = @clienteId)
      AND (@cotizacionEstatusId IS NULL OR c.CotizacionEstatusId = @cotizacionEstatusId)
      AND (@desde IS NULL OR CAST(c.FechaCreacion AS DATE) >= @desde)
      AND (@hasta IS NULL OR CAST(c.FechaCreacion AS DATE) <= @hasta)
  )
  SELECT
    b.*,

    CAST(COALESCE(qt.MontoCotizacion, 0) AS DECIMAL(18,2)) AS MontoCotizacion,

    note.Pagos,
    CAST(COALESCE(note.TotalPagado, 0) AS DECIMAL(18,2)) AS TotalPagado,
    CAST(COALESCE(qt.MontoCotizacion, 0) - COALESCE(note.TotalPagado, 0) AS DECIMAL(18,2)) AS Saldo,

    lp.UltimoPagoFecha,
    lp.UltimoPagoMetodo,
    lp.UltimoPagoReferencia,
    lp.UltimoPagoTipoNombre,

    prod.ProduccionItems,
    prod.PrimerProduccionFecha,

    -------------------------------------------------------------------
    -- CATEGORIA por IDs resueltos por nombre
    -------------------------------------------------------------------
    CASE
      WHEN @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId
        THEN 'Aceptada'
      WHEN ( @EstatusRechazadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusRechazadaId )
        OR ( @EstatusCanceladaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusCanceladaId )
        THEN 'Rechazada'
      ELSE 'Pendiente'
    END AS Categoria,

    -------------------------------------------------------------------
    -- Convertida: aceptada O ya hubo dinero O ya hubo producción
    -------------------------------------------------------------------
    CASE
      WHEN ( @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId )
        OR COALESCE(note.TotalPagado, 0) > 0
        OR COALESCE(prod.ProduccionItems, 0) > 0
      THEN CAST(1 AS bit)
      ELSE CAST(0 AS bit)
    END AS Convertida,

    -------------------------------------------------------------------
    -- FechaConversion (proxy):
    -------------------------------------------------------------------
    CAST(
      COALESCE(
        note.PrimerPagoFecha,
        prod.PrimerProduccionFecha,
        CASE
          WHEN ( @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId )
          THEN b.CotizacionFechaCreacion
        END
      ) AS datetime2(0)
    ) AS FechaConversion,

    CASE
      WHEN COALESCE(
            note.PrimerPagoFecha,
            prod.PrimerProduccionFecha,
            CASE
              WHEN ( @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId )
              THEN b.CotizacionFechaCreacion
            END
          ) IS NOT NULL
      THEN DATEDIFF(
            DAY,
            CAST(b.CotizacionFechaCreacion AS DATE),
            CAST(COALESCE(
              note.PrimerPagoFecha,
              prod.PrimerProduccionFecha,
              CASE
                WHEN ( @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId )
                THEN b.CotizacionFechaCreacion
              END
            ) AS DATE)
          )
      ELSE NULL
    END AS DiasAConversion

  INTO #filtered
  FROM base b
  OUTER APPLY (
    SELECT COALESCE(SUM(ci.Cantidad * ci.PrecioUnitario), 0) AS MontoCotizacion
    FROM dbo.TblCotizacionItems ci
    WHERE ci.CotizacionId = b.CotizacionId
      AND ci.EstaActivo = 1
  ) qt
  OUTER APPLY (
    SELECT
      COUNT(1) AS Pagos,
      COALESCE(SUM(pa.Monto), 0) AS TotalPagado,
      MIN(pa.FechaPago) AS PrimerPagoFecha
    FROM dbo.TblPagos pa
    WHERE pa.CotizacionId = b.CotizacionId
      AND pa.EstaActivo = 1
  ) note
  OUTER APPLY (
    SELECT TOP (1)
      pa.FechaPago AS UltimoPagoFecha,
      pa.Metodo    AS UltimoPagoMetodo,
      pa.Referencia AS UltimoPagoReferencia,
      pt.Nombre    AS UltimoPagoTipoNombre
    FROM dbo.TblPagos pa
    INNER JOIN dbo.TblPagoTipos pt ON pt.PagoTipoId = pa.PagoTipoId
    WHERE pa.CotizacionId = b.CotizacionId
      AND pa.EstaActivo = 1
    ORDER BY pa.FechaPago DESC, pa.PagoId DESC
  ) lp
  OUTER APPLY (
    SELECT
      COUNT(1) AS ProduccionItems,
      MIN(pi.FechaCreacion) AS PrimerProduccionFecha
    FROM dbo.TblProduccionItems pi
    WHERE pi.PedidoId = b.PedidoId
      AND pi.EstaActivo = 1
  ) prod
  WHERE
    (@soloUltimaPorPedido = 0 OR b.rnPedido = 1)
    AND (@minMonto IS NULL OR COALESCE(qt.MontoCotizacion, 0) >= @minMonto)
    AND (
      @soloConvertidas = 0 OR
      (
        ( @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId )
        OR COALESCE(note.TotalPagado, 0) > 0
        OR COALESCE(prod.ProduccionItems, 0) > 0
      )
    )
    AND (
      @q IS NULL
      OR b.ClienteNombre LIKE '%' + @q + '%'
      OR COALESCE(b.Notas,'') LIKE '%' + @q + '%'
      OR CAST(b.PedidoId AS nvarchar(30)) LIKE '%' + @q + '%'
      OR CAST(b.CotizacionId AS nvarchar(30)) LIKE '%' + @q + '%'
    );

  -----------------------------------------------------------------------
  -- Resultset 1: Totales / KPIs
  -----------------------------------------------------------------------
  SELECT
    COUNT(1) AS Cotizaciones,
    SUM(MontoCotizacion) AS MontoTotal,
    SUM(CASE WHEN Categoria = 'Aceptada' THEN 1 ELSE 0 END) AS Aceptadas,
    SUM(CASE WHEN Categoria = 'Pendiente' THEN 1 ELSE 0 END) AS Pendientes,
    SUM(CASE WHEN Categoria = 'Rechazada' THEN 1 ELSE 0 END) AS Rechazadas,
    SUM(CASE WHEN Convertida = 1 THEN 1 ELSE 0 END) AS Convertidas,
    CAST(CASE WHEN COUNT(1) > 0 THEN (SUM(CASE WHEN Convertida = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(1)) ELSE 0 END AS DECIMAL(6,2)) AS ConversionPct,
    AVG(CASE WHEN Convertida = 1 AND DiasAConversion IS NOT NULL THEN CAST(DiasAConversion AS DECIMAL(18,2)) ELSE NULL END) AS AvgDiasAConversion
  FROM #filtered;

  -----------------------------------------------------------------------
  -- Resultset 2: Resumen por estatus (real)
  -----------------------------------------------------------------------
  SELECT
    CotizacionEstatusId,
    CotizacionEstatusNombre,
    COUNT(1) AS Cotizaciones,
    SUM(MontoCotizacion) AS Monto,
    SUM(CASE WHEN Convertida = 1 THEN 1 ELSE 0 END) AS Convertidas,
    CAST(CASE WHEN COUNT(1) > 0 THEN (SUM(CASE WHEN Convertida = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(1)) ELSE 0 END AS DECIMAL(6,2)) AS ConversionPct
  FROM #filtered
  GROUP BY CotizacionEstatusId, CotizacionEstatusNombre
  ORDER BY CotizacionEstatusNombre;

  -----------------------------------------------------------------------
  -- Resultset 3: Detalle
  -----------------------------------------------------------------------
  SELECT
    CotizacionId,
    PedidoId,
    ClienteId,
    ClienteNombre,
    CotizacionEstatusId,
    CotizacionEstatusNombre,
    Categoria,
    CotizacionFechaCreacion,
    FechaVigencia,
    MontoCotizacion,
    TotalPagado,
    Saldo,
    Convertida,
    FechaConversion,
    DiasAConversion,
    UltimoPagoFecha,
    UltimoPagoMetodo,
    UltimoPagoReferencia,
    UltimoPagoTipoNombre
  FROM #filtered
  ORDER BY CotizacionFechaCreacion DESC, CotizacionId DESC;

  -----------------------------------------------------------------------
  -- Resultset 4: Clientes (dropdown)
  -----------------------------------------------------------------------
  SELECT
    ClienteId AS Id,
    Nombre
  FROM dbo.TblClientes
  WHERE EstaActivo = 1
  ORDER BY Nombre;

  -----------------------------------------------------------------------
  -- Resultset 5: Estatus cotización (dropdown)
  -----------------------------------------------------------------------
  SELECT
    CotizacionEstatusId AS Id,
    Nombre
  FROM dbo.TblCotizacionesEstatus
  ORDER BY Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesIndexResumen
(
    @loginId     INT,
    @diasUrgente INT = 3,
    @topN        INT = 10,
    @minStock    DECIMAL(18,2) = 100  -- umbral para alerta de inventario bajo
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF (@diasUrgente IS NULL OR @diasUrgente <= 0) SET @diasUrgente = 3;
    IF (@topN IS NULL OR @topN <= 0) SET @topN = 10;
    IF (@minStock IS NULL OR @minStock < 0) SET @minStock = 100;

    DECLARE @now   datetime2(0) = SYSUTCDATETIME();
    DECLARE @today date         = CAST(@now AS date);

    /* ===== Estatus de pedido (según tu catálogo) ===== */
    DECLARE @EstatusEntregadoId INT =
    (
        SELECT TOP 1 PedidoEstatusId
        FROM dbo.TblPedidoEstatus
        WHERE Nombre = 'Entregado'
    );

    DECLARE @EstatusCanceladoId INT =
    (
        SELECT TOP 1 PedidoEstatusId
        FROM dbo.TblPedidoEstatus
        WHERE Nombre = 'Cancelado'
    );

    /* ===== Estatus de producción (por si te queda FechaFin NULL) ===== */
    DECLARE @ProdEstatusEntregadoId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus
        WHERE Nombre = 'Entregado'
    );

    DECLARE @ProdEstatusCanceladoId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus
        WHERE Nombre = 'Cancelado'
    );

    /* ===== Pedidos activos (no Entregado/Cancelado) ===== */
    IF OBJECT_ID('tempdb..#PedidosActivos') IS NOT NULL DROP TABLE #PedidosActivos;

    SELECT
        p.PedidoId,
        p.ClienteId,
        p.PedidoEstatusId,
        CAST(p.FechaEntregaEstimada AS datetime2(7)) AS FechaEntregaEstimada,
        CAST(ISNULL(p.TotalEstimado,0) AS decimal(18,2)) AS TotalEstimado
    INTO #PedidosActivos
    FROM dbo.TblPedidos p
    WHERE p.EstaActivo = 1
      AND p.PedidoEstatusId NOT IN (
            ISNULL(@EstatusEntregadoId, -1),
            ISNULL(@EstatusCanceladoId, -2)
      );

    /* ===== Producción pendiente (solo de pedidos activos) ===== */
    IF OBJECT_ID('tempdb..#ProdPend') IS NOT NULL DROP TABLE #ProdPend;

    SELECT
        pi.ProduccionItemId,
        pi.PedidoId,
        pi.PedidoItemId,
        pi.ProductoId,
        pi.Cantidad,
        pi.ProduccionEstatusId,
        pi.RecetaId,
        CAST(pi.InventarioAplicado AS bit) AS InventarioAplicado,
        CAST(pi.FechaInicio AS datetime2(0)) AS FechaInicio,
        CAST(pi.FechaFin    AS datetime2(0)) AS FechaFin
    INTO #ProdPend
    FROM dbo.TblProduccionItems pi
    INNER JOIN #PedidosActivos pa ON pa.PedidoId = pi.PedidoId
    WHERE pi.EstaActivo = 1
      AND pi.FechaFin IS NULL
      AND pi.ProduccionEstatusId NOT IN (
            ISNULL(@ProdEstatusEntregadoId, -1),
            ISNULL(@ProdEstatusCanceladoId, -2)
      );

    /* ===== Compras últimos 30 días ===== */
    DECLARE @ComprasUlt30Dias INT = 0;
    DECLARE @GastoComprasUlt30Dias decimal(18,2) = 0;

    SELECT
        @ComprasUlt30Dias = COUNT(1),
        @GastoComprasUlt30Dias = CAST(
            ISNULL(SUM(CAST(ISNULL(c.CostoTotal,0) AS decimal(18,2))),0)
        AS decimal(18,2))
    FROM dbo.TblCompras c
    WHERE c.EstaActivo = 1
      AND CAST(c.FechaCreacion AS date) BETWEEN DATEADD(day,-30,@today) AND @today;

    /* ===== Inventario "alerta" (simple: Cantidad < @minStock) ===== */
    IF OBJECT_ID('tempdb..#InvAlertas') IS NOT NULL DROP TABLE #InvAlertas;

    SELECT TOP (@topN)
        inv.InventarioId,
        CONCAT(
            COALESCE(NULLIF(LTRIM(RTRIM(nom.Nombre)),''), CONCAT('InventarioId=', inv.InventarioId)),
            CASE WHEN col.Nombre IS NOT NULL THEN CONCAT(' - ', col.Nombre) ELSE '' END,
            CASE WHEN mar.Nombre IS NOT NULL THEN CONCAT(' · ', mar.Nombre) ELSE '' END,
            CASE WHEN it.Nombre  IS NOT NULL THEN CONCAT(' · ', it.Nombre)  ELSE '' END
        ) AS InventarioNombre,
        u.Nombre AS UnidadNombre,
        CAST(inv.Cantidad AS decimal(18,4)) AS Disponible,
        CAST(@minStock    AS decimal(18,4)) AS Requerido,
        CAST((@minStock - CAST(inv.Cantidad AS decimal(18,4))) AS decimal(18,4)) AS Faltante
    INTO #InvAlertas
    FROM dbo.TblInventarios inv
    LEFT  JOIN dbo.TblInventariosUnidades u  ON u.InventarioUnidadId = inv.InventarioUnidadId
    LEFT  JOIN dbo.TblInventariosNombres  nom ON nom.InventarioNombreId = inv.InventarioNombreId
    LEFT  JOIN dbo.TblInventariosColores  col ON col.InventarioColorId = inv.InventarioColorId
    LEFT  JOIN dbo.TblInventariosMarcas   mar ON mar.InventarioMarcaId = inv.InventarioMarcaId
    LEFT  JOIN dbo.TblInventariosTipos    it  ON it.InventarioTipoId   = inv.InventarioTipoId
    WHERE inv.EstaActivo = 1
      AND CAST(inv.Cantidad AS decimal(18,4)) < CAST(@minStock AS decimal(18,4))
    ORDER BY CAST(inv.Cantidad AS decimal(18,4)) ASC, inv.InventarioId DESC;

    DECLARE @InventarioFaltante INT = ISNULL((SELECT COUNT(1) FROM #InvAlertas),0);

    /* ===== Pedidos urgentes ===== */
    IF OBJECT_ID('tempdb..#Urgentes') IS NOT NULL DROP TABLE #Urgentes;

    SELECT TOP (@topN)
        pa.PedidoId,
        c.Nombre  AS ClienteNombre,
        pe.Nombre AS EstatusNombre,
        pa.FechaEntregaEstimada,
        pa.TotalEstimado,
        DATEDIFF(day, @today, CAST(pa.FechaEntregaEstimada AS date)) AS DiasParaEntrega,
        CAST(CASE WHEN CAST(pa.FechaEntregaEstimada AS date) < @today THEN 1 ELSE 0 END AS bit) AS EsVencido
    INTO #Urgentes
    FROM #PedidosActivos pa
    INNER JOIN dbo.TblClientes c      ON c.ClienteId = pa.ClienteId
    INNER JOIN dbo.TblPedidoEstatus pe ON pe.PedidoEstatusId = pa.PedidoEstatusId
    WHERE pa.FechaEntregaEstimada IS NOT NULL
      AND DATEDIFF(day, @today, CAST(pa.FechaEntregaEstimada AS date)) <= @diasUrgente
    ORDER BY
        CAST(CASE WHEN CAST(pa.FechaEntregaEstimada AS date) < @today THEN 1 ELSE 0 END AS int) DESC,
        DATEDIFF(day, @today, CAST(pa.FechaEntregaEstimada AS date)) ASC,
        pa.PedidoId DESC;

    /* ===== KPIs ===== */
    DECLARE @PedidosActivos INT  = (SELECT COUNT(1) FROM #PedidosActivos);

    DECLARE @PedidosVencidos INT =
    (
        SELECT COUNT(1)
        FROM #PedidosActivos
        WHERE FechaEntregaEstimada IS NOT NULL
          AND CAST(FechaEntregaEstimada AS date) < @today
    );

    DECLARE @ProduccionPendiente INT = (SELECT COUNT(1) FROM #ProdPend);

    /* =========================
       RESULT SETS (ORDEN DAPPER)
       RS1: KPIs
       RS2: Urgentes
       RS3: Inventario alertas (Cantidad < @minStock)
       RS4: Producción pendiente
       ========================= */

    /* RS1: KPIs */
    SELECT
        @PedidosActivos          AS PedidosActivos,
        @PedidosVencidos         AS PedidosVencidos,
        @ProduccionPendiente     AS ProduccionPendiente,
        @InventarioFaltante      AS InventarioFaltante,
        ISNULL(@ComprasUlt30Dias,0)      AS ComprasUlt30Dias,
        ISNULL(@GastoComprasUlt30Dias,0) AS GastoComprasUlt30Dias;

    /* RS2: Pedidos urgentes */
    SELECT
        PedidoId,
        ClienteNombre,
        EstatusNombre,
        FechaEntregaEstimada,
        TotalEstimado,
        DiasParaEntrega,
        EsVencido
    FROM #Urgentes
    ORDER BY
        CAST(EsVencido AS int) DESC,
        DiasParaEntrega ASC,
        PedidoId DESC;

    /* RS3: Inventario alertas */
    SELECT
        InventarioId,
        InventarioNombre,
        UnidadNombre,
        Disponible,
        Requerido,
        Faltante
    FROM #InvAlertas
    ORDER BY Disponible ASC, InventarioId DESC;

    /* RS4: Producción pendiente */
    SELECT TOP (@topN)
        pp.ProduccionItemId,
        pp.PedidoId,
        cli.Nombre AS ClienteNombre,
        pr.Nombre  AS ProductoNombre,
        pp.Cantidad,
        pes.Nombre AS ProduccionEstatus,
        pp.FechaInicio,
        pp.FechaFin,
        pa.FechaEntregaEstimada,
        CASE
            WHEN pa.FechaEntregaEstimada IS NULL THEN 0
            ELSE DATEDIFF(day, @today, CAST(pa.FechaEntregaEstimada AS date))
        END AS DiasParaEntrega
    FROM #ProdPend pp
    INNER JOIN #PedidosActivos pa      ON pa.PedidoId = pp.PedidoId
    INNER JOIN dbo.TblPedidos p        ON p.PedidoId = pp.PedidoId
    INNER JOIN dbo.TblClientes cli     ON cli.ClienteId = p.ClienteId
    INNER JOIN dbo.TblProductos pr     ON pr.ProductoId = pp.ProductoId
    INNER JOIN dbo.TblProduccionEstatus pes ON pes.ProduccionEstatusId = pp.ProduccionEstatusId
    ORDER BY
        CASE WHEN pa.FechaEntregaEstimada IS NULL THEN 1 ELSE 0 END ASC,
        CASE WHEN pa.FechaEntregaEstimada IS NULL THEN 999999 ELSE DATEDIFF(day, @today, CAST(pa.FechaEntregaEstimada AS date)) END ASC,
        pp.ProduccionItemId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesInventarioConsumoMejorado
(
    @loginId     INT,
    @desde       DATE = NULL,
    @hasta       DATE = NULL,

    @pedidoId    INT  = NULL,
    @productoId  INT  = NULL,
    @recetaId    INT  = NULL,
    @inventarioId INT = NULL,

    @periodo     VARCHAR(10) = 'month',  -- day | week | month
    @topN        INT = 10,

    @q           NVARCHAR(200) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @q = NULLIF(LTRIM(RTRIM(@q)), '');
    IF (@topN IS NULL OR @topN <= 0) SET @topN = 10;

    IF OBJECT_ID('tempdb..#base') IS NOT NULL DROP TABLE #base;
    IF OBJECT_ID('tempdb..#latestCosteo') IS NOT NULL DROP TABLE #latestCosteo;
    IF OBJECT_ID('tempdb..#costeoDet') IS NOT NULL DROP TABLE #costeoDet;
    IF OBJECT_ID('tempdb..#items') IS NOT NULL DROP TABLE #items;

    ;WITH BaseRaw AS
    (
        SELECT
            c.ProduccionInventarioConsumoId,
            c.Fecha AS FechaConsumo,
            CAST(c.Fecha AS date) AS FechaConsumoDate,

            c.ProduccionItemId,
            c.PedidoId,
            c.PedidoItemId,
            c.ProductoId,
            c.RecetaId,
            c.InventarioId,

            COALESCE(NULLIF(c.RecetaNombre,''), r.Nombre) AS RecetaNombre,
            COALESCE(NULLIF(c.InsumoNombre,''), invNom.Nombre, CONCAT(N'InventarioId=', c.InventarioId)) AS InsumoNombre,
            COALESCE(NULLIF(c.UnidadNombre,''), u.Nombre) AS UnidadNombre,

            pr.Nombre AS ProductoNombre,

            p.ClienteId,
            cl.Nombre AS ClienteNombre,
            CAST(p.FechaCreacion AS datetime2(0)) AS PedidoFechaCreacion,
            CAST(ISNULL(p.TotalEstimado,0) AS decimal(18,2)) AS PedidoTotalEstimado,

            CAST(
                ISNULL(pi.Cantidad, c.CantidadItem) * ISNULL(pi.PrecioUnitarioEstimado, ISNULL(pr.PrecioSugerido, 0))
            AS decimal(18,2)) AS VentaItemEstimada,

            CAST(c.Cantidad AS decimal(18,4)) AS CantidadConsumida,

            c.DesdeEstatusId,
            c.HaciaEstatusId,
            c.Notas
        FROM dbo.TblProduccionInventarioConsumo c
        INNER JOIN dbo.TblPedidos p
            ON p.PedidoId = c.PedidoId
           AND p.EstaActivo = 1
        INNER JOIN dbo.TblClientes cl
            ON cl.ClienteId = p.ClienteId
        LEFT JOIN dbo.TblPedidoItems pi
            ON pi.PedidoItemId = c.PedidoItemId
        LEFT JOIN dbo.TblProductos pr
            ON pr.ProductoId = c.ProductoId
        LEFT JOIN dbo.TblRecetas r
            ON r.RecetaId = c.RecetaId
        LEFT JOIN dbo.TblInventarios inv
            ON inv.InventarioId = c.InventarioId
           AND inv.EstaActivo = 1
        LEFT JOIN dbo.TblInventariosNombres invNom
            ON invNom.InventarioNombreId = inv.InventarioNombreId
        LEFT JOIN dbo.TblInventariosUnidades u
            ON u.InventarioUnidadId = COALESCE(c.InventarioUnidadId, inv.InventarioUnidadId)
        WHERE
            (@desde IS NULL OR CAST(c.Fecha AS date) >= @desde)
            AND (@hasta IS NULL OR CAST(c.Fecha AS date) <= @hasta)

            AND (@pedidoId IS NULL OR c.PedidoId = @pedidoId)
            AND (@productoId IS NULL OR c.ProductoId = @productoId)
            AND (@recetaId IS NULL OR c.RecetaId = @recetaId)
            AND (@inventarioId IS NULL OR c.InventarioId = @inventarioId)

            AND (
                @q IS NULL
                OR cl.Nombre LIKE '%' + @q + '%'
                OR pr.Nombre LIKE '%' + @q + '%'
                OR COALESCE(NULLIF(c.RecetaNombre,''), r.Nombre, '') LIKE '%' + @q + '%'
                OR COALESCE(NULLIF(c.InsumoNombre,''), invNom.Nombre, '') LIKE '%' + @q + '%'
                OR COALESCE(c.Notas,'') LIKE '%' + @q + '%'
                OR CAST(c.PedidoId AS NVARCHAR(30)) LIKE '%' + @q + '%'
                OR CAST(c.ProduccionItemId AS NVARCHAR(30)) LIKE '%' + @q + '%'
            )
    )
    SELECT
        r.*,
        CAST(
            CASE
                WHEN LOWER(@periodo) = 'day' THEN r.FechaConsumoDate
                WHEN LOWER(@periodo) = 'week' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, r.FechaConsumoDate), 0)
                WHEN LOWER(@periodo) = 'month' THEN DATEFROMPARTS(YEAR(r.FechaConsumoDate), MONTH(r.FechaConsumoDate), 1)
                ELSE r.FechaConsumoDate
            END
        AS date) AS PeriodoInicio,

        CAST(0 AS decimal(18,4)) AS CostoUnitarioActual,
        CAST(0 AS decimal(18,4)) AS CostoTotalEstimado,

        CAST(0 AS decimal(18,4)) AS CostoMaterialTotalItem,
        CAST(0 AS decimal(18,4)) AS CostoMaterialGlobalItem,

        -- NUEVAS COLUMNAS (para mostrar en tabla detalle)
        CAST(0 AS decimal(18,4)) AS CostoGlobalAplicado,
        CAST(0 AS decimal(18,4)) AS CostoTotalConGlobal,
        CAST(0 AS decimal(18,4)) AS CostoUnitarioConGlobal

    INTO #base
    FROM BaseRaw r;

    /* =========================================================
       1) Último costeo MATERIAL por ProduccionItemId
    ========================================================= */
    ;WITH Latest AS
    (
        SELECT
            pc.ProduccionItemId,
            pc.ProduccionCosteoId,
            pc.Fecha,
            ROW_NUMBER() OVER
            (
                PARTITION BY pc.ProduccionItemId
                ORDER BY pc.Fecha DESC, pc.ProduccionCosteoId DESC
            ) AS rn
        FROM dbo.TblProduccionCosteos pc
        WHERE pc.EstaActivo = 1
          AND pc.TipoCodigo = 'MATERIAL'
          AND EXISTS (SELECT 1 FROM #base b WHERE b.ProduccionItemId = pc.ProduccionItemId)
    )
    SELECT
        ProduccionItemId,
        ProduccionCosteoId,
        Fecha
    INTO #latestCosteo
    FROM Latest
    WHERE rn = 1;

    /* =========================================================
       2) Detalle de tarifas (MATERIAL*) + nombre de tarifa real
    ========================================================= */
    SELECT
        lc.ProduccionItemId,
        lc.ProduccionCosteoId,
        lc.Fecha AS FechaCosteo,

        d.ConceptoCodigo,
        COALESCE(NULLIF(tc.Nombre,''), d.ConceptoCodigo) AS ConceptoNombre,
        tc.Unidad AS ConceptoUnidad,

        ISNULL(d.InventarioId, 0) AS InventarioId,
        d.ImpresoraId,

        d.TarifaId,
        COALESCE(NULLIF(t.Nombre,''), d.TarifaNombre) AS TarifaNombre,
        d.TarifaOrden,

        CAST(d.MontoTarifa AS decimal(18,4)) AS MontoTarifa,
        CAST(d.Cantidad AS decimal(18,4)) AS Cantidad,
        CAST(d.Subtotal AS decimal(18,4)) AS Subtotal,
        d.Moneda
    INTO #costeoDet
    FROM dbo.TblProduccionCosteosDetalle d
    INNER JOIN #latestCosteo lc
        ON lc.ProduccionCosteoId = d.ProduccionCosteoId
    LEFT JOIN dbo.TblTarifaConceptos tc
        ON tc.Codigo = d.ConceptoCodigo
    LEFT JOIN dbo.TblTarifas t
        ON t.TarifaId = d.TarifaId
    WHERE d.ConceptoCodigo LIKE 'MATERIAL%';

    /* =========================================================
       3) #base costo por INSUMO
    ========================================================= */
    UPDATE b
       SET b.CostoTotalEstimado = ISNULL(x.CostoTotal, 0),
           b.CostoUnitarioActual =
               CASE
                   WHEN ISNULL(b.CantidadConsumida,0) > 0
                   THEN CAST(ISNULL(x.CostoTotal, 0) / NULLIF(b.CantidadConsumida,0) AS decimal(18,4))
                   ELSE 0
               END
    FROM #base b
    OUTER APPLY
    (
        SELECT SUM(cd.Subtotal) AS CostoTotal
        FROM #costeoDet cd
        WHERE cd.ProduccionItemId = b.ProduccionItemId
          AND cd.InventarioId = ISNULL(b.InventarioId,0)
    ) x;

    /* =========================================================
       4) #items (1 por ProduccionItem)
    ========================================================= */
    SELECT
        b.ProduccionItemId,
        MAX(b.PedidoId) AS PedidoId,
        MAX(b.ClienteNombre) AS ClienteNombre,
        MAX(b.PedidoFechaCreacion) AS PedidoFechaCreacion,
        MAX(b.PedidoTotalEstimado) AS PedidoTotalEstimado,

        MAX(b.ProductoId) AS ProductoId,
        MAX(b.ProductoNombre) AS ProductoNombre,

        MAX(b.RecetaId) AS RecetaId,
        MAX(b.RecetaNombre) AS RecetaNombre,

        MAX(b.VentaItemEstimada) AS VentaItemEstimada,

        SUM(b.CostoTotalEstimado) AS CostoInsumosItem,

        ISNULL((
            SELECT SUM(Subtotal) FROM #costeoDet cd
            WHERE cd.ProduccionItemId = b.ProduccionItemId
        ), 0) AS CostoMaterialTotalItem,

        ISNULL((
            SELECT SUM(Subtotal) FROM #costeoDet cd
            WHERE cd.ProduccionItemId = b.ProduccionItemId
              AND cd.InventarioId = 0
        ), 0) AS CostoMaterialGlobalItem
    INTO #items
    FROM #base b
    GROUP BY b.ProduccionItemId;

    -- reflejar totales en #base (y nuevas columnas global/total)
    UPDATE b
       SET b.CostoMaterialTotalItem = i.CostoMaterialTotalItem,
           b.CostoMaterialGlobalItem = i.CostoMaterialGlobalItem,
           b.CostoGlobalAplicado = i.CostoMaterialGlobalItem,
           b.CostoTotalConGlobal = (b.CostoTotalEstimado + i.CostoMaterialGlobalItem),
           b.CostoUnitarioConGlobal =
               CASE
                   WHEN ISNULL(b.CantidadConsumida,0) > 0
                   THEN CAST((b.CostoTotalEstimado + i.CostoMaterialGlobalItem) / NULLIF(b.CantidadConsumida,0) AS decimal(18,4))
                   ELSE 0
               END
    FROM #base b
    INNER JOIN #items i ON i.ProduccionItemId = b.ProduccionItemId;

    /* =========================================================
       Resultset 1: KPIs
    ========================================================= */
    SELECT
        (SELECT COUNT(1) FROM #base) AS Movimientos,
        COUNT(1) AS ProduccionItems,

        COUNT(DISTINCT PedidoId) AS Pedidos,
        COUNT(DISTINCT ProductoId) AS Productos,
        COUNT(DISTINCT RecetaId) AS Recetas,
        (SELECT COUNT(DISTINCT InventarioId) FROM #base) AS Insumos,

        (SELECT SUM(CantidadConsumida) FROM #base) AS CantidadTotal,

        CAST((SELECT SUM(CostoTotalEstimado) FROM #base) AS decimal(18,4)) AS CostoInsumosEstimado,
        CAST(SUM(CostoMaterialTotalItem) AS decimal(18,4)) AS CostoMaterialTotal,
        CAST(SUM(CostoMaterialGlobalItem) AS decimal(18,4)) AS CostoMaterialGlobal,

        CAST(SUM(ISNULL(VentaItemEstimada,0)) AS decimal(18,2)) AS VentaItemsEstimada,

        CASE
            WHEN SUM(ISNULL(VentaItemEstimada,0)) > 0
            THEN CAST(SUM(CostoMaterialTotalItem) / NULLIF(SUM(ISNULL(VentaItemEstimada,0)),0) AS decimal(18,4))
            ELSE NULL
        END AS RatioCostoSobreVentaItems
    FROM #items;

    /* =========================================================
       Resultset 2: TOP insumos
    ========================================================= */
    SELECT TOP (@topN)
        InventarioId,
        InsumoNombre,
        UnidadNombre,
        SUM(CantidadConsumida) AS CantidadTotal,
        SUM(CostoTotalEstimado) AS CostoTotalEstimado,
        COUNT(DISTINCT PedidoId) AS Pedidos,
        COUNT(DISTINCT ProductoId) AS Productos
    FROM #base
    GROUP BY InventarioId, InsumoNombre, UnidadNombre
    ORDER BY CostoTotalEstimado DESC, CantidadTotal DESC;

    /* =========================================================
       Resultset 3: Consumo por producto
    ========================================================= */
    SELECT
        i.ProductoId,
        MAX(i.ProductoNombre) AS ProductoNombre,
        (SELECT SUM(b2.CantidadConsumida) FROM #base b2 WHERE b2.ProductoId = i.ProductoId) AS CantidadTotal,
        (SELECT SUM(b2.CostoTotalEstimado) FROM #base b2 WHERE b2.ProductoId = i.ProductoId) AS CostoInsumosEstimado,
        SUM(i.CostoMaterialTotalItem) AS CostoMaterialTotal,
        SUM(ISNULL(i.VentaItemEstimada,0)) AS VentaItemsEstimada,
        COUNT(DISTINCT i.PedidoId) AS Pedidos,
        COUNT(1) AS ProduccionItems,
        COUNT(DISTINCT i.RecetaId) AS Recetas
    FROM #items i
    GROUP BY i.ProductoId
    ORDER BY CostoMaterialTotal DESC, CostoInsumosEstimado DESC;

    /* =========================================================
       Resultset 4: Consumo por pedido
    ========================================================= */
    SELECT
        i.PedidoId,
        MAX(i.ClienteNombre) AS ClienteNombre,
        MAX(i.PedidoFechaCreacion) AS PedidoFechaCreacion,
        MAX(i.PedidoTotalEstimado) AS PedidoTotalEstimado,
        (SELECT SUM(b2.CantidadConsumida) FROM #base b2 WHERE b2.PedidoId = i.PedidoId) AS CantidadTotal,
        (SELECT SUM(b2.CostoTotalEstimado) FROM #base b2 WHERE b2.PedidoId = i.PedidoId) AS CostoInsumosEstimado,
        SUM(i.CostoMaterialTotalItem) AS CostoMaterialTotal,
        SUM(ISNULL(i.VentaItemEstimada,0)) AS VentaItemsEstimada,
        CASE
            WHEN SUM(ISNULL(i.VentaItemEstimada,0)) > 0
            THEN CAST(SUM(i.CostoMaterialTotalItem) / NULLIF(SUM(ISNULL(i.VentaItemEstimada,0)),0) AS decimal(18,4))
            ELSE NULL
        END AS RatioCostoSobreVentaItems
    FROM #items i
    GROUP BY i.PedidoId
    ORDER BY CostoMaterialTotal DESC, i.PedidoId DESC;

    /* =========================================================
       Resultset 5: Consumo por receta
    ========================================================= */
    SELECT
        i.RecetaId,
        MAX(i.RecetaNombre) AS RecetaNombre,
        MAX(i.ProductoId) AS ProductoId,
        MAX(i.ProductoNombre) AS ProductoNombre,
        (SELECT SUM(b2.CantidadConsumida) FROM #base b2 WHERE b2.RecetaId = i.RecetaId) AS CantidadTotal,
        (SELECT SUM(b2.CostoTotalEstimado) FROM #base b2 WHERE b2.RecetaId = i.RecetaId) AS CostoInsumosEstimado,
        SUM(i.CostoMaterialTotalItem) AS CostoMaterialTotal,
        COUNT(1) AS ProduccionItems,
        COUNT(DISTINCT i.PedidoId) AS Pedidos
    FROM #items i
    GROUP BY i.RecetaId
    ORDER BY CostoMaterialTotal DESC, CostoInsumosEstimado DESC;

    /* =========================================================
       Resultset 6: TOP por periodo
    ========================================================= */
    ;WITH Agg AS
    (
        SELECT
            PeriodoInicio,
            InventarioId,
            InsumoNombre,
            UnidadNombre,
            SUM(CantidadConsumida) AS CantidadTotal,
            SUM(CostoTotalEstimado) AS CostoTotalEstimado
        FROM #base
        GROUP BY PeriodoInicio, InventarioId, InsumoNombre, UnidadNombre
    ),
    Ranked AS
    (
        SELECT
            a.*,
            ROW_NUMBER() OVER (PARTITION BY a.PeriodoInicio ORDER BY a.CostoTotalEstimado DESC, a.CantidadTotal DESC) AS rn
        FROM Agg a
    )
    SELECT
        PeriodoInicio,
        InventarioId,
        InsumoNombre,
        UnidadNombre,
        CantidadTotal,
        CostoTotalEstimado
    FROM Ranked
    WHERE rn <= @topN
    ORDER BY PeriodoInicio DESC, rn ASC;

    /* =========================================================
       Resultset 7: Detalle (incluye global + total con global)
    ========================================================= */
    SELECT
        ProduccionInventarioConsumoId,
        FechaConsumo,
        PedidoId,
        ClienteNombre,
        PedidoItemId,
        ProduccionItemId,

        ProductoId,
        ProductoNombre,

        RecetaId,
        RecetaNombre,

        InventarioId,
        InsumoNombre,
        UnidadNombre,

        CantidadConsumida,

        CostoUnitarioActual,
        CostoTotalEstimado,

        CostoMaterialTotalItem,
        CostoMaterialGlobalItem,

        CostoGlobalAplicado,
        CostoTotalConGlobal,
        CostoUnitarioConGlobal,

        VentaItemEstimada,
        PedidoTotalEstimado,

        DesdeEstatusId,
        HaciaEstatusId,
        Notas
    FROM #base
    ORDER BY FechaConsumo DESC, ProduccionInventarioConsumoId DESC;

    /* =========================================================
       Resultset 8: Desglose tarifas (incluye TarifaNombre real)
    ========================================================= */
    SELECT
        ProduccionItemId,
        ProduccionCosteoId,
        FechaCosteo,

        ConceptoCodigo,
        ConceptoNombre,
        ConceptoUnidad,

        InventarioId,
        ImpresoraId,

        TarifaId,
        TarifaNombre,
        TarifaOrden,

        MontoTarifa,
        Cantidad,
        Subtotal,
        Moneda
    FROM #costeoDet
    ORDER BY ProduccionItemId DESC, TarifaOrden ASC, TarifaId ASC;

    /* =========================================================
       Resultset 9-11: Catálogos
    ========================================================= */
    SELECT
        ProductoId AS Id,
        Nombre
    FROM dbo.TblProductos
    WHERE EstaActivo = 1
    ORDER BY Nombre;

    SELECT
        RecetaId AS Id,
        Nombre,
        ProductoId
    FROM dbo.TblRecetas
    WHERE EstaActivo = 1
    ORDER BY Nombre;

    SELECT DISTINCT
        inv.InventarioId AS Id,
        COALESCE(n.Nombre, CONCAT(N'InventarioId=', inv.InventarioId)) AS Nombre,
        u.Nombre AS UnidadNombre
    FROM dbo.TblInventarios inv
    LEFT JOIN dbo.TblInventariosNombres n ON n.InventarioNombreId = inv.InventarioNombreId
    LEFT JOIN dbo.TblInventariosUnidades u ON u.InventarioUnidadId = inv.InventarioUnidadId
    WHERE inv.EstaActivo = 1
      AND EXISTS (
        SELECT 1 FROM dbo.TblProduccionInventarioConsumo c
        WHERE c.InventarioId = inv.InventarioId
      )
    ORDER BY Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.procReportesPagosCxcAging
  @loginId      INT,
  @desde        DATE        = NULL,
  @hasta        DATE        = NULL,
  @clienteId    INT         = NULL,
  @pedidoId     INT         = NULL,
  @soloVencidos BIT         = 0,
  @bucketId     INT         = NULL,   -- 0=no vencido, 1=1-7, 2=8-14, 3=15-30, 4=31-60, 5=61+
  @metodo       NVARCHAR(100) = NULL, -- busca en Metodo/Referencia/PagoTipo del ÚLTIMO pago
  @minSaldo     DECIMAL(18,2) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SET @metodo = NULLIF(LTRIM(RTRIM(@metodo)), N'');

  ;WITH base AS
  (
    SELECT
      p.PedidoId,
      p.UsuarioId,
      p.ClienteId,
      cl.Nombre AS ClienteNombre,

      p.PedidoEstatusId,
      pe.Nombre AS PedidoEstatusNombre,

      p.FechaCreacion      AS PedidoFechaCreacion,
      p.FechaEntregaEstimada,
      p.TotalEstimado,

      c.CotizacionId,
      c.FechaCreacion      AS CotizacionFechaCreacion,
      c.FechaVigencia,

      qt.CotizacionTotal,
      pg.TotalPagado,

      lp.UltimoPagoFecha,
      lp.UltimoPagoMetodo,
      lp.UltimoPagoReferencia,
      lp.UltimoPagoTipoNombre,

      CAST(COALESCE(c.FechaVigencia, c.FechaCreacion, p.FechaCreacion) AS DATE) AS FechaBase
    FROM dbo.TblPedidos p
    INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus pe ON pe.PedidoEstatusId = p.PedidoEstatusId

    OUTER APPLY (
      SELECT TOP (1) *
      FROM dbo.TblCotizaciones cc
      WHERE cc.PedidoId = p.PedidoId
        AND cc.EstaActivo = 1
      ORDER BY cc.FechaCreacion DESC, cc.CotizacionId DESC
    ) c

    OUTER APPLY (
      SELECT COALESCE(SUM(ci.Cantidad * ci.PrecioUnitario), 0) AS CotizacionTotal
      FROM dbo.TblCotizacionItems ci
      WHERE ci.CotizacionId = c.CotizacionId
        AND ci.EstaActivo = 1
    ) qt

    OUTER APPLY (
      SELECT COALESCE(SUM(pa.Monto), 0) AS TotalPagado
      FROM dbo.TblPagos pa
      WHERE pa.CotizacionId = c.CotizacionId
        AND pa.EstaActivo = 1
    ) pg

    OUTER APPLY (
      SELECT TOP (1)
        pa.FechaPago   AS UltimoPagoFecha,
        pa.Metodo      AS UltimoPagoMetodo,
        pa.Referencia  AS UltimoPagoReferencia,
        pt.Nombre      AS UltimoPagoTipoNombre
      FROM dbo.TblPagos pa
      INNER JOIN dbo.TblPagoTipos pt ON pt.PagoTipoId = pa.PagoTipoId
      WHERE pa.CotizacionId = c.CotizacionId
        AND pa.EstaActivo = 1
      ORDER BY pa.FechaPago DESC, pa.PagoId DESC
    ) lp

    WHERE p.EstaActivo = 1
      AND (@clienteId IS NULL OR p.ClienteId = @clienteId)
      AND (@pedidoId  IS NULL OR p.PedidoId  = @pedidoId)
  ),
  calc AS
  (
    SELECT
      b.*,

      CAST(COALESCE(b.CotizacionTotal, b.TotalEstimado, 0) AS DECIMAL(18,2)) AS TotalCobro,
      CAST(COALESCE(b.TotalPagado, 0) AS DECIMAL(18,2)) AS TotalPagado2,
      CAST(COALESCE(b.CotizacionTotal, b.TotalEstimado, 0) - COALESCE(b.TotalPagado, 0) AS DECIMAL(18,2)) AS Saldo,

      CASE
        WHEN CAST(SYSDATETIME() AS DATE) > b.FechaBase
          THEN DATEDIFF(DAY, b.FechaBase, CAST(SYSDATETIME() AS DATE))
        ELSE 0
      END AS DiasVencidos
    FROM base b
  ),
  aged AS
  (
    SELECT
      c.*,

      CASE
        WHEN c.DiasVencidos <= 0 THEN 0
        WHEN c.DiasVencidos BETWEEN 1 AND 7 THEN 1
        WHEN c.DiasVencidos BETWEEN 8 AND 14 THEN 2
        WHEN c.DiasVencidos BETWEEN 15 AND 30 THEN 3
        WHEN c.DiasVencidos BETWEEN 31 AND 60 THEN 4
        ELSE 5
      END AS BucketId,

      CASE
        WHEN c.DiasVencidos <= 0 THEN N'No vencido'
        WHEN c.DiasVencidos BETWEEN 1 AND 7 THEN N'1-7'
        WHEN c.DiasVencidos BETWEEN 8 AND 14 THEN N'8-14'
        WHEN c.DiasVencidos BETWEEN 15 AND 30 THEN N'15-30'
        WHEN c.DiasVencidos BETWEEN 31 AND 60 THEN N'31-60'
        ELSE N'61+'
      END AS BucketNombre,

      CASE
        WHEN c.TotalCobro > 0 THEN CAST((c.TotalPagado2 / c.TotalCobro) * 100.0 AS DECIMAL(6,2))
        ELSE CAST(0 AS DECIMAL(6,2))
      END AS PagadoPct
    FROM calc c
  )
  SELECT
    a.PedidoId,
    a.UsuarioId,
    a.ClienteId,
    a.ClienteNombre,
    a.PedidoEstatusId,
    a.PedidoEstatusNombre,
    a.PedidoFechaCreacion,
    a.FechaEntregaEstimada,
    a.TotalEstimado,

    a.CotizacionId,
    a.CotizacionFechaCreacion,
    a.FechaVigencia,

    a.CotizacionTotal,
    a.TotalPagado,

    a.UltimoPagoFecha,
    a.UltimoPagoMetodo,
    a.UltimoPagoReferencia,
    a.UltimoPagoTipoNombre,

    a.FechaBase,
    a.TotalCobro,
    a.TotalPagado2,
    a.Saldo,
    a.DiasVencidos,
    a.BucketId,
    a.BucketNombre,
    a.PagadoPct
  INTO #filtered
  FROM aged a
  WHERE a.Saldo > 0
    AND (@minSaldo IS NULL OR a.Saldo >= @minSaldo)
    AND (@desde IS NULL OR a.FechaBase >= @desde)
    AND (@hasta IS NULL OR a.FechaBase <= @hasta)
    AND (@soloVencidos = 0 OR a.DiasVencidos > 0)
    AND (@bucketId IS NULL OR a.BucketId = @bucketId)
    AND (
      @metodo IS NULL
      OR COALESCE(a.UltimoPagoMetodo, N'') LIKE N'%' + @metodo + N'%'
      OR COALESCE(a.UltimoPagoReferencia, N'') LIKE N'%' + @metodo + N'%'
      OR COALESCE(a.UltimoPagoTipoNombre, N'') LIKE N'%' + @metodo + N'%'
    );

  -----------------------------------------------------------------------
  -- Resultset 1: Totales
  -----------------------------------------------------------------------
  SELECT
    COUNT(1) AS PedidosConSaldo,
    SUM(f.Saldo) AS SaldoTotal,
    SUM(f.TotalCobro) AS TotalCobro,
    SUM(f.TotalPagado2) AS TotalPagado,
    SUM(CASE WHEN f.DiasVencidos > 0 THEN 1 ELSE 0 END) AS PedidosVencidos,
    SUM(CASE WHEN f.DiasVencidos > 0 THEN f.Saldo ELSE 0 END) AS SaldoVencido
  FROM #filtered f;

  -----------------------------------------------------------------------
  -- Resultset 2: Buckets
  -----------------------------------------------------------------------
  SELECT
    f.BucketId,
    f.BucketNombre,
    COUNT(1) AS Pedidos,
    SUM(f.Saldo) AS Saldo
  FROM #filtered f
  GROUP BY f.BucketId, f.BucketNombre
  ORDER BY f.BucketId;

  -----------------------------------------------------------------------
  -- Resultset 3: Detalle
  -----------------------------------------------------------------------
  SELECT
    f.PedidoId,
    f.ClienteId,
    f.ClienteNombre,

    f.PedidoEstatusId,
    f.PedidoEstatusNombre,

    f.PedidoFechaCreacion,
    f.FechaEntregaEstimada,

    f.CotizacionId,
    f.CotizacionFechaCreacion,
    f.FechaVigencia,

    f.FechaBase,
    f.DiasVencidos,
    f.BucketId,
    f.BucketNombre,

    f.TotalCobro,
    f.TotalPagado2 AS TotalPagado,
    f.Saldo,
    f.PagadoPct,

    f.UltimoPagoFecha,
    f.UltimoPagoMetodo,
    f.UltimoPagoReferencia,
    f.UltimoPagoTipoNombre
  FROM #filtered f
  ORDER BY
    CASE WHEN f.DiasVencidos > 0 THEN 0 ELSE 1 END,
    f.DiasVencidos DESC,
    f.Saldo DESC,
    f.PedidoId DESC;

  DROP TABLE #filtered;
END
GO
CREATE   PROCEDURE dbo.procReportesInventarioConsumoMejorado
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
            CONCAT( ISNULL(cl.Nombre, ''), ' ', ISNULL(cl.ApellidoPaterno, ''), ' ', ISNULL(cl.ApellidoMaterno, '')) AS ClienteNombre,
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


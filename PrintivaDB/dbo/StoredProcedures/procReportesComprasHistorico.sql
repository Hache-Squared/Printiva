CREATE   PROCEDURE dbo.procReportesComprasHistorico
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


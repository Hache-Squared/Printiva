CREATE   PROCEDURE dbo.procReportesIndexResumen
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


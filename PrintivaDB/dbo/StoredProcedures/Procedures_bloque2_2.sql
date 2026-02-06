
CREATE OR ALTER PROCEDURE dbo.procReportesPedido360
  @pedidoId INT,
  @loginId  INT
AS
BEGIN
  SET NOCOUNT ON;

  -----------------------------------------------------------------------
  -- Cotización más reciente activa del pedido (sin filtrar por usuario)
  -----------------------------------------------------------------------
  DECLARE @CotizacionId INT;

  SELECT TOP (1)
      @CotizacionId = c.CotizacionId
  FROM dbo.TblCotizaciones c
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = c.PedidoId
  WHERE c.PedidoId = @pedidoId
    AND c.EstaActivo = 1
    AND p.EstaActivo = 1
  ORDER BY c.FechaCreacion DESC, c.CotizacionId DESC;

  -----------------------------------------------------------------------
  -- Helpers de totales (cotización y pagos)
  -----------------------------------------------------------------------
  DECLARE @QuoteTotal DECIMAL(18,2) = 0,
          @PaidTotal  DECIMAL(18,2) = 0;

  IF @CotizacionId IS NOT NULL
  BEGIN
    SELECT
      @QuoteTotal = COALESCE(SUM(ci.Cantidad * ci.PrecioUnitario), 0)
    FROM dbo.TblCotizacionItems ci
    WHERE ci.CotizacionId = @CotizacionId
      AND ci.EstaActivo = 1;

    SELECT
      @PaidTotal = COALESCE(SUM(pa.Monto), 0)
    FROM dbo.TblPagos pa
    WHERE pa.CotizacionId = @CotizacionId
      AND pa.EstaActivo = 1;
  END

  -----------------------------------------------------------------------
  -- 1) header: Cabecera del pedido + cliente + estatus + resumen
  -----------------------------------------------------------------------
  SELECT
      p.PedidoId,
      p.UsuarioId,
      p.ClienteId,
      cl.Nombre              AS ClienteNombre,
      cl.Telefono,
      cl.WhatsApp,
      cl.Instagram,
      cl.Email,
      cl.Direccion,
      cl.EstaActivo          AS ClienteEstaActivo,

      p.PedidoEstatusId,
      pe.Nombre              AS PedidoEstatusNombre,

      p.FechaCreacion,
      p.FechaEntregaEstimada,
      p.Notas,
      p.TotalEstimado,
      p.EstaActivo           AS PedidoEstaActivo,

      @CotizacionId          AS CotizacionIdVinculada,
      @QuoteTotal            AS CotizacionTotal,
      @PaidTotal             AS TotalPagado,
      (@QuoteTotal - @PaidTotal) AS TotalPendiente,

      (SELECT COUNT(1) FROM dbo.TblPedidoItems i
        WHERE i.PedidoId = p.PedidoId AND i.EstaActivo = 1) AS PedidoItemsActivos,

      (SELECT COUNT(1) FROM dbo.TblProduccionItems pr
        WHERE pr.PedidoId = p.PedidoId AND pr.EstaActivo = 1) AS ProduccionItemsActivos

  FROM dbo.TblPedidos p
  INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
  INNER JOIN dbo.TblPedidoEstatus pe ON pe.PedidoEstatusId = p.PedidoEstatusId
  WHERE p.PedidoId = @pedidoId
    AND p.EstaActivo = 1;

  -----------------------------------------------------------------------
  -- 2) items: Items del pedido + producto/categoría + resumen producción
  -----------------------------------------------------------------------
  SELECT
      i.PedidoItemId,
      i.PedidoId,
      i.ProductoId,
      pr.Nombre                     AS ProductoNombre,
      pr.ProductoCategoriaId,
      pc.Nombre                     AS ProductoCategoriaNombre,
      i.Cantidad,
      i.PrecioUnitarioEstimado,
      i.Notas,
      i.EstaActivo,

      COALESCE(prod.ProduccionItems, 0)              AS ProduccionItems,
      COALESCE(prod.CantidadEnProduccion, 0)         AS CantidadEnProduccion,
      COALESCE(prod.PesoEstimadoGrTotal, 0)          AS PesoEstimadoGrTotal,
      COALESCE(prod.PesoRealGrTotal, 0)              AS PesoRealGrTotal
  FROM dbo.TblPedidoItems i
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = i.PedidoId
  INNER JOIN dbo.TblProductos pr ON pr.ProductoId = i.ProductoId
  INNER JOIN dbo.TblProductosCategorias pc ON pc.ProductoCategoriaId = pr.ProductoCategoriaId
  OUTER APPLY (
      SELECT
          COUNT(1) AS ProduccionItems,
          COALESCE(SUM(pi.Cantidad), 0) AS CantidadEnProduccion,
          COALESCE(SUM(pi.PesoEstimadoGr), 0) AS PesoEstimadoGrTotal,
          COALESCE(SUM(pi.PesoRealGr), 0) AS PesoRealGrTotal
      FROM dbo.TblProduccionItems pi
      WHERE pi.PedidoId = i.PedidoId
        AND pi.PedidoItemId = i.PedidoItemId
        AND pi.EstaActivo = 1
  ) prod
  WHERE i.PedidoId = @pedidoId
    AND i.EstaActivo = 1
    AND p.EstaActivo = 1
  ORDER BY i.PedidoItemId;

  -----------------------------------------------------------------------
  -- 3) quote: Cotización vinculada (HEADER + ITEM en el MISMO resultset)
  -----------------------------------------------------------------------
  SELECT
      'HEADER' AS RowType,
      c.CotizacionId,
      c.PedidoId,
      c.CotizacionEstatusId,
      ce.Nombre AS CotizacionEstatusNombre,
      c.FechaCreacion,
      c.FechaVigencia,
      c.Notas,
      c.EstaActivo,
      @QuoteTotal AS CotizacionTotal,

      CAST(NULL AS INT)            AS CotizacionItemId,
      CAST(NULL AS INT)            AS ConceptoTipoId,
      CAST(NULL AS VARCHAR(100))   AS ConceptoTipoNombre,
      CAST(NULL AS INT)            AS ProductoId,
      CAST(NULL AS VARCHAR(200))   AS ProductoNombre,
      CAST(NULL AS INT)            AS ProductoCategoriaId,
      CAST(NULL AS VARCHAR(200))   AS ProductoCategoriaNombre,
      CAST(NULL AS VARCHAR(200))   AS Concepto,
      CAST(NULL AS DECIMAL(10,2))  AS Cantidad,
      CAST(NULL AS DECIMAL(10,2))  AS PrecioUnitario,
      CAST(NULL AS DECIMAL(18,2))  AS Subtotal,
      CAST(NULL AS VARCHAR(500))   AS ItemNotas
  FROM dbo.TblCotizaciones c
  INNER JOIN dbo.TblCotizacionesEstatus ce ON ce.CotizacionEstatusId = c.CotizacionEstatusId
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = c.PedidoId
  WHERE c.CotizacionId = @CotizacionId
    AND p.EstaActivo = 1

  UNION ALL

  SELECT
      'ITEM' AS RowType,
      c.CotizacionId,
      c.PedidoId,
      c.CotizacionEstatusId,
      ce.Nombre AS CotizacionEstatusNombre,
      c.FechaCreacion,
      c.FechaVigencia,
      c.Notas,
      c.EstaActivo,
      @QuoteTotal AS CotizacionTotal,

      ci.CotizacionItemId,
      ci.ConceptoTipoId,
      ct.Nombre AS ConceptoTipoNombre,
      ci.ProductoId,
      ppr.Nombre AS ProductoNombre,
      ppr.ProductoCategoriaId,
      ppc.Nombre AS ProductoCategoriaNombre,
      ci.Concepto,
      ci.Cantidad,
      ci.PrecioUnitario,
      CAST(ci.Cantidad * ci.PrecioUnitario AS DECIMAL(18,2)) AS Subtotal,
      ci.Notas AS ItemNotas
  FROM dbo.TblCotizaciones c
  INNER JOIN dbo.TblCotizacionesEstatus ce ON ce.CotizacionEstatusId = c.CotizacionEstatusId
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = c.PedidoId
  INNER JOIN dbo.TblCotizacionItems ci ON ci.CotizacionId = c.CotizacionId
  INNER JOIN dbo.TblCotizacionConceptoTipos ct ON ct.ConceptoTipoId = ci.ConceptoTipoId
  LEFT  JOIN dbo.TblProductos ppr ON ppr.ProductoId = ci.ProductoId
  LEFT  JOIN dbo.TblProductosCategorias ppc ON ppc.ProductoCategoriaId = ppr.ProductoCategoriaId
  WHERE c.CotizacionId = @CotizacionId
    AND ci.EstaActivo = 1
    AND p.EstaActivo = 1
  ORDER BY RowType, CotizacionItemId;

  -----------------------------------------------------------------------
  -- 4) payments: Pagos de la cotización vinculada
  -----------------------------------------------------------------------
  SELECT
      pa.PagoId,
      pa.CotizacionId,
      pa.PagoTipoId,
      pt.Nombre AS PagoTipoNombre,
      pa.Monto,
      pa.FechaPago,
      pa.Metodo,
      pa.Referencia,
      pa.Notas,
      pa.FechaCreacion,
      pa.EstaActivo
  FROM dbo.TblPagos pa
  INNER JOIN dbo.TblPagoTipos pt ON pt.PagoTipoId = pa.PagoTipoId
  WHERE pa.CotizacionId = @CotizacionId
    AND pa.EstaActivo = 1
  ORDER BY pa.FechaPago, pa.PagoId;

  -----------------------------------------------------------------------
  -- 5) production: Producción (items, impresora, receta, estatus)
  -----------------------------------------------------------------------
  SELECT
      pi.ProduccionItemId,
      pi.PedidoId,
      pi.PedidoItemId,
      pi.UsuarioId,
      pi.ProductoId,
      pr.Nombre AS ProductoNombre,
      pr.ProductoCategoriaId,
      pc.Nombre AS ProductoCategoriaNombre,

      pi.Cantidad,
      pi.ProduccionEstatusId,
      pes.Nombre AS ProduccionEstatusNombre,
      pes.Orden  AS ProduccionEstatusOrden,
      pes.BadgeClass,

      pi.ImpresoraId,
      imp.Nombre AS ImpresoraNombre,
      imp.Modelo AS ImpresoraModelo,

      pi.RecetaId,
      r.Nombre   AS RecetaNombre,
      r.TiempoImpresion,
      r.TiempoImpresionMin,
      r.TiempoPostMin,

      pi.PesoEstimadoGr,
      pi.PesoRealGr,
      pi.FechaInicio,
      pi.FechaFin,
      pi.InventarioAplicado,
      pi.Notas,
      pi.NotasOperativas,
      pi.FechaCreacion,
      pi.FechaActualizacion,
      pi.EstaActivo
  FROM dbo.TblProduccionItems pi
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = pi.PedidoId
  INNER JOIN dbo.TblProductos pr ON pr.ProductoId = pi.ProductoId
  INNER JOIN dbo.TblProductosCategorias pc ON pc.ProductoCategoriaId = pr.ProductoCategoriaId
  INNER JOIN dbo.TblProduccionEstatus pes ON pes.ProduccionEstatusId = pi.ProduccionEstatusId
  LEFT  JOIN dbo.TblImpresoras imp ON imp.ImpresoraId = pi.ImpresoraId
  LEFT  JOIN dbo.TblRecetas r ON r.RecetaId = pi.RecetaId
  WHERE pi.PedidoId = @pedidoId
    AND pi.EstaActivo = 1
    AND p.EstaActivo = 1
  ORDER BY pi.ProduccionItemId;

  -----------------------------------------------------------------------
  -- 6) consumption: Consumo inventario (por receta/insumo)
  -----------------------------------------------------------------------
  SELECT
      c.ProduccionInventarioConsumoId,
      c.ProduccionItemId,
      c.PedidoId,
      c.PedidoItemId,
      c.ProductoId,
      c.CantidadItem,

      c.RecetaId,
      COALESCE(c.RecetaNombre, r.Nombre) AS RecetaNombre,

      c.InventarioId,
      COALESCE(
        c.InsumoNombre,
        CONCAT(
          im.Nombre, ' ',
          inb.Nombre, ' ',
          ic.Nombre
        )
      ) AS InsumoNombre,

      c.Cantidad AS CantidadConsumida,

      ri.Cantidad AS CantidadPlaneadaBase,
      CAST(
        COALESCE(ri.Cantidad, 0) *
        COALESCE(NULLIF(c.CantidadItem, 0), pi.Cantidad, 1)
        AS DECIMAL(18,2)
      ) AS CantidadPlaneadaTotal,

      COALESCE(c.UnidadNombre, iu.Nombre) AS UnidadNombre,

      c.DisponibleAntes,
      c.DisponibleDespues,

      c.DesdeEstatusId,
      c.HaciaEstatusId,
      c.Notas,
      c.UsuarioId,
      c.Fecha
  FROM dbo.TblProduccionInventarioConsumo c
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = c.PedidoId
  LEFT  JOIN dbo.TblProduccionItems pi ON pi.ProduccionItemId = c.ProduccionItemId
  LEFT  JOIN dbo.TblRecetas r ON r.RecetaId = c.RecetaId
  LEFT  JOIN dbo.TblRecetasInventarios ri ON ri.RecetaId = c.RecetaId AND ri.InventarioId = c.InventarioId

  LEFT  JOIN dbo.TblInventarios inv ON inv.InventarioId = c.InventarioId
  LEFT  JOIN dbo.TblInventariosUnidades iu ON iu.InventarioUnidadId = COALESCE(c.InventarioUnidadId, inv.InventarioUnidadId)
  LEFT  JOIN dbo.TblInventariosMarcas im ON im.InventarioMarcaId = inv.InventarioMarcaId
  LEFT  JOIN dbo.TblInventariosNombres inb ON inb.InventarioNombreId = inv.InventarioNombreId
  LEFT  JOIN dbo.TblInventariosColores ic ON ic.InventarioColorId = inv.InventarioColorId

  WHERE c.PedidoId = @pedidoId
    AND p.EstaActivo = 1
  ORDER BY c.Fecha, c.ProduccionInventarioConsumoId;

  -----------------------------------------------------------------------
  -- 7) history: Timeline unificado (pedido + producción)
  -----------------------------------------------------------------------
  SELECT
      'PEDIDO' AS Tipo,
      b.PedidoBitacoraId AS BitacoraId,
      b.PedidoId,
      CAST(NULL AS INT) AS ProduccionItemId,
      CAST(NULL AS INT) AS PedidoItemId,
      b.UsuarioId,
      b.DesdeEstatusId,
      peD.Nombre AS DesdeEstatusNombre,
      b.HaciaEstatusId,
      peH.Nombre AS HaciaEstatusNombre,
      b.Notas,
      CAST(b.FechaMovimiento AS datetime2(0)) AS Fecha
  FROM dbo.TblPedidosBitacora b
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = b.PedidoId
  INNER JOIN dbo.TblPedidoEstatus peD ON peD.PedidoEstatusId = b.DesdeEstatusId
  INNER JOIN dbo.TblPedidoEstatus peH ON peH.PedidoEstatusId = b.HaciaEstatusId
  WHERE b.PedidoId = @pedidoId
    AND p.EstaActivo = 1

  UNION ALL

  SELECT
      'PRODUCCION' AS Tipo,
      pb.ProduccionBitacoraId AS BitacoraId,
      pb.PedidoId,
      pb.ProduccionItemId,
      pb.PedidoItemId,
      pb.UsuarioId,
      pb.DesdeEstatusId,
      prD.Nombre AS DesdeEstatusNombre,
      pb.HaciaEstatusId,
      prH.Nombre AS HaciaEstatusNombre,
      pb.Notas,
      CAST(pb.Fecha AS datetime2(0)) AS Fecha
  FROM dbo.TblProduccionBitacora pb
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = pb.PedidoId
  INNER JOIN dbo.TblProduccionEstatus prD ON prD.ProduccionEstatusId = pb.DesdeEstatusId
  INNER JOIN dbo.TblProduccionEstatus prH ON prH.ProduccionEstatusId = pb.HaciaEstatusId
  WHERE pb.PedidoId = @pedidoId
    AND p.EstaActivo = 1
  ORDER BY Tipo DESC, Fecha DESC, BitacoraId;

END
GO


CREATE OR ALTER PROCEDURE dbo.procReportesPedidosOperativos
  @loginId            INT,
  @desde              DATE        = NULL,
  @hasta              DATE        = NULL,
  @pedidoEstatusId    INT         = NULL,
  @clienteId          INT         = NULL,
  @soloAtrasados      BIT         = 0,
  @produccionEstatusId INT        = NULL,
  @canal              NVARCHAR(80)= NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @hoy DATE = CAST(GETDATE() AS DATE);

  ;WITH Base AS (
    SELECT
      p.PedidoId,
      p.UsuarioId,
      p.ClienteId,
      cl.Nombre AS ClienteNombre,
      p.PedidoEstatusId,
      pe.Nombre AS PedidoEstatusNombre,
      p.FechaCreacion,
      p.FechaEntregaEstimada,
      p.TotalEstimado,
      p.Notas,

      cq.CotizacionId,
      cq.CotizacionTotal,
      cq.TotalPagado,
      (COALESCE(cq.CotizacionTotal, 0) - COALESCE(cq.TotalPagado, 0)) AS Saldo,

      CASE
        WHEN cq.CotizacionId IS NOT NULL THEN COALESCE(cq.CotizacionTotal, 0)
        ELSE COALESCE(p.TotalEstimado, 0)
      END AS Total,

      CASE
        WHEN (CASE WHEN cq.CotizacionId IS NOT NULL THEN COALESCE(cq.CotizacionTotal, 0) ELSE COALESCE(p.TotalEstimado, 0) END) > 0
          THEN CAST( (COALESCE(cq.TotalPagado, 0) * 100.0) /
               (CASE WHEN cq.CotizacionId IS NOT NULL THEN COALESCE(cq.CotizacionTotal, 0) ELSE COALESCE(p.TotalEstimado, 0) END)
               AS DECIMAL(10,2))
        ELSE CAST(0 AS DECIMAL(10,2))
      END AS PagadoPorcentaje,

      prod.ProduccionItems,
      prod.ProduccionEstatusId,
      prod.ProduccionEstatusNombre,
      prod.ProduccionEstatusOrden,

      CAST(
        CASE
          WHEN p.FechaEntregaEstimada IS NULL THEN 0
          WHEN p.FechaEntregaEstimada >= @hoy THEN 0
          WHEN pe.Nombre LIKE '%entreg%' THEN 0
          WHEN pe.Nombre LIKE '%cancel%' THEN 0
          ELSE 1
        END
      AS BIT) AS EsAtrasado,

      CASE
        WHEN p.FechaEntregaEstimada IS NULL THEN 0
        WHEN p.FechaEntregaEstimada >= @hoy THEN 0
        WHEN pe.Nombre LIKE '%entreg%' THEN 0
        WHEN pe.Nombre LIKE '%cancel%' THEN 0
        ELSE DATEDIFF(DAY, p.FechaEntregaEstimada, @hoy)
      END AS DiasAtraso
    FROM dbo.TblPedidos p
    INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus pe ON pe.PedidoEstatusId = p.PedidoEstatusId

    OUTER APPLY (
      SELECT TOP (1)
        c.CotizacionId,
        CAST(COALESCE((
          SELECT SUM(ci.Cantidad * ci.PrecioUnitario)
          FROM dbo.TblCotizacionItems ci
          WHERE ci.CotizacionId = c.CotizacionId
            AND ci.EstaActivo = 1
        ), 0) AS DECIMAL(18,2)) AS CotizacionTotal,
        CAST(COALESCE((
          SELECT SUM(pa.Monto)
          FROM dbo.TblPagos pa
          WHERE pa.CotizacionId = c.CotizacionId
            AND pa.EstaActivo = 1
        ), 0) AS DECIMAL(18,2)) AS TotalPagado
      FROM dbo.TblCotizaciones c
      WHERE c.PedidoId = p.PedidoId
        AND c.EstaActivo = 1
      ORDER BY c.FechaCreacion DESC, c.CotizacionId DESC
    ) cq

    OUTER APPLY (
      SELECT
        COUNT(1) AS ProduccionItems,
        x.ProduccionEstatusId,
        x.ProduccionEstatusNombre,
        x.ProduccionEstatusOrden
      FROM dbo.TblProduccionItems pi
      OUTER APPLY (
        SELECT TOP (1)
          pes.ProduccionEstatusId,
          pes.Nombre AS ProduccionEstatusNombre,
          pes.Orden  AS ProduccionEstatusOrden
        FROM dbo.TblProduccionItems pi2
        INNER JOIN dbo.TblProduccionEstatus pes ON pes.ProduccionEstatusId = pi2.ProduccionEstatusId
        WHERE pi2.PedidoId = p.PedidoId
          AND pi2.EstaActivo = 1
        ORDER BY pes.Orden ASC, pi2.ProduccionItemId ASC
      ) x
      WHERE pi.PedidoId = p.PedidoId
        AND pi.EstaActivo = 1
      GROUP BY x.ProduccionEstatusId, x.ProduccionEstatusNombre, x.ProduccionEstatusOrden
    ) prod

    WHERE p.EstaActivo = 1
      AND (@pedidoEstatusId IS NULL OR p.PedidoEstatusId = @pedidoEstatusId)
      AND (@clienteId IS NULL OR p.ClienteId = @clienteId)
      AND (@produccionEstatusId IS NULL OR prod.ProduccionEstatusId = @produccionEstatusId)
      AND (
        @desde IS NULL OR
        CAST(COALESCE(p.FechaEntregaEstimada, p.FechaCreacion) AS DATE) >= @desde
      )
      AND (
        @hasta IS NULL OR
        CAST(COALESCE(p.FechaEntregaEstimada, p.FechaCreacion) AS DATE) <= @hasta
      )
      AND (
        @canal IS NULL OR @canal = '' OR
        p.Notas LIKE '%' + @canal + '%' OR
        cl.Nombre LIKE '%' + @canal + '%' OR
        cl.Instagram LIKE '%' + @canal + '%' OR
        cl.WhatsApp LIKE '%' + @canal + '%' OR
        cl.Telefono LIKE '%' + @canal + '%' OR
        cl.Email LIKE '%' + @canal + '%'
      )
  )
  SELECT
    PedidoId,
    ClienteId,
    ClienteNombre,
    Total,
    TotalPagado,
    Saldo,
    PagadoPorcentaje,
    PedidoEstatusId,
    PedidoEstatusNombre,
    ProduccionItems,
    ProduccionEstatusId,
    ProduccionEstatusNombre,
    FechaCreacion,
    FechaEntregaEstimada,
    EsAtrasado,
    DiasAtraso,

    CASE
      WHEN EsAtrasado = 1 THEN 1
      WHEN FechaEntregaEstimada IS NOT NULL AND FechaEntregaEstimada <= DATEADD(DAY, 1, @hoy) THEN 2
      WHEN Saldo > 0 THEN 3
      ELSE 4
    END AS Prioridad
  FROM Base
  WHERE (@soloAtrasados = 0 OR EsAtrasado = 1)
  ORDER BY
    Prioridad ASC,
    ISNULL(FechaEntregaEstimada, CAST(FechaCreacion AS DATE)) ASC,
    PedidoId DESC;

  -----------------------------------------------------------------------
  -- Lookups (para filtros dropdown)
  -----------------------------------------------------------------------
  SELECT PedidoEstatusId AS Id, Nombre
  FROM dbo.TblPedidoEstatus
  ORDER BY Nombre;

  SELECT ProduccionEstatusId AS Id, Nombre
  FROM dbo.TblProduccionEstatus
  WHERE EstaActivo = 1
  ORDER BY Orden, Nombre;

  SELECT ClienteId AS Id, Nombre
  FROM dbo.TblClientes
  WHERE EstaActivo = 1
  ORDER BY Nombre;

END
GO


CREATE OR ALTER PROCEDURE dbo.procReportesProduccionDashboard
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Items por estatus de producción (global)
    SELECT
        e.ProduccionEstatusId,
        e.Nombre,
        e.Orden,
        COUNT(*) AS Items
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus e WITH (NOLOCK)
        ON e.ProduccionEstatusId = i.ProduccionEstatusId
    WHERE i.EstaActivo = 1
    GROUP BY e.ProduccionEstatusId, e.Nombre, e.Orden
    ORDER BY e.Orden;

    -- Pedidos por estatus (global)
    SELECT
        pe.PedidoEstatusId,
        pe.Nombre,
        COUNT(*) AS Pedidos
    FROM dbo.TblPedidos p WITH (NOLOCK)
    INNER JOIN dbo.TblPedidoEstatus pe WITH (NOLOCK)
        ON pe.PedidoEstatusId = p.PedidoEstatusId
    WHERE ISNULL(p.EstaActivo,1)=1
    GROUP BY pe.PedidoEstatusId, pe.Nombre
    ORDER BY pe.PedidoEstatusId;

    -- WIP: items no entregados (toma el id de “Entregado” en producción)
    DECLARE @EntregadoProdId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus WITH (NOLOCK)
        WHERE EstaActivo=1 AND Nombre LIKE N'Entreg%'
        ORDER BY Orden DESC
    );

    SELECT
        COUNT(*) AS ItemsTotales,
        SUM(CASE WHEN @EntregadoProdId IS NOT NULL AND i.ProduccionEstatusId <> @EntregadoProdId THEN 1 ELSE 0 END) AS ItemsWIP
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    WHERE i.EstaActivo=1;
END
GO


CREATE OR ALTER PROCEDURE dbo.procReportesProduccionUtilizacionImpresoras
  @loginId             INT,
  @desde               DATE = NULL,
  @hasta               DATE = NULL,
  @impresoraId         INT  = NULL,
  @incluirEnCurso      BIT  = 1,
  @incluirSinImpresora BIT  = 1,
  @q                   NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SET @q = NULLIF(LTRIM(RTRIM(@q)), '');

  IF OBJECT_ID('tempdb..#base') IS NOT NULL DROP TABLE #base;

  ;WITH BaseRaw AS (
    SELECT
      pi.ProduccionItemId,
      pi.PedidoId,
      pi.PedidoItemId,
      pi.UsuarioId,
      pi.ProductoId,
      pr.Nombre AS ProductoNombre,

      p.ClienteId,
      cl.Nombre AS ClienteNombre,

      pi.Cantidad,
      pi.ProduccionEstatusId,
      pes.Nombre AS ProduccionEstatusNombre,
      pes.Orden  AS ProduccionEstatusOrden,
      pes.BadgeClass,

      pi.ImpresoraId,
      imp.Nombre AS ImpresoraNombre,
      imp.Modelo AS ImpresoraModelo,

      CAST(pi.FechaInicio AS datetime2(0)) AS FechaInicio,
      CAST(pi.FechaFin    AS datetime2(0)) AS FechaFin,
      CAST(pi.FechaCreacion AS datetime2(0)) AS FechaCreacion,

      pi.Notas,
      pi.NotasOperativas,

      CAST(COALESCE(pi.FechaFin, pi.FechaInicio, pi.FechaCreacion) AS date) AS FechaRef,

      CASE
        WHEN pes.Nombre COLLATE Latin1_General_CI_AI LIKE N'%falla%'
          OR pes.Nombre COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
          OR pes.Nombre COLLATE Latin1_General_CI_AI LIKE N'%error%'
          OR COALESCE(pi.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%falla%'
          OR COALESCE(pi.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
          OR COALESCE(pi.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%error%'
          OR COALESCE(pi.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%falla%'
          OR COALESCE(pi.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
          OR COALESCE(pi.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%error%'
        THEN CAST(1 AS bit) ELSE CAST(0 AS bit)
      END AS MarcadaFalla,

      CASE
        WHEN pes.Nombre COLLATE Latin1_General_CI_AI LIKE N'%reimp%'
          OR pes.Nombre COLLATE Latin1_General_CI_AI LIKE N'%reprint%'
          OR COALESCE(pi.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%reimp%'
          OR COALESCE(pi.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%reprint%'
          OR COALESCE(pi.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%reimp%'
          OR COALESCE(pi.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%reprint%'
        THEN CAST(1 AS bit) ELSE CAST(0 AS bit)
      END AS MarcadaReimpresion

    FROM dbo.TblProduccionItems pi
    INNER JOIN dbo.TblPedidos p ON p.PedidoId = pi.PedidoId AND p.EstaActivo = 1
    INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
    INNER JOIN dbo.TblProductos pr ON pr.ProductoId = pi.ProductoId
    INNER JOIN dbo.TblProduccionEstatus pes ON pes.ProduccionEstatusId = pi.ProduccionEstatusId

    -- Join de impresoras sin filtrar por usuario (y sin filtrar por activo)
    LEFT  JOIN dbo.TblImpresoras imp
      ON imp.ImpresoraId = pi.ImpresoraId

    WHERE
      pi.EstaActivo = 1
      AND (@impresoraId IS NULL OR pi.ImpresoraId = @impresoraId)
      AND (@incluirSinImpresora = 1 OR pi.ImpresoraId IS NOT NULL)
      AND (@desde IS NULL OR CAST(COALESCE(pi.FechaFin, pi.FechaInicio, pi.FechaCreacion) AS date) >= @desde)
      AND (@hasta IS NULL OR CAST(COALESCE(pi.FechaFin, pi.FechaInicio, pi.FechaCreacion) AS date) <= @hasta)
      AND (@q IS NULL
            OR cl.Nombre LIKE '%' + @q + '%'
            OR pr.Nombre LIKE '%' + @q + '%'
            OR COALESCE(pi.Notas,'') LIKE '%' + @q + '%'
            OR COALESCE(pi.NotasOperativas,'') LIKE '%' + @q + '%'
            OR CAST(pi.PedidoId AS NVARCHAR(30)) LIKE '%' + @q + '%'
            OR CAST(pi.ProduccionItemId AS NVARCHAR(30)) LIKE '%' + @q + '%'
      )
  )
  SELECT
    r.*,

    CASE WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NOT NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS EsCompletado,
    CASE WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS EsEnCurso,
    CASE WHEN r.FechaInicio IS NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS SinTiempos,

    CASE
      WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NOT NULL AND r.FechaFin >= r.FechaInicio
        THEN DATEDIFF(MINUTE, r.FechaInicio, r.FechaFin)
      ELSE NULL
    END AS DuracionMinCompletada,

    CASE
      WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NULL AND @incluirEnCurso = 1
        THEN CASE WHEN DATEDIFF(MINUTE, r.FechaInicio, CAST(GETDATE() AS datetime2(0))) < 0 THEN 0
                  ELSE DATEDIFF(MINUTE, r.FechaInicio, CAST(GETDATE() AS datetime2(0))) END
      ELSE NULL
    END AS DuracionMinEnCurso,

    CASE
      WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NOT NULL AND r.FechaFin >= r.FechaInicio
        THEN DATEDIFF(MINUTE, r.FechaInicio, r.FechaFin)
      WHEN r.FechaInicio IS NOT NULL AND r.FechaFin IS NULL AND @incluirEnCurso = 1
        THEN CASE WHEN DATEDIFF(MINUTE, r.FechaInicio, CAST(GETDATE() AS datetime2(0))) < 0 THEN 0
                  ELSE DATEDIFF(MINUTE, r.FechaInicio, CAST(GETDATE() AS datetime2(0))) END
      ELSE NULL
    END AS DuracionMinTotal,

    CASE
      WHEN r.MarcadaReimpresion = 1 THEN CAST(1 AS bit)
      WHEN EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pi2
        INNER JOIN dbo.TblProduccionEstatus pes2 ON pes2.ProduccionEstatusId = pi2.ProduccionEstatusId
        WHERE pi2.EstaActivo = 1
          AND pi2.PedidoItemId = r.PedidoItemId
          AND pi2.ProductoId = r.ProductoId
          AND pi2.ProduccionItemId < r.ProduccionItemId
          AND (
            pes2.Nombre COLLATE Latin1_General_CI_AI LIKE N'%falla%'
            OR pes2.Nombre COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
            OR pes2.Nombre COLLATE Latin1_General_CI_AI LIKE N'%error%'
            OR COALESCE(pi2.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%falla%'
            OR COALESCE(pi2.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
            OR COALESCE(pi2.NotasOperativas,'') COLLATE Latin1_General_CI_AI LIKE N'%error%'
            OR COALESCE(pi2.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%falla%'
            OR COALESCE(pi2.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%fallo%'
            OR COALESCE(pi2.Notas,'') COLLATE Latin1_General_CI_AI LIKE N'%error%'
          )
      ) THEN CAST(1 AS bit)
      ELSE CAST(0 AS bit)
    END AS EsReimpresion

  INTO #base
  FROM BaseRaw r;

  IF @incluirEnCurso = 0
    DELETE FROM #base WHERE EsEnCurso = 1;

  -----------------------------------------------------------------------
  -- Resultset 1: Totales KPI
  -----------------------------------------------------------------------
  SELECT
    COUNT(1) AS Items,
    SUM(CASE WHEN EsCompletado = 1 THEN 1 ELSE 0 END) AS ItemsCompletados,
    SUM(CASE WHEN EsEnCurso = 1 THEN 1 ELSE 0 END) AS ItemsEnCurso,
    SUM(CASE WHEN SinTiempos = 1 THEN 1 ELSE 0 END) AS ItemsSinTiempos,

    CAST(SUM(CASE WHEN DuracionMinCompletada IS NOT NULL THEN DuracionMinCompletada ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasCompletadas,
    CAST(SUM(CASE WHEN DuracionMinEnCurso IS NOT NULL THEN DuracionMinEnCurso ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasEnCurso,
    CAST(SUM(CASE WHEN DuracionMinTotal IS NOT NULL THEN DuracionMinTotal ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasTotales,

    AVG(CAST(COALESCE(DuracionMinCompletada, NULL) AS decimal(18,2))) AS AvgDuracionMin,

    SUM(CASE WHEN MarcadaFalla = 1 THEN 1 ELSE 0 END) AS Fallas,
    SUM(CASE WHEN EsReimpresion = 1 THEN 1 ELSE 0 END) AS Reimpresiones
  FROM #base;

  -----------------------------------------------------------------------
  -- Resultset 2: Por impresora
  -----------------------------------------------------------------------
  SELECT
    ImpresoraId,
    COALESCE(ImpresoraNombre, '(Sin impresora)') AS ImpresoraNombre,
    ImpresoraModelo,

    COUNT(1) AS Items,
    SUM(CASE WHEN EsCompletado = 1 THEN 1 ELSE 0 END) AS ItemsCompletados,
    SUM(CASE WHEN EsEnCurso = 1 THEN 1 ELSE 0 END) AS ItemsEnCurso,
    SUM(CASE WHEN SinTiempos = 1 THEN 1 ELSE 0 END) AS ItemsSinTiempos,

    CAST(SUM(CASE WHEN DuracionMinCompletada IS NOT NULL THEN DuracionMinCompletada ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasCompletadas,
    CAST(SUM(CASE WHEN DuracionMinEnCurso IS NOT NULL THEN DuracionMinEnCurso ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasEnCurso,
    CAST(SUM(CASE WHEN DuracionMinTotal IS NOT NULL THEN DuracionMinTotal ELSE 0 END) AS decimal(18,2)) / 60.0 AS HorasTotales,

    AVG(CAST(COALESCE(DuracionMinCompletada, NULL) AS decimal(18,2))) AS AvgDuracionMin,

    SUM(CASE WHEN MarcadaFalla = 1 THEN 1 ELSE 0 END) AS Fallas,
    SUM(CASE WHEN EsReimpresion = 1 THEN 1 ELSE 0 END) AS Reimpresiones
  FROM #base
  GROUP BY ImpresoraId, ImpresoraNombre, ImpresoraModelo
  ORDER BY
    CASE WHEN ImpresoraId IS NULL THEN 1 ELSE 0 END,
    HorasTotales DESC,
    Items DESC;

  -----------------------------------------------------------------------
  -- Resultset 3: Detalle
  -----------------------------------------------------------------------
  SELECT
    ProduccionItemId,
    PedidoId,
    PedidoItemId,
    ClienteId,
    ClienteNombre,
    ProductoId,
    ProductoNombre,

    ImpresoraId,
    COALESCE(ImpresoraNombre, '(Sin impresora)') AS ImpresoraNombre,
    ImpresoraModelo,

    ProduccionEstatusId,
    ProduccionEstatusNombre,
    ProduccionEstatusOrden,
    BadgeClass,

    FechaInicio,
    FechaFin,

    CAST(COALESCE(DuracionMinTotal, 0) AS decimal(18,2)) AS DuracionMin,

    EsCompletado,
    EsEnCurso,
    SinTiempos,

    MarcadaFalla,
    EsReimpresion
  FROM #base
  ORDER BY
    CASE WHEN EsEnCurso = 1 THEN 0 ELSE 1 END,
    CASE WHEN MarcadaFalla = 1 THEN 0 ELSE 1 END,
    COALESCE(DuracionMinTotal, 0) DESC,
    ProduccionItemId DESC;

  -----------------------------------------------------------------------
  -- Resultset 4: Dropdown impresoras (global)
  -----------------------------------------------------------------------
  SELECT
    ImpresoraId AS Id,
    Nombre,
    Modelo
  FROM dbo.TblImpresoras
  WHERE EstaActivo = 1
  ORDER BY Nombre;

END
GO


CREATE OR ALTER PROCEDURE dbo.procReportesProduccionWipDashboard
  @loginId        INT,
  @desde          DATE = NULL,
  @hasta          DATE = NULL,
  @clienteId      INT  = NULL,
  @pedidoId       INT  = NULL,
  @estatusId      INT  = NULL,
  @impresoraId    INT  = NULL,
  @soloWip        BIT  = 0,
  @soloAtrasados  BIT  = 0,
  @sinImpresora   BIT  = 0,
  @minDiasCola    INT  = NULL,
  @q              NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SET @q = NULLIF(LTRIM(RTRIM(@q)), '');

  -----------------------------------------------------------------------
  -- Determinar "orden final" (para decidir WIP)
  -----------------------------------------------------------------------
  DECLARE @FinalOrden INT = NULL;

  SELECT TOP (1)
    @FinalOrden = pes.Orden
  FROM dbo.TblProduccionEstatus pes
  WHERE pes.EstaActivo = 1
    AND pes.Nombre COLLATE Latin1_General_CI_AI IN
      (N'Entregado', N'Finalizado', N'Completado')
  ORDER BY pes.Orden DESC;

  IF @FinalOrden IS NULL
  BEGIN
    SELECT @FinalOrden = MAX(pes.Orden)
    FROM dbo.TblProduccionEstatus pes
    WHERE pes.EstaActivo = 1;
  END

  IF OBJECT_ID('tempdb..#prod') IS NOT NULL DROP TABLE #prod;

  -----------------------------------------------------------------------
  -- Base (materializada)
  -----------------------------------------------------------------------
  SELECT
    pi.ProduccionItemId,
    pi.PedidoId,
    pi.PedidoItemId,
    pi.UsuarioId,
    pi.ProductoId,
    pr.Nombre AS ProductoNombre,

    p.ClienteId,
    cl.Nombre AS ClienteNombre,

    pi.Cantidad,
    pi.ProduccionEstatusId,
    pes.Nombre AS ProduccionEstatusNombre,
    pes.Orden  AS ProduccionEstatusOrden,
    pes.BadgeClass,

    pi.ImpresoraId,
    imp.Nombre AS ImpresoraNombre,
    imp.Modelo AS ImpresoraModelo,

    pi.RecetaId,
    r.Nombre AS RecetaNombre,

    pi.PesoEstimadoGr,
    pi.PesoRealGr,

    CAST(pi.FechaCreacion AS datetime2(0)) AS FechaCreacion,
    CAST(pi.FechaActualizacion AS datetime2(0)) AS FechaActualizacion,
    CAST(pi.FechaInicio AS datetime2(0)) AS FechaInicio,
    CAST(pi.FechaFin AS datetime2(0)) AS FechaFin,

    CAST(p.FechaEntregaEstimada AS datetime2(0)) AS FechaEntregaEstimada,

    pi.Notas,
    pi.NotasOperativas,
    pi.InventarioAplicado,
    pi.EstaActivo,

    CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS datetime2(0)) AS FechaEnEstatus,

    CASE
      WHEN DATEDIFF(DAY,
        CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE),
        CAST(GETDATE() AS DATE)
      ) < 0 THEN 0
      ELSE DATEDIFF(DAY,
        CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE),
        CAST(GETDATE() AS DATE)
      )
    END AS DiasEnEstatus,

    CASE WHEN pes.Orden < @FinalOrden THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS EsWip,

    CASE
      WHEN p.FechaEntregaEstimada IS NOT NULL
       AND CAST(GETDATE() AS DATE) > CAST(p.FechaEntregaEstimada AS DATE)
       AND pes.Orden < @FinalOrden
      THEN CAST(1 AS bit)
      ELSE CAST(0 AS bit)
    END AS Atrasado,

    CASE
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) <= 1 THEN 0
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 2 AND 3 THEN 1
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 4 AND 7 THEN 2
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 8 AND 14 THEN 3
      ELSE 4
    END AS ColaBucketId,
    CASE
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) <= 1 THEN '0-1'
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 2 AND 3 THEN '2-3'
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 4 AND 7 THEN '4-7'
      WHEN DATEDIFF(DAY, CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE), CAST(GETDATE() AS DATE)) BETWEEN 8 AND 14 THEN '8-14'
      ELSE '15+'
    END AS ColaBucketNombre

  INTO #prod
  FROM dbo.TblProduccionItems pi
  INNER JOIN dbo.TblPedidos p ON p.PedidoId = pi.PedidoId
  INNER JOIN dbo.TblClientes cl ON cl.ClienteId = p.ClienteId
  INNER JOIN dbo.TblProductos pr ON pr.ProductoId = pi.ProductoId
  INNER JOIN dbo.TblProduccionEstatus pes ON pes.ProduccionEstatusId = pi.ProduccionEstatusId
  LEFT  JOIN dbo.TblImpresoras imp ON imp.ImpresoraId = pi.ImpresoraId
  LEFT  JOIN dbo.TblRecetas r ON r.RecetaId = pi.RecetaId
  OUTER APPLY (
    SELECT TOP (1)
      pb.Fecha AS UltimoMovimientoFecha
    FROM dbo.TblProduccionBitacora pb
    WHERE pb.ProduccionItemId = pi.ProduccionItemId
      AND pb.PedidoId = pi.PedidoId
      AND pb.PedidoItemId = pi.PedidoItemId
    ORDER BY pb.Fecha DESC, pb.ProduccionBitacoraId DESC
  ) lastMv
  WHERE
    p.EstaActivo = 1
    AND pi.EstaActivo = 1
    AND (@clienteId IS NULL OR p.ClienteId = @clienteId)
    AND (@pedidoId  IS NULL OR p.PedidoId  = @pedidoId)
    AND (@estatusId IS NULL OR pi.ProduccionEstatusId = @estatusId)
    AND (@impresoraId IS NULL OR pi.ImpresoraId = @impresoraId)
    AND (@sinImpresora = 0 OR pi.ImpresoraId IS NULL)
    AND (@desde IS NULL OR CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE) >= @desde)
    AND (@hasta IS NULL OR CAST(COALESCE(lastMv.UltimoMovimientoFecha, pi.FechaActualizacion, pi.FechaCreacion) AS DATE) <= @hasta)
    AND (@q IS NULL
         OR cl.Nombre LIKE '%' + @q + '%'
         OR pr.Nombre LIKE '%' + @q + '%'
         OR COALESCE(pi.Notas,'') LIKE '%' + @q + '%'
         OR COALESCE(pi.NotasOperativas,'') LIKE '%' + @q + '%'
         OR CAST(pi.PedidoId AS NVARCHAR(30)) LIKE '%' + @q + '%'
         OR CAST(pi.ProduccionItemId AS NVARCHAR(30)) LIKE '%' + @q + '%'
    );

  IF @soloWip = 1
    DELETE FROM #prod WHERE EsWip = 0;

  IF @soloAtrasados = 1
    DELETE FROM #prod WHERE Atrasado = 0;

  IF @minDiasCola IS NOT NULL
    DELETE FROM #prod WHERE DiasEnEstatus < @minDiasCola;

  -----------------------------------------------------------------------
  -- Resultset 1: KPIs / Totales
  -----------------------------------------------------------------------
  SELECT
    COUNT(1) AS Items,
    SUM(CASE WHEN EsWip = 1 THEN 1 ELSE 0 END) AS WipItems,
    SUM(CASE WHEN EsWip = 0 THEN 1 ELSE 0 END) AS FinalizadosItems,
    SUM(CASE WHEN ImpresoraId IS NULL THEN 1 ELSE 0 END) AS SinImpresora,
    SUM(CASE WHEN Atrasado = 1 THEN 1 ELSE 0 END) AS Atrasados,
    SUM(COALESCE(Cantidad,0)) AS CantidadTotal,
    SUM(COALESCE(PesoEstimadoGr,0)) AS PesoEstimadoTotalGr,
    SUM(COALESCE(PesoRealGr,0)) AS PesoRealTotalGr,
    AVG(CAST(DiasEnEstatus AS DECIMAL(18,2))) AS AvgDiasEnEstatus,
    MAX(DiasEnEstatus) AS MaxDiasEnEstatus
  FROM #prod;

  -----------------------------------------------------------------------
  -- Resultset 2: WIP por etapa (estatus)
  -----------------------------------------------------------------------
  SELECT
    ProduccionEstatusId,
    ProduccionEstatusNombre,
    ProduccionEstatusOrden,
    BadgeClass,
    COUNT(1) AS Items,
    SUM(COALESCE(Cantidad,0)) AS Cantidad,
    SUM(COALESCE(PesoEstimadoGr,0)) AS PesoEstimadoTotalGr,
    SUM(COALESCE(PesoRealGr,0)) AS PesoRealTotalGr,
    SUM(CASE WHEN Atrasado = 1 THEN 1 ELSE 0 END) AS Atrasados,
    AVG(CAST(DiasEnEstatus AS DECIMAL(18,2))) AS AvgDiasEnEstatus,
    MAX(DiasEnEstatus) AS MaxDiasEnEstatus
  FROM #prod
  GROUP BY ProduccionEstatusId, ProduccionEstatusNombre, ProduccionEstatusOrden, BadgeClass
  ORDER BY ProduccionEstatusOrden;

  -----------------------------------------------------------------------
  -- Resultset 3: Items por impresora
  -----------------------------------------------------------------------
  SELECT
    ImpresoraId,
    COALESCE(ImpresoraNombre, '(Sin impresora)') AS ImpresoraNombre,
    ImpresoraModelo,
    COUNT(1) AS Items,
    SUM(COALESCE(Cantidad,0)) AS Cantidad,
    SUM(CASE WHEN EsWip = 1 THEN 1 ELSE 0 END) AS WipItems,
    SUM(CASE WHEN Atrasado = 1 THEN 1 ELSE 0 END) AS Atrasados,
    AVG(CAST(DiasEnEstatus AS DECIMAL(18,2))) AS AvgDiasEnEstatus,
    MAX(DiasEnEstatus) AS MaxDiasEnEstatus
  FROM #prod
  GROUP BY ImpresoraId, ImpresoraNombre, ImpresoraModelo
  ORDER BY
    CASE WHEN ImpresoraId IS NULL THEN 1 ELSE 0 END,
    Items DESC;

  -----------------------------------------------------------------------
  -- Resultset 4: Pendientes por antigüedad (buckets de cola)
  -----------------------------------------------------------------------
  SELECT
    ColaBucketId,
    ColaBucketNombre,
    COUNT(1) AS Items,
    SUM(COALESCE(Cantidad,0)) AS Cantidad,
    SUM(CASE WHEN Atrasado = 1 THEN 1 ELSE 0 END) AS Atrasados,
    AVG(CAST(DiasEnEstatus AS DECIMAL(18,2))) AS AvgDiasEnEstatus,
    MAX(DiasEnEstatus) AS MaxDiasEnEstatus
  FROM #prod
  WHERE EsWip = 1
  GROUP BY ColaBucketId, ColaBucketNombre
  ORDER BY ColaBucketId;

  -----------------------------------------------------------------------
  -- Resultset 5: Detalle (para la tabla)
  -----------------------------------------------------------------------
  SELECT
    ProduccionItemId,
    PedidoId,
    PedidoItemId,
    ClienteId,
    ClienteNombre,
    ProductoId,
    ProductoNombre,
    Cantidad,

    ProduccionEstatusId,
    ProduccionEstatusNombre,
    ProduccionEstatusOrden,
    BadgeClass,

    ImpresoraId,
    ImpresoraNombre,
    ImpresoraModelo,

    RecetaId,
    RecetaNombre,

    FechaCreacion,
    FechaEnEstatus,
    DiasEnEstatus,
    FechaInicio,
    FechaFin,
    FechaEntregaEstimada,

    EsWip,
    Atrasado,
    ColaBucketId,
    ColaBucketNombre,

    PesoEstimadoGr,
    PesoRealGr,

    InventarioAplicado,
    Notas,
    NotasOperativas
  FROM #prod
  ORDER BY
    CASE WHEN Atrasado = 1 THEN 0 ELSE 1 END,
    DiasEnEstatus DESC,
    ProduccionEstatusOrden,
    ProduccionItemId DESC;

  -----------------------------------------------------------------------
  -- Resultset 6: Dropdown estatus
  -----------------------------------------------------------------------
  SELECT
    ProduccionEstatusId AS Id,
    Nombre,
    Orden,
    BadgeClass
  FROM dbo.TblProduccionEstatus
  WHERE EstaActivo = 1
  ORDER BY Orden;

  -----------------------------------------------------------------------
  -- Resultset 7: Dropdown impresoras (global)
  -----------------------------------------------------------------------
  SELECT
    ImpresoraId AS Id,
    Nombre,
    Modelo
  FROM dbo.TblImpresoras
  WHERE EstaActivo = 1
  ORDER BY Nombre;

  -----------------------------------------------------------------------
  -- Resultset 8: Dropdown clientes (global)
  -----------------------------------------------------------------------
  SELECT
    ClienteId AS Id,
    Nombre
  FROM dbo.TblClientes
  WHERE EstaActivo = 1
  ORDER BY Nombre;

END
GO


/* =========================================================
   9) SP: ACTUALIZAR TARIFA (por TarifaId)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasActualizar
    @TarifaId INT,
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @Nombre NVARCHAR(80) = NULL,
    @Orden INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SET @Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN');

        DECLARE @chg TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            OrdenDespues INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET
            Monto = @Monto,
            Moneda = @Moneda,
            Nombre = COALESCE(@Nombre, t.Nombre),
            Orden  = COALESCE(@Orden, t.Orden),
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            inserted.Nombre,
            deleted.Orden,
            inserted.Orden,
            deleted.Monto,
            deleted.Moneda,
            inserted.Monto,
            inserted.Moneda,
            deleted.EstaActivo,
            inserted.EstaActivo
        INTO @chg
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @chg)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            'UPDATE',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @chg;

        SELECT 'success' AS result, 'Tarifa actualizada.' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


/* =========================================================
   8) SP: DIAGNÓSTICO (SIN VIGENCIAS)
      - Solo devuelve conceptos que NO tienen tarifa global (sin scope)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasDiagnostico
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH conceptos AS (
        SELECT TarifaConceptoId, Codigo, Nombre
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE EstaActivo = 1
    ),
    existentes_global AS (
        SELECT TarifaConceptoId
        FROM dbo.TblTarifas WITH (NOLOCK)
        WHERE EstaActivo = 1
          AND ImpresoraId IS NULL
          AND InventarioId IS NULL
    )
    SELECT
        c.Codigo,
        c.Nombre,
        CASE WHEN eg.TarifaConceptoId IS NULL THEN 1 ELSE 0 END AS FaltaTarifaGlobal
    FROM conceptos c
    LEFT JOIN existentes_global eg
        ON eg.TarifaConceptoId = c.TarifaConceptoId
    WHERE eg.TarifaConceptoId IS NULL
    ORDER BY c.Codigo;
END
GO


/* =========================================================
   6) SP: ELIMINACIÓN LÓGICA + LOG
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasEliminar
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @del TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenDespues INT NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET EstaActivo = 0,
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            deleted.Orden,
            deleted.Monto,
            deleted.Moneda,
            deleted.EstaActivo,
            inserted.Nombre,
            inserted.Orden,
            inserted.Monto,
            inserted.Moneda,
            inserted.EstaActivo
        INTO @del
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @del)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            'DELETE_LOGICO',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @del;

        SELECT 'success' AS result, 'Tarifa eliminada (lógica).' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


/* =========================================================
   5) SP: OBTENER TARIFA (PRIORIDAD POR ESPECIFICIDAD)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtener
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


/* =========================================================
   13) SP: OBTENER TARIFAS APLICABLES (para cálculo + desglose)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerAplicables
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


/* =========================================================
   2) SP: LISTAR CONCEPTOS
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerConceptos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TarifaConceptoId, Codigo, Nombre, Unidad, Orden
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE EstaActivo = 1
    ORDER BY Orden ASC, Nombre ASC;
END
GO


/* =========================================================
   7) SP: HISTÓRICO POR TARIFA
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP(200)
        l.TarifaLogId,
        l.Accion,

        l.ImpresoraId,
        l.InventarioId,

        l.NombreAntes, l.NombreDespues,
        l.OrdenAntes,  l.OrdenDespues,

        l.MontoAntes, l.MonedaAntes,
        l.MontoDespues, l.MonedaDespues,

        l.EstaActivoAntes, l.EstaActivoDespues,
        l.FechaAccion
    FROM dbo.TblTarifasLog l WITH (NOLOCK)
    WHERE l.TarifaId = @TarifaId
    ORDER BY l.FechaAccion DESC, l.TarifaLogId DESC;
END
GO


CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorImpresora
    @ImpresoraId INT,
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
        t.InventarioId, -- agrega para poder detectar globales en UI
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio,
        CAST(CASE WHEN t.InventarioId IS NULL AND t.ImpresoraId IS NULL THEN 1 ELSE 0 END AS BIT) AS EsGlobal
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.EstaActivo = 1
      AND c.EstaActivo = 1
      AND (
            (t.ImpresoraId = @ImpresoraId AND t.InventarioId IS NULL)
            OR (t.ImpresoraId IS NULL AND t.InventarioId IS NULL AND c.Codigo = 'MATERIAL_GENERAL_PRN_GLOBAL')
      )
    ORDER BY
        EsGlobal DESC,
        c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO


CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorInventario
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


/* =========================================================
   3) SP: LISTAR TARIFAS ACTIVAS (global)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorUsuario
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


CREATE OR ALTER PROCEDURE dbo.procTarifasSet
    @TarifaConceptoCodigo VARCHAR(40),
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @Nombre NVARCHAR(80) = N'',
    @Orden INT = 100,
    @ImpresoraId INT = NULL,
    @InventarioId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TarifaConceptoId INT;
    DECLARE @TarifaId INT;

    BEGIN TRY
        SET @TarifaConceptoCodigo = UPPER(LTRIM(RTRIM(ISNULL(@TarifaConceptoCodigo,''))));
        SET @Moneda = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN'));
        SET @Nombre = ISNULL(@Nombre, N'');
        SET @Orden  = ISNULL(@Orden, 100);

        IF (@TarifaConceptoCodigo = '')
            RAISERROR('Concepto de tarifa inválido (vacío).',16,1);

        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SELECT @TarifaConceptoId = TarifaConceptoId
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

        IF @TarifaConceptoId IS NULL
            RAISERROR('Concepto de tarifa inválido o inactivo.',16,1);

        IF (@InventarioId IS NOT NULL AND @ImpresoraId IS NOT NULL)
            RAISERROR('Scope inválido: no se permite ImpresoraId e InventarioId a la vez.',16,1);

        IF (@TarifaConceptoCodigo = 'MATERIAL_UNIT' AND @InventarioId IS NULL)
            RAISERROR('MATERIAL_UNIT requiere InventarioId.',16,1);

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL')
        BEGIN
            IF (@InventarioId IS NULL AND @ImpresoraId IS NULL)
                RAISERROR('MATERIAL_GENERAL requiere InventarioId o ImpresoraId (uno).',16,1);
        END

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL_INV_GLOBAL')
        BEGIN
            SET @InventarioId = NULL;
            SET @ImpresoraId = NULL;
        END

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL_PRN_GLOBAL')
        BEGIN
            SET @InventarioId = NULL;
            SET @ImpresoraId = NULL;
        END

        INSERT dbo.TblTarifas(
            UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            InventarioTipoId, InventarioNombreId,
            Nombre, Orden,
            Monto, Moneda,
            EstaActivo
        )
        VALUES(
            @loginId, @TarifaConceptoId,
            @ImpresoraId, @InventarioId,
            NULL, NULL,
            @Nombre, @Orden,
            @Monto, @Moneda,
            1
        );

        SET @TarifaId = SCOPE_IDENTITY();

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            InventarioTipoId, InventarioNombreId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        VALUES(
            @TarifaId, @loginId, @TarifaConceptoId,
            @ImpresoraId, @InventarioId,
            NULL, NULL,
            'INSERT',
            NULL, @Nombre,
            NULL, @Orden,
            NULL, NULL,
            @Monto, @Moneda,
            NULL, 1
        );

        SELECT 'success' AS result, 'Tarifa creada.' AS message, @TarifaId AS TarifaId;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message, NULL AS TarifaId;
    END CATCH
END
GO


/* ============================================================================
   SP: procUpdateTransaccionesCompra
   - Devuelve INT: TransaccionCompraId
============================================================================ */
CREATE OR ALTER PROCEDURE dbo.procUpdateTransaccionesCompra
    @CompraId      INT,
    @UsuarioId     INT = 0,
    @loginId       INT = 0,
    @Descripcion   NVARCHAR(300) = NULL,
    @InventarioId  INT = NULL,
    @Cantidad      DECIMAL(18,4) = 0,
    @CostoUnitario DECIMAL(18,4) = 0,
    @CostoTotal    DECIMAL(18,4) = 0,
    @FechaCreacion DATE = NULL,

    @Crear         BIT = 0,
    @Actualizar    BIT = 0,
    @Borrar        BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @uid INT = CASE WHEN ISNULL(@UsuarioId,0) > 0 THEN @UsuarioId ELSE ISNULL(@loginId,0) END;
    IF (@uid <= 0)
    BEGIN
        RAISERROR('UsuarioId/loginId requerido.', 16, 1);
        RETURN;
    END

    IF (@CompraId IS NULL OR @CompraId <= 0)
    BEGIN
        RAISERROR('CompraId inválido.', 16, 1);
        RETURN;
    END

    IF (@FechaCreacion IS NULL)
        SET @FechaCreacion = CAST(GETDATE() AS DATE);

    DECLARE @op VARCHAR(20) =
        CASE
            WHEN ISNULL(@Borrar,0) = 1 THEN 'BORRAR'
            WHEN ISNULL(@Actualizar,0) = 1 THEN 'ACTUALIZAR'
            ELSE 'CREAR'
        END;

    INSERT INTO dbo.TblTransaccionesCompras
    (
        CompraId, UsuarioId, Operacion, Descripcion, InventarioId,
        Cantidad, CostoUnitario, CostoTotal, FechaCompra
    )
    VALUES
    (
        @CompraId, @uid, @op, @Descripcion, @InventarioId,
        ISNULL(@Cantidad,0), ISNULL(@CostoUnitario,0), ISNULL(@CostoTotal,0), @FechaCreacion
    );

    SELECT CAST(SCOPE_IDENTITY() AS INT);
END
GO
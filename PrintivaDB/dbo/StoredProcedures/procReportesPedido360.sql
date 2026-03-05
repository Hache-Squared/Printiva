CREATE   PROCEDURE dbo.procReportesPedido360
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
      CONCAT( ISNULL(cl.Nombre, ''), ' ', ISNULL(cl.ApellidoPaterno, ''), ' ', ISNULL(cl.ApellidoMaterno, '')) AS ClienteNombre,
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


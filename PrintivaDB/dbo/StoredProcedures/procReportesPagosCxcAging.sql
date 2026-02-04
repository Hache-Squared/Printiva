CREATE   PROCEDURE dbo.procReportesPagosCxcAging
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

    WHERE p.UsuarioId = @loginId
      AND p.EstaActivo = 1
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


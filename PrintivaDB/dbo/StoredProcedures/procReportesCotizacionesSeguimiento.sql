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
      CONCAT(ISNULL(cl.Nombre, ''), ' ', ISNULL(cl.ApellidoPaterno, ''), ' ', ISNULL(cl.ApellidoMaterno, '')) AS ClienteNombre,

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

    CASE
      WHEN @EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId
        THEN 'Aceptada'
      WHEN (@EstatusRechazadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusRechazadaId)
        OR (@EstatusCanceladaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusCanceladaId)
        THEN 'Rechazada'
      ELSE 'Pendiente'
    END AS Categoria,

    CASE
      WHEN (@EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId)
        OR COALESCE(note.TotalPagado, 0) > 0
        OR COALESCE(prod.ProduccionItems, 0) > 0
      THEN CAST(1 AS bit)
      ELSE CAST(0 AS bit)
    END AS Convertida,

    CAST(
      COALESCE(
        note.PrimerPagoFecha,
        prod.PrimerProduccionFecha,
        CASE
          WHEN (@EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId)
          THEN b.CotizacionFechaCreacion
        END
      ) AS datetime2(0)
    ) AS FechaConversion,

    CASE
      WHEN COALESCE(
            note.PrimerPagoFecha,
            prod.PrimerProduccionFecha,
            CASE
              WHEN (@EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId)
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
                WHEN (@EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId)
                THEN b.CotizacionFechaCreacion
              END
            ) AS DATE)
          )
      ELSE NULL
    END AS DiasAConversion

  INTO #filtered
  FROM base b
  OUTER APPLY (
    SELECT
      CAST(
        COALESCE(SUM(ci.Cantidad * ci.PrecioUnitario), 0)
        + ROUND(COALESCE(SUM(ci.Cantidad * ci.PrecioUnitario), 0) * 0.16, 2)
      AS DECIMAL(18,2)) AS MontoCotizacion
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
      pa.Metodo AS UltimoPagoMetodo,
      pa.Referencia AS UltimoPagoReferencia,
      pt.Nombre AS UltimoPagoTipoNombre
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
        (@EstatusAceptadaId IS NOT NULL AND b.CotizacionEstatusId = @EstatusAceptadaId)
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

  SELECT
    c.ClienteId AS Id,
    CONCAT(ISNULL(c.Nombre, ''), ' ', ISNULL(c.ApellidoPaterno, ''), ' ', ISNULL(c.ApellidoMaterno, '')) AS Nombre
  FROM dbo.TblClientes c
  WHERE EstaActivo = 1
  ORDER BY Nombre;

  SELECT
    CotizacionEstatusId AS Id,
    Nombre
  FROM dbo.TblCotizacionesEstatus
  ORDER BY Nombre;
END
GO
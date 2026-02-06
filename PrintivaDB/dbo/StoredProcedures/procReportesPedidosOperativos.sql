CREATE   PROCEDURE dbo.procReportesPedidosOperativos
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


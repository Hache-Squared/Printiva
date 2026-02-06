CREATE   PROCEDURE dbo.procReportesProduccionWipDashboard
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


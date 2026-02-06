CREATE   PROCEDURE dbo.procReportesProduccionUtilizacionImpresoras
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


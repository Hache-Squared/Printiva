CREATE OR ALTER PROCEDURE dbo.procObtenerPedidosKanban
    @loginId INT,
    @ClienteId INT = 0,
    @q VARCHAR(200) = '',
    @SoloPendientes BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AceptadaId INT = (
        SELECT TOP 1 CotizacionEstatusId
        FROM dbo.TblCotizacionesEstatus WITH (NOLOCK)
        WHERE Nombre = 'Aceptada'
    );

    ;WITH Cot AS (
        SELECT
            c.PedidoId,
            c.CotizacionId,
            c.CotizacionEstatusId,
            ce.Nombre AS CotizacionEstatusNombre,
            ROW_NUMBER() OVER (PARTITION BY c.PedidoId ORDER BY c.CotizacionId DESC) AS rn
        FROM dbo.TblCotizaciones c WITH (NOLOCK)
        INNER JOIN dbo.TblCotizacionesEstatus ce WITH (NOLOCK)
            ON ce.CotizacionEstatusId = c.CotizacionEstatusId
        WHERE ISNULL(c.EstaActivo, 1) = 1
    ),
    Cot1 AS (
        SELECT * FROM Cot WHERE rn = 1
    ),
    TotCot AS (
        SELECT
            ci.CotizacionId,
            SUM(ISNULL(ci.Cantidad,0) * ISNULL(ci.PrecioUnitario,0)) AS TotalCotizado
        FROM dbo.TblCotizacionItems ci WITH (NOLOCK)
        WHERE ISNULL(ci.EstaActivo, 1) = 1
        GROUP BY ci.CotizacionId
    ),
    TotPago AS (
        SELECT
            p.CotizacionId,
            SUM(ISNULL(p.Monto,0)) AS TotalPagado
        FROM dbo.TblPagos p WITH (NOLOCK)
        WHERE ISNULL(p.EstaActivo, 1) = 1
        GROUP BY p.CotizacionId
    )
    SELECT
        p.PedidoId,
        p.UsuarioId,
        p.ClienteId,
        c.Nombre AS ClienteNombre,
        p.PedidoEstatusId,
        e.Nombre AS EstatusNombre,
        p.FechaCreacion,
        p.FechaEntregaEstimada,
        p.Notas,
        p.TotalEstimado,

        ISNULL(c1.CotizacionId, 0) AS CotizacionId,
        ISNULL(c1.CotizacionEstatusNombre, '') AS CotizacionEstatusNombre,
        CASE WHEN c1.CotizacionId IS NULL THEN 0 ELSE 1 END AS TieneCotizacion,
        CASE WHEN c1.CotizacionEstatusId = @AceptadaId THEN 1 ELSE 0 END AS CotizacionAceptada,

        ISNULL(tc.TotalCotizado, 0) AS TotalCotizado,
        ISNULL(tp.TotalPagado, 0) AS TotalPagado,
        ISNULL(tc.TotalCotizado, 0) - ISNULL(tp.TotalPagado, 0) AS Saldo
    FROM dbo.TblPedidos p WITH (NOLOCK)
    INNER JOIN dbo.TblClientes c WITH (NOLOCK) ON c.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus e WITH (NOLOCK) ON e.PedidoEstatusId = p.PedidoEstatusId
    LEFT JOIN Cot1 c1 ON c1.PedidoId = p.PedidoId
    LEFT JOIN TotCot tc ON tc.CotizacionId = c1.CotizacionId
    LEFT JOIN TotPago tp ON tp.CotizacionId = c1.CotizacionId
    WHERE p.UsuarioId = @loginId
      AND (@ClienteId = 0 OR p.ClienteId = @ClienteId)
      AND (
            ISNULL(@q,'') = ''
            OR c.Nombre LIKE '%' + @q + '%'
            OR p.Notas LIKE '%' + @q + '%'
            OR CAST(p.PedidoId AS VARCHAR(20)) = @q
      )
      AND (
            @SoloPendientes = 0
            OR (ISNULL(tc.TotalCotizado,0) - ISNULL(tp.TotalPagado,0)) > 0
      )
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END

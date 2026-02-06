CREATE   PROCEDURE dbo.procProduccionObtenerConsumosAplicadosPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pi WITH (NOLOCK)
        WHERE pi.ProduccionItemId=@ProduccionItemId
          AND pi.EstaActivo=1
    )
    BEGIN
        -- Devuelve vacío para no romper UI
        SELECT TOP 0
            CAST(0 AS INT) AS InventarioId,
            CAST(0 AS DECIMAL(18,4)) AS CantidadUsada;
        RETURN;
    END

    SELECT
        c.InventarioId,
        CAST(SUM(c.Cantidad) AS DECIMAL(18,4)) AS CantidadUsada
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    WHERE c.ProduccionItemId=@ProduccionItemId
    GROUP BY c.InventarioId;
END
GO


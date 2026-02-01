CREATE   PROCEDURE dbo.procProduccionRecetasDisponiblesPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pr (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.UsuarioId=@loginId
          AND pr.EstaActivo=1
    )
    BEGIN
        SELECT TOP 0
            0 AS RecetaId,
            '' AS Nombre,
            '' AS TiempoImpresion,
            CAST(0 AS BIT) AS IsSelected;
        RETURN;
    END

    DECLARE @ProductoId INT = (SELECT ProductoId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);
    DECLARE @SelectedId INT = (SELECT RecetaId  FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

    SELECT
        r.RecetaId,
        r.Nombre,
        r.TiempoImpresion,
        CAST(CASE WHEN r.RecetaId = @SelectedId THEN 1 ELSE 0 END AS BIT) AS IsSelected
    FROM dbo.TblRecetas r (NOLOCK)
    WHERE r.ProductoId = @ProductoId
      AND r.EstaActivo = 1
    ORDER BY r.RecetaId DESC;
END
GO


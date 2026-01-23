CREATE OR ALTER PROCEDURE dbo.procProduccionAccionesDisponibles
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblProduccionItems pr (NOLOCK) WHERE pr.ProduccionItemId=@ProduccionItemId AND pr.UsuarioId=@loginId AND pr.EstaActivo=1)
    BEGIN
        SELECT TOP 0
            'mover' AS AccionCodigo,
            '' AS AccionTexto,
            0 AS HaciaEstatusId,
            CAST(0 AS BIT) AS RequiereConfirmacion,
            CAST(0 AS BIT) AS Bloqueada,
            '' AS Motivo;
        RETURN;
    END

    DECLARE @DesdeId INT = (SELECT ProduccionEstatusId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

    SELECT
        'mover' AS AccionCodigo,
        CONCAT('Mover a: ', pe.Nombre) AS AccionTexto,
        t.HaciaEstatusId,
        CAST(CASE WHEN pe.Nombre = N'Entregado' THEN 1 ELSE 0 END AS BIT) AS RequiereConfirmacion,
        CAST(0 AS BIT) AS Bloqueada,
        '' AS Motivo
    FROM dbo.TblProduccionEstatusTransiciones t (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK) ON pe.ProduccionEstatusId = t.HaciaEstatusId
    WHERE t.DesdeEstatusId = @DesdeId
      AND pe.EstaActivo = 1
    ORDER BY pe.Orden ASC;
END
GO

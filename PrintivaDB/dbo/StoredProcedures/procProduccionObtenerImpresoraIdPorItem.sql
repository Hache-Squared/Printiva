CREATE   PROCEDURE dbo.procProduccionObtenerImpresoraIdPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        pr.ImpresoraId
    FROM dbo.TblProduccionItems pr WITH (NOLOCK)
    WHERE pr.ProduccionItemId = @ProduccionItemId
      AND pr.EstaActivo = 1;
END
GO


CREATE   PROCEDURE dbo.procProduccionInitPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = 'Producción inicializada.';
    DECLARE @elementoId INT = @PedidoId;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            THROW 50000, 'Usuario no encontrado.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND ISNULL(p.EstaActivo,1)=1)
            THROW 50000, 'Pedido no encontrado.', 1;

        DECLARE @Now DATETIME2(0) = CAST(SYSDATETIME() AS DATETIME2(0));

        DECLARE @EnProdId INT =
            (SELECT TOP 1 ProduccionEstatusId
             FROM dbo.TblProduccionEstatus (NOLOCK)
             WHERE EstaActivo=1 AND Nombre=N'En producción'
             ORDER BY Orden ASC);

        IF @EnProdId IS NULL
            SET @EnProdId = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus (NOLOCK) WHERE EstaActivo=1 ORDER BY Orden ASC);

        /* Inserta solo los faltantes */
        INSERT INTO dbo.TblProduccionItems
            (PedidoId, PedidoItemId, UsuarioId, ProductoId, Cantidad, ProduccionEstatusId, FechaInicio)
        SELECT
            pi.PedidoId,
            pi.PedidoItemId,
            p.UsuarioId,
            pi.ProductoId,
            pi.Cantidad,
            @EnProdId,
            -- si nace en En producción, arranca timer
            @Now
        FROM dbo.TblPedidoItems pi (NOLOCK)
        INNER JOIN dbo.TblPedidos p (NOLOCK) ON p.PedidoId = pi.PedidoId
        LEFT JOIN dbo.TblProduccionItems pr (NOLOCK) ON pr.PedidoItemId = pi.PedidoItemId
        WHERE pi.PedidoId = @PedidoId
          AND pr.ProduccionItemId IS NULL;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


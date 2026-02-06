CREATE   PROCEDURE dbo.procProduccionAsignarRecetaItem
    @ProduccionItemId INT,
    @RecetaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20)='success';
    DECLARE @message VARCHAR(MAX)='Receta asignada.';
    DECLARE @elementoId INT = ISNULL(@ProduccionItemId,0);

    BEGIN TRY
        DECLARE @ProductoId INT;
        DECLARE @InvAplicado BIT;

        SELECT
            @ProductoId = pr.ProductoId,
            @InvAplicado = pr.InventarioAplicado
        FROM dbo.TblProduccionItems pr WITH (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.EstaActivo=1;

        IF @ProductoId IS NULL
            THROW 50000, 'Item de producción no encontrado.', 1;

        IF ISNULL(@InvAplicado,0)=1
            THROW 50000, 'No puedes cambiar receta: inventario ya aplicado (Post-procesado).', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblRecetas r WITH (NOLOCK)
            WHERE r.RecetaId=@RecetaId
              AND r.ProductoId=@ProductoId
              AND r.EstaActivo=1
        )
            THROW 50000, 'Receta inválida o no activa para este producto.', 1;

        UPDATE dbo.TblProduccionItems
           SET RecetaId = @RecetaId,
               FechaActualizacion = SYSDATETIME()
        WHERE ProduccionItemId=@ProduccionItemId;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result='fail';
        SET @message=CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


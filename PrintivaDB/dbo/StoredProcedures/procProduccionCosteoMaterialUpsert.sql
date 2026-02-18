CREATE   PROCEDURE dbo.procProduccionCosteoMaterialUpsert
    @ProduccionItemId INT,
    @Moneda VARCHAR(3),
    @Total DECIMAL(18,4),
    @DetallesJson NVARCHAR(MAX),
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20)='success';
    DECLARE @message VARCHAR(MAX)='Costeo guardado.';
    DECLARE @costeoId INT;

    BEGIN TRY
        IF (@ProduccionItemId <= 0) THROW 50000, 'ProduccionItemId inválido.', 1;
        IF (@Moneda IS NULL OR LEN(@Moneda) <> 3) THROW 50000, 'Moneda inválida.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblProduccionItems pi WITH (NOLOCK)
            WHERE pi.ProduccionItemId=@ProduccionItemId
              AND pi.EstaActivo=1
        )
            THROW 50000, 'Item de producción no encontrado.', 1;

        BEGIN TRAN;

        -- Upsert header (único por item+tipo)
        SELECT TOP (1) @costeoId = ProduccionCosteoId
        FROM dbo.TblProduccionCosteos WITH (UPDLOCK, HOLDLOCK)
        WHERE ProduccionItemId=@ProduccionItemId
          AND TipoCodigo='MATERIAL'
          AND EstaActivo=1
        ORDER BY Fecha DESC, ProduccionCosteoId DESC;

        IF (@costeoId IS NULL)
        BEGIN
            INSERT INTO dbo.TblProduccionCosteos(ProduccionItemId, UsuarioId, TipoCodigo, Moneda, Total)
            VALUES (@ProduccionItemId, @loginId, 'MATERIAL', @Moneda, @Total);

            SET @costeoId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.TblProduccionCosteos
               SET Moneda=@Moneda,
                   Total=@Total,
                   Fecha=GETUTCDATE()
            WHERE ProduccionCosteoId=@costeoId;
        END

        -- Reemplazar detalle (idempotente)
        DELETE FROM dbo.TblProduccionCosteosDetalle
        WHERE ProduccionCosteoId=@costeoId;

        IF (ISNULL(@DetallesJson,'') <> '')
        BEGIN
            INSERT INTO dbo.TblProduccionCosteosDetalle
            (
                ProduccionCosteoId, ConceptoCodigo, InventarioId, ImpresoraId,
                TarifaId, TarifaNombre, TarifaOrden,
                MontoTarifa, Cantidad, Subtotal, Moneda
            )
            SELECT
                @costeoId,
                j.ConceptoCodigo,
                j.InventarioId,
                j.ImpresoraId,
                j.TarifaId,
                j.TarifaNombre,
                j.TarifaOrden,
                j.MontoTarifa,
                j.Cantidad,
                j.Subtotal,
                j.Moneda
            FROM OPENJSON(@DetallesJson)
            WITH
            (
                ConceptoCodigo VARCHAR(50) '$.ConceptoCodigo',
                InventarioId INT '$.InventarioId',
                ImpresoraId INT '$.ImpresoraId',
                TarifaId INT '$.TarifaId',
                TarifaNombre NVARCHAR(200) '$.TarifaNombre',
                TarifaOrden INT '$.TarifaOrden',
                MontoTarifa DECIMAL(18,4) '$.MontoTarifa',
                Cantidad DECIMAL(18,4) '$.Cantidad',
                Subtotal DECIMAL(18,4) '$.Subtotal',
                Moneda VARCHAR(3) '$.Moneda'
            ) j;
        END

        COMMIT;

        SELECT @result [result], @message [message], @costeoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @result='fail';
        SET @message=CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], NULL [elementoId];
    END CATCH
END
GO


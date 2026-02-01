CREATE OR ALTER PROCEDURE dbo.procProduccionActualizarItemDatos
    @ProduccionItemId INT,
    @ImpresoraId INT = NULL,
    @NotasOperativas NVARCHAR(500) = NULL,
    @PesoEstimadoGr DECIMAL(10,2) = NULL,
    @PesoRealGr DECIMAL(10,2) = NULL,
    @FechaInicio DATETIME2(0) = NULL,
    @FechaFin DATETIME2(0) = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ProduccionItemId, 0);

    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        -- El item debe pertenecer a un pedido del usuario
        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblPedidos ped (NOLOCK) ON ped.PedidoId = pr.PedidoId
            WHERE pr.ProduccionItemId = @ProduccionItemId
              AND ped.UsuarioId = @loginId
              AND ISNULL(pr.EstaActivo,1)=1
        )
            RAISERROR('Item de producción no encontrado.', 16, 1);

        -- Si mandan impresora, valida que exista, sea del usuario y esté activa
        IF @ImpresoraId IS NOT NULL
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ImpresoraId
                  AND i.UsuarioId = @loginId
                  AND i.EstaActivo = 1
            )
                RAISERROR('Impresora inválida o inactiva.', 16, 1);
        END

        UPDATE dbo.TblProduccionItems
           SET ImpresoraId     = @ImpresoraId,
               NotasOperativas = NULLIF(@NotasOperativas,''),
               PesoEstimadoGr  = @PesoEstimadoGr,
               PesoRealGr      = @PesoRealGr,
               FechaInicio     = @FechaInicio,
               FechaFin        = @FechaFin,
               FechaActualizacion = SYSDATETIME()
        WHERE ProduccionItemId = @ProduccionItemId;

        SET @message = 'Datos de producción guardados.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

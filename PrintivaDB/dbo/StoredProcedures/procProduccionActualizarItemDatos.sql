CREATE   PROCEDURE dbo.procProduccionActualizarItemDatos
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

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblPedidos ped (NOLOCK) ON ped.PedidoId = pr.PedidoId
            WHERE pr.ProduccionItemId = @ProduccionItemId
              AND ISNULL(pr.EstaActivo,1)=1
        )
            RAISERROR('Item de producción no encontrado.', 16, 1);

        IF @ImpresoraId IS NOT NULL
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ImpresoraId
                  AND i.EstaActivo = 1
            )
                RAISERROR('Impresora inválida o inactiva.', 16, 1);
        END

        DECLARE @Now DATETIME2(0) = CAST(GETUTCDATE() AS DATETIME2(0));

        DECLARE @EnProdId INT =
        (
            SELECT TOP 1 ProduccionEstatusId
            FROM dbo.TblProduccionEstatus (NOLOCK)
            WHERE EstaActivo=1 AND Nombre=N'En producción'
            ORDER BY Orden ASC
        );

        DECLARE @PostId INT =
        (
            SELECT TOP 1 ProduccionEstatusId
            FROM dbo.TblProduccionEstatus WITH (NOLOCK)
            WHERE EstaActivo=1 AND (
                   Nombre = N'Post-procesado'
                OR Nombre = N'Post-proceso'
                OR Nombre = N'Post Procesado'
                OR Nombre LIKE N'Post%'
            )
            ORDER BY Orden ASC
        );

        UPDATE pi
           SET ImpresoraId     = @ImpresoraId,
               NotasOperativas = NULLIF(@NotasOperativas,''),
               PesoEstimadoGr  = @PesoEstimadoGr,
               PesoRealGr      = @PesoRealGr,

               -- FECHAS: NO borres si vienen NULL
               -- y si está En producción y aún no hay inicio, arráncalo
               FechaInicio = CASE
                                WHEN @FechaInicio IS NOT NULL THEN @FechaInicio
                                WHEN pi.FechaInicio IS NULL AND @EnProdId IS NOT NULL AND pi.ProduccionEstatusId = @EnProdId THEN @Now
                                ELSE pi.FechaInicio
                            END,

               -- FECHA FIN: solo se setea si la mandan; o si está Post y no hay fin (fallback)
               FechaFin = CASE
                            WHEN @FechaFin IS NOT NULL THEN @FechaFin
                            WHEN pi.FechaFin IS NULL AND @PostId IS NOT NULL AND pi.ProduccionEstatusId = @PostId THEN @Now
                            ELSE pi.FechaFin
                         END,

               FechaActualizacion = GETUTCDATE()
        FROM dbo.TblProduccionItems pi
        WHERE pi.ProduccionItemId = @ProduccionItemId
          AND pi.EstaActivo = 1;

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


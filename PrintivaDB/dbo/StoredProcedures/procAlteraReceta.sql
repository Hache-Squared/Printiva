/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Description: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Description     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE   PROCEDURE dbo.procAlteraReceta
@ElementoAlterarId  INT = 0,
@Nombre             VARCHAR(200) = '',
@TiempoImpresion    VARCHAR(200) = NULL,   -- legacy
@TiempoImpresionMin INT = NULL,            -- nuevo
@TiempoPostMin      INT = NULL,            -- nuevo
@ProductoId         INT = 0,
@loginId            INT = 0,
@Actualizar         BIT = 0,
@Borrar             BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result  VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF (ISNULL(@Borrar,0) = 0)
        BEGIN
            IF (ISNULL(@Nombre,'') = '')
                RAISERROR('Nombre no puede ser vacío.',16,1);

            SET @TiempoImpresionMin = ISNULL(@TiempoImpresionMin, 0);
            SET @TiempoPostMin      = ISNULL(@TiempoPostMin, 0);

            IF (@TiempoImpresionMin < 0) RAISERROR('TiempoImpresionMin debe ser >= 0.',16,1);
            IF (@TiempoPostMin < 0)      RAISERROR('TiempoPostMin debe ser >= 0.',16,1);
        END

        IF EXISTS (SELECT 1 FROM dbo.TblRecetas r (NOLOCK) WHERE r.RecetaId = @elementoId)
        BEGIN
            IF (ISNULL(@Actualizar,0) = 1)
            BEGIN
                UPDATE dbo.TblRecetas
                SET Nombre = @Nombre,
                    ProductoId = @ProductoId,
                    TiempoImpresion = COALESCE(NULLIF(@TiempoImpresion,''), TiempoImpresion),
                    TiempoImpresionMin = @TiempoImpresionMin,
                    TiempoPostMin = @TiempoPostMin,
                    EstaActivo = 1
                WHERE RecetaId = @elementoId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar,0) = 1)
            BEGIN
                UPDATE dbo.TblRecetasInventarios SET EstaActivo = 0 WHERE RecetaId = @elementoId;
                UPDATE dbo.TblRecetas SET EstaActivo = 0 WHERE RecetaId = @elementoId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.TblRecetas r (NOLOCK) WHERE r.Nombre = @Nombre)
                RAISERROR('Nombre ya existe actualmente.',16,1);

            INSERT INTO dbo.TblRecetas (Nombre, ProductoId, TiempoImpresion, TiempoImpresionMin, TiempoPostMin, EstaActivo)
            VALUES (@Nombre, @ProductoId, ISNULL(@TiempoImpresion,''), ISNULL(@TiempoImpresionMin,0), ISNULL(@TiempoPostMin,0), 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SET @result = 'success';
        SET @message = IIF(@message='','Ningun error',@message);

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


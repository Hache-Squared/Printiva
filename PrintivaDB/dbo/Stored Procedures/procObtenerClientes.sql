/*
===============================================================================
Author: AGHH (adaptado para Clientes)
Date: 17/11/2025
Description: Obtención de clientes
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 17/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procObtenerClientes
    @ElementoObtenerId INT = 0,
    @loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;
    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoObtenerId, 0);
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END
        -- Temp table con campos que coincidan con la entidad Cliente
        CREATE TABLE #TempData (
            ClienteId INT,
            Nombre VARCHAR(200),
            Telefono VARCHAR(200),
            Correo VARCHAR(200)
        );
        INSERT INTO #TempData (
            ClienteId,
            Nombre,
            Telefono,
            Correo
        )
        SELECT
            cl.ClienteId,
            cl.Nombre,
            cl.Telefono,
            cl.Correo
        FROM dbo.TblClientes cl (NOLOCK);
        IF (ISNULL(@elementoId, 0) = 0)
        BEGIN
            -- Retorna todos
            SELECT
                ClienteId,
                Nombre,
                Telefono,
                Correo
            FROM #TempData;
        END
        ELSE
        BEGIN
            -- Retorna por ID
            SELECT
                ClienteId,
                Nombre,
                Telefono,
                Correo
            FROM #TempData t
            WHERE t.ClienteId = @elementoId;
        END
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, '') = '')
        BEGIN
            SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        END
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END CATCH
    DROP TABLE IF EXISTS #TempData;
END
/*
===============================================================================
Author: AGHH (adaptado para Ventas)
Date: 22/11/2025
Description: Obtención de ventas con JOIN al cliente
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author    Date        Description     Ticket
-------------------------------------------------------------------------------
1.0     AGHH       22/11/2025  First Version   N/A
*/
CREATE PROCEDURE dbo.procObtenerVentas
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

        -- Tabla temporal con los campos que coinciden con la entidad Venta + nombre cliente
        CREATE TABLE #TempData (
            VentaId INT,
            ClienteId INT,
            Descripcion VARCHAR(MAX),
            CostoTotal DECIMAL(10,2),
            FechaCreacion DATETIME,
            UsuarioId INT,
            ClienteNombre VARCHAR(400)  -- Nombre + Apellido del cliente
        );

        INSERT INTO #TempData (
            VentaId,
            ClienteId,
            Descripcion,
            CostoTotal,
            FechaCreacion,
            UsuarioId,
            ClienteNombre
        )
        SELECT
            v.VentaId,
            v.ClienteId,
            v.Descripcion,
            v.CostoTotal,
            v.FechaCreacion,
            v.UsuarioId,
            ISNULL(c.Nombre, '') AS ClienteNombre
        FROM dbo.TblVentas v (NOLOCK)
        LEFT JOIN dbo.TblClientes c (NOLOCK) ON v.ClienteId = c.ClienteId
        WHERE v.UsuarioId = @loginId;

        IF (ISNULL(@elementoId, 0) = 0)
        BEGIN
            -- Retorna todos
            SELECT
                VentaId,
                ClienteId,
                Descripcion,
                CostoTotal,
                FechaCreacion,
                UsuarioId,
                ClienteNombre
            FROM #TempData
            ORDER BY FechaCreacion DESC;
        END
        ELSE
        BEGIN
            -- Retorna uno específico
            SELECT
                VentaId,
                ClienteId,
                Descripcion,
                CostoTotal,
                FechaCreacion,
                UsuarioId,
                ClienteNombre
            FROM #TempData t
            WHERE t.VentaId = @elementoId;
        END

        SET @result = 'success';
        SET @message = 'OK';
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
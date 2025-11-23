/*
===============================================================================
Author: AGHH (adaptado para VentasRecetas)
Date: 22/11/2025
Description: Obtiene líneas de venta por VentaRecetaId o por VentaId usando flag
Ticket: 0000
Customer: N/A
Version: 1.1 (compatible con INSERT directo en Crear)
==============================================================================
*/
CREATE PROCEDURE dbo.procObtenerVentasRecetas
    @ElementoObtenerId     INT  = 0,
    @loginId               INT  = 0,
    @ObtenerPorVentaId     BIT  = 0   -- 1 = buscar por VentaId | 0 = buscar por VentaRecetaId
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @result  VARCHAR(100) = 'success';
    DECLARE @message VARCHAR(MAX) = '';

    BEGIN TRY
        -- Validar usuario
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios (NOLOCK) WHERE Id = @loginId)
            THROW 50000, 'Usuario no encontrado.', 1;

        -- Caso 1: Obtener TODAS las líneas de una venta
        IF @ObtenerPorVentaId = 1
        BEGIN
            IF @ElementoObtenerId <= 0
                THROW 50000, 'Debe especificar un VentaId válido.', 1;

            IF NOT EXISTS (SELECT 1 FROM dbo.TblVentas (NOLOCK) WHERE VentaId = @ElementoObtenerId AND UsuarioId = @loginId)
                THROW 50000, 'Venta no encontrada o no pertenece al usuario.', 1;

            SELECT 
                vr.VentaRecetaId,
                vr.VentaId,
                vr.RecetaId,
                vr.Cantidad,
                vr.CostoUnitario,
                r.Nombre AS RecetaNombre,
                vr.Cantidad * vr.CostoUnitario AS Subtotal
            FROM dbo.TblVentasRecetas vr (NOLOCK)
            INNER JOIN dbo.TblRecetas r (NOLOCK) ON vr.RecetaId = r.RecetaId
            WHERE vr.VentaId = @ElementoObtenerId
            ORDER BY vr.VentaRecetaId;
        END
        -- Caso 2: Obtener UNA línea específica por VentaRecetaId
        ELSE
        BEGIN
            IF @ElementoObtenerId <= 0
                THROW 50000, 'Debe especificar un VentaRecetaId válido.', 1;

            SELECT 
                vr.VentaRecetaId,
                vr.VentaId,
                vr.RecetaId,
                vr.Cantidad,
                vr.CostoUnitario,
                r.Nombre AS RecetaNombre,
                vr.Cantidad * vr.CostoUnitario AS Subtotal
            FROM dbo.TblVentasRecetas vr (NOLOCK)
            INNER JOIN dbo.TblRecetas r (NOLOCK) ON vr.RecetaId = r.RecetaId
            INNER JOIN dbo.TblVentas v (NOLOCK) ON vr.VentaId = v.VentaId
            WHERE vr.VentaRecetaId = @ElementoObtenerId
              AND v.UsuarioId = @loginId;

            IF @@ROWCOUNT = 0
                THROW 50000, 'Línea no encontrada o no pertenece al usuario.', 1;
        END

    END TRY
    BEGIN CATCH
        SET @result  = 'fail';
        SET @message = ERROR_MESSAGE() + ' (Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ')';

        SELECT @result  AS result,
               @message AS message,
               0        AS elementoId;
    END CATCH
END
GO
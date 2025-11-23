/*
===============================================================================
Author: AGHH (adaptado para VentasRecetas)
Date: 22/11/2025
Description: Actualizar, Borrar línea o Borrar todas las líneas de una venta
             (CREATE se hace con INSERT directo en C#)
Ticket: 0000
Customer: N/A
Version: 1.2 (compatible con todas las versiones de SQL Server)
==============================================================================
*/
CREATE PROCEDURE dbo.procAlteraVentasRecetas
    @ElementoAlterarId     INT = 0,
    @VentaId               INT = 0,
    @RecetaId              INT = 0,
    @Cantidad              DECIMAL(10,2) = 0,
    @CostoUnitario         DECIMAL(10,2) = 0,
    @loginId               INT = 0,
    @Actualizar            BIT = 0,
    @Borrar                BIT = 0,
    @BorrarTodasPorVenta   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @result     VARCHAR(100) = 'success';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        -- Validar usuario
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios (NOLOCK) WHERE Id = @loginId)
        BEGIN
            RAISERROR('Usuario no encontrado.', 16, 1);
        END

        ------------------------------------------------------------------
        -- Borrar TODAS las líneas de una venta
        ------------------------------------------------------------------
        IF @BorrarTodasPorVenta = 1
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.TblVentas (NOLOCK) WHERE VentaId = @ElementoAlterarId AND UsuarioId = @loginId)
                RAISERROR('Venta no encontrada o no pertenece al usuario.', 16, 1);

            DELETE FROM dbo.TblVentasRecetas 
            WHERE VentaId = @ElementoAlterarId;

            SET @message = 'Todas las líneas de la venta fueron eliminadas';
            SELECT @result AS result, @message AS message, @ElementoAlterarId AS elementoId;
            RETURN;
        END

        ------------------------------------------------------------------
        -- Borrar una línea individual
        ------------------------------------------------------------------
        IF @Borrar = 1
        BEGIN
            DELETE FROM dbo.TblVentasRecetas 
            WHERE VentaRecetaId = @ElementoAlterarId;

            IF @@ROWCOUNT = 0
                RAISERROR('Línea no encontrada.', 16, 1);

            SET @message = 'Línea eliminada';
        END

        ------------------------------------------------------------------
        -- Actualizar línea
        ------------------------------------------------------------------
        ELSE IF @Actualizar = 1
        BEGIN
            IF @Cantidad <= 0
                RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);

            IF @CostoUnitario < 0
                RAISERROR('El costo unitario no puede ser negativo.', 16, 1);

            IF NOT EXISTS (SELECT 1 FROM dbo.TblRecetas (NOLOCK) WHERE RecetaId = @RecetaId)
                RAISERROR('La receta no existe.', 16, 1);

            UPDATE dbo.TblVentasRecetas
            SET RecetaId      = @RecetaId,
                Cantidad      = @Cantidad,
                CostoUnitario = @CostoUnitario
            WHERE VentaRecetaId = @ElementoAlterarId;

            IF @@ROWCOUNT = 0
                RAISERROR('Línea no encontrada para actualizar.', 16, 1);

            SET @message = 'Línea actualizada';
        END
        ELSE
        BEGIN
            RAISERROR('Operación no permitida. Use INSERT directo para crear.', 16, 1);
        END

        SELECT @result     AS result,
               @message    AS message,
               @elementoId AS elementoId;

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
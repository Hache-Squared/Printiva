/*
===============================================================================
Author: AGHH (adaptado para Ventas)
Date: 22/11/2025
Description: Crear / Actualizar / Borrar ventas (físico)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
*/
CREATE PROCEDURE dbo.procAlteraVentas
    @ElementoAlterarId INT = 0,
    @ClienteId INT = NULL,
    @Descripcion VARCHAR(MAX) = '',
    @CostoTotal DECIMAL(10,2) = 0,
    @FechaCreacion DATETIME = NULL,
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @result VARCHAR(100) = 'success';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoAlterarId, 0);
        SET @FechaCreacion = ISNULL(@FechaCreacion, GETUTCDATE());

        -- Validar usuario
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Id = @loginId)
            THROW 50000, 'Usuario no encontrado.', 1;

        ---- Validaciones comunes para CREATE y UPDATE
        --IF @Actualizar = 1 OR (@Actualizar = 0 AND @Borrar = 0)
        --BEGIN
        --    IF @ClienteId <= 0
        --        THROW 50000, 'Cliente es obligatorio.', 1;

        --    IF NOT EXISTS (SELECT 1 FROM dbo.TblClientes WHERE ClienteId = @ClienteId)
        --        THROW 50000, 'Cliente no existe.', 1;

        --    IF LTRIM(RTRIM(@Descripcion)) = ''
        --        THROW 50000, 'La descripción no puede estar vacía.', 1;
        --END

        -- ¿Existe el registro y pertenece al usuario?
        IF @elementoId > 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.TblVentas WHERE VentaId = @elementoId AND UsuarioId = @loginId)
                THROW 50000, 'Registro no encontrado o no pertenece al usuario.', 1;
        END

        -- UPDATE
        IF @Actualizar = 1
        BEGIN
            --IF EXISTS (SELECT 1 FROM dbo.TblVentas 
            --           WHERE Descripcion = @Descripcion 
            --             AND ClienteId = @ClienteId 
            --             AND VentaId <> @elementoId
            --             AND UsuarioId = @loginId)
            --    THROW 50000, 'Ya existe una venta con esa descripción y cliente.', 1;

            UPDATE dbo.TblVentas
            SET ClienteId = @ClienteId,
                Descripcion = @Descripcion,
                CostoTotal = @CostoTotal,
                FechaCreacion = @FechaCreacion
            WHERE VentaId = @elementoId AND UsuarioId = @loginId;

            SET @message = 'Elemento Actualizado';
        END

        -- DELETE
        ELSE IF @Borrar = 1
        BEGIN
            DELETE FROM dbo.TblVentas 
            WHERE VentaId = @elementoId AND UsuarioId = @loginId;

            SET @message = 'Elemento Eliminado';
        END

        -- CREATE
        ELSE
        BEGIN
            --IF EXISTS (SELECT 1 FROM dbo.TblVentas 
            --           WHERE Descripcion = @Descripcion 
            --             AND ClienteId = @ClienteId 
            --             AND UsuarioId = @loginId)
            --    THROW 50000, 'Ya existe una venta con esa descripción y cliente.', 1;

            INSERT INTO dbo.TblVentas (ClienteId, Descripcion, CostoTotal, FechaCreacion, UsuarioId)
            VALUES (@ClienteId, @Descripcion, @CostoTotal, @FechaCreacion, @loginId);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SELECT @result  AS result,
               @message AS message,
               @elementoId AS elementoId;

    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = ERROR_MESSAGE() + ' (Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ')';

        SELECT @result  AS result,
               @message AS message,
               @elementoId AS elementoId;
    END CATCH
END
GO
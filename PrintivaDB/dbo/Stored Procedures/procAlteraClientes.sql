/*
===============================================================================
Author: AGHH (adaptado para Clientes)
Date: 17/11/2025
Description: Alteración de clientes (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 17/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procAlteraClientes
    @ElementoAlterarId INT = 0,
    @Nombre VARCHAR(200) = '',
    @Telefono VARCHAR(200) = NULL,  -- NULLable, default NULL
    @Correo VARCHAR(200) = NULL,    -- NULLable, default NULL
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;
    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoAlterarId, 0);
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END
        -- Solo valida inputs si es Actualizar o CREATE (no para Borrar, donde params son defaults)
        IF (ISNULL(@Actualizar, 0) = 1 OR (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0))
        BEGIN
            IF (ISNULL(@Nombre, '') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
        END
        -- Para Borrar, solo valida existencia del registro
        IF (ISNULL(@Borrar, 0) = 1 AND NOT EXISTS (
            SELECT 1
            FROM dbo.TblClientes cl (NOLOCK)
            WHERE cl.ClienteId = @ElementoAlterarId
        ))
        BEGIN
            SET @message = 'Registro no encontrado para borrar.';
            RAISERROR(@message, 16, 1);
        END
        IF EXISTS (
            SELECT 1
            FROM dbo.TblClientes cl (NOLOCK)
            WHERE cl.ClienteId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                -- Valida duplicado de Nombre (excluyendo el propio)
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblClientes cl (NOLOCK)
                    WHERE cl.Nombre = @Nombre
                    AND cl.ClienteId != @ElementoAlterarId
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                UPDATE tgt
                SET tgt.Nombre = @Nombre,
                    tgt.Telefono = @Telefono,  -- Maneja NULL directamente
                    tgt.Correo = @Correo       -- Maneja NULL directamente
                FROM dbo.TblClientes tgt
                WHERE tgt.ClienteId = @ElementoAlterarId;
                SET @message = 'Elemento Actualizado';
            END
            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblClientes tgt
                WHERE tgt.ClienteId = @ElementoAlterarId;
                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            -- Asume CREATE si no Actualizar ni Borrar
            IF (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0)
            BEGIN
                -- Valida duplicado de Nombre para CREATE
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblClientes cl (NOLOCK)
                    WHERE cl.Nombre = @Nombre
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                INSERT INTO dbo.TblClientes (Nombre, Telefono, Correo)
                VALUES (@Nombre, @Telefono, @Correo);  -- Maneja NULL directamente
                SET @elementoId = SCOPE_IDENTITY();
                SET @message = 'Elemento Agregado';
            END
            ELSE
            BEGIN
                SET @message = 'Operación inválida: No es CREATE ni UPDATE ni Borrar.';
                RAISERROR(@message, 16, 1);
            END
        END
        SET @result = 'success';
        SET @message = IIF(@message = '', 'Ningún error', @message);
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
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
END
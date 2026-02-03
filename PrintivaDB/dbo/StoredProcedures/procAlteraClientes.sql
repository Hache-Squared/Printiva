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

CREATE   PROCEDURE dbo.procAlteraClientes
    @ElementoAlterarId INT = 0,

    @Nombre NVARCHAR(150) = NULL,
    @Telefono NVARCHAR(30) = NULL,
    @Instagram NVARCHAR(80) = NULL,
    @WhatsApp NVARCHAR(30) = NULL,
    @Email NVARCHAR(120) = NULL,
    @Direccion NVARCHAR(250) = NULL,

    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0,
    @Reactivar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'fail';
    DECLARE @message NVARCHAR(MAX) = N'';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId, 0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = N'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        /* -----------------------------
           BORRAR LOGICO
           ----------------------------- */
        IF (ISNULL(@Borrar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
                  AND c.UsuarioId = @loginId
            )
            BEGIN
                SET @message = N'Registro no encontrado para borrar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET EstaActivo = 0,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId
              AND UsuarioId = @loginId;

            SET @result = 'success';
            SET @message = N'Cliente desactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           REACTIVAR
           ----------------------------- */
        IF (ISNULL(@Reactivar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
                  AND c.UsuarioId = @loginId
            )
            BEGIN
                SET @message = N'Registro no encontrado para reactivar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET EstaActivo = 1,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId
              AND UsuarioId = @loginId;

            SET @result = 'success';
            SET @message = N'Cliente reactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           VALIDACIONES BASE (create/update)
           ----------------------------- */
        IF (ISNULL(@Nombre, N'') = N'')
        BEGIN
            SET @message = N'Nombre no puede ser vacío.';
            RAISERROR(@message, 16, 1);
        END

        /* -----------------------------
           UPDATE
           ----------------------------- */
        IF (ISNULL(@Actualizar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
                  AND c.UsuarioId = @loginId
            )
            BEGIN
                SET @message = N'Registro no encontrado para actualizar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET Nombre = @Nombre,
                Telefono = @Telefono,
                Instagram = @Instagram,
                WhatsApp = @WhatsApp,
                Email = @Email,
                Direccion = @Direccion,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId
              AND UsuarioId = @loginId;

            SET @result = 'success';
            SET @message = N'Cliente actualizado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           CREATE
           ----------------------------- */
        INSERT INTO dbo.TblClientes
        (
            UsuarioId, Nombre, Telefono, Instagram, WhatsApp, Email, Direccion,
            FechaCreacion, EstaActivo, FechaActualizacion
        )
        VALUES
        (
            @loginId, @Nombre, @Telefono, @Instagram, @WhatsApp, @Email, @Direccion,
            SYSUTCDATETIME(), 1, NULL
        );

        SET @elementoId = CAST(SCOPE_IDENTITY() AS INT);

        SET @result = 'success';
        SET @message = N'Cliente creado.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;

    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, N'') = N'')
            SET @message = CONCAT(ERROR_MESSAGE(), N'. Error Line: *', ERROR_LINE(), N'*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;
    END CATCH
END
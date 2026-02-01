/*
===============================================================================
Author: AGHH
Date: 16/11/2025
Description: Alteración de compras (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procAlteraCompras
    @ElementoAlterarId INT = 0,
    @Descripcion VARCHAR(MAX) = '',
    @CompraTipoId INT = 0,
    @FilamentoTipoId INT = NULL,
    @CompraCategoriaId INT = 0,
    @CostoTotal DECIMAL(10,2) = 0,
    @FechaCreacion DATETIME = NULL,
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
        SET @FechaCreacion = ISNULL(@FechaCreacion, GETUTCDATE()); -- Usa parámetro o default
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF (ISNULL(@Actualizar, 0) = 1)
        BEGIN
            IF (ISNULL(@Descripcion, '') = '')
            BEGIN
                SET @message = 'Descripción no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblComprasTipos ct (NOLOCK)
                WHERE ct.CompraTipoId = @CompraTipoId
            )
            BEGIN
                SET @message = 'Tipo de compra no existe.';
                RAISERROR(@message, 16, 1);
            END
            IF (@FilamentoTipoId IS NOT NULL AND @FilamentoTipoId != 0 AND NOT EXISTS (
                SELECT 1
                FROM dbo.TblFilamentosTipos ft (NOLOCK)
                WHERE ft.FilamentoTipoId = @FilamentoTipoId
            ))
            BEGIN
                SET @message = 'Tipo de filamento no existe.';
                RAISERROR(@message, 16, 1);
            END
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblComprasCategorias cc (NOLOCK)
                WHERE cc.CompraCategoriaId = @CompraCategoriaId
            )
            BEGIN
                SET @message = 'Categoría de compra no existe.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF (ISNULL(@Borrar, 0) = 1 AND NOT EXISTS (
            SELECT 1
            FROM dbo.TblCompras c (NOLOCK)
            WHERE c.CompraId = @ElementoAlterarId
        ))
        BEGIN
            SET @message = 'Registro no encontrado para borrar.';
            RAISERROR(@message, 16, 1);
        END
        IF EXISTS (
            SELECT 1
            FROM dbo.TblCompras c (NOLOCK)
            WHERE c.CompraId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblCompras c (NOLOCK)
                    WHERE c.Descripcion = @Descripcion
                    AND c.CompraTipoId = @CompraTipoId
                    AND c.CompraCategoriaId = @CompraCategoriaId
                    AND c.CompraId != @ElementoAlterarId -- Excluir el propio para permitir actualizar al mismo
                )
                BEGIN
                    SET @message = 'Descripción ya existe con esa tipo y categoría actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                UPDATE tgt
                SET tgt.Descripcion = @Descripcion,
                    tgt.CompraTipoId = @CompraTipoId,
                    tgt.FilamentoTipoId = @FilamentoTipoId,
                    tgt.CompraCategoriaId = @CompraCategoriaId,
                    tgt.CostoTotal = @CostoTotal,
                    tgt.FechaCreacion = @FechaCreacion
                FROM dbo.TblCompras tgt
                WHERE tgt.CompraId = @ElementoAlterarId;
                SET @message = 'Elemento Actualizado';
            END
            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblCompras tgt
                WHERE tgt.CompraId = @ElementoAlterarId;
                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0)  -- Asume CREATE si no Actualizar ni Borrar
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblCompras c (NOLOCK)
                    WHERE c.Descripcion = @Descripcion
                    AND c.CompraTipoId = @CompraTipoId
                    AND c.CompraCategoriaId = @CompraCategoriaId
                )
                BEGIN
                    SET @message = 'Descripción ya existe con esa tipo y categoría actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                INSERT INTO dbo.TblCompras (Descripcion, CompraTipoId, FilamentoTipoId, CompraCategoriaId, CostoTotal, FechaCreacion)
                VALUES (@Descripcion, @CompraTipoId, @FilamentoTipoId, @CompraCategoriaId, @CostoTotal, @FechaCreacion);
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

-- ====== SP V2 (sin filamento, borrado lógico) ======
CREATE   PROCEDURE dbo.procAlteraComprasTiposV2
    @ElementoAlterarId INT = 0,
    @Nombre VARCHAR(200) = '',
    @EsInventario BIT = 0,
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
            FROM dbo.Usuarios u WITH (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        -- Si es borrado, NO exijas nombre
        IF (ISNULL(@Borrar, 0) = 0)
        BEGIN
            IF (ISNULL(@Nombre, '') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF EXISTS (
            SELECT 1
            FROM dbo.TblComprasTipos ct WITH (NOLOCK)
            WHERE ct.CompraTipoId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblComprasTipos ct WITH (NOLOCK)
                    WHERE ct.Nombre = @Nombre
                      AND ct.CompraTipoId != @ElementoAlterarId
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                SET tgt.Nombre = @Nombre,
                    tgt.EsInventario = @EsInventario
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                -- Borrado lógico
                UPDATE tgt
                SET tgt.EstaActivo = 0
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Desactivado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM dbo.TblComprasTipos ct WITH (NOLOCK)
                WHERE ct.Nombre = @Nombre
            )
            BEGIN
                SET @message = 'Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasTipos (Nombre, EsInventario, EstaActivo)
            VALUES (@Nombre, @EsInventario, 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
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
GO


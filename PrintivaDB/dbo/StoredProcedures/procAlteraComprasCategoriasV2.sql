    CREATE   PROCEDURE dbo.procAlteraComprasCategoriasV2
        @ElementoAlterarId INT = 0,
        @Nombre VARCHAR(200) = '',
        @loginId INT = 0,
        @Actualizar BIT = 0,
        @Borrar BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @result VARCHAR(50) = '';
        DECLARE @message VARCHAR(MAX) = '';
        DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

        BEGIN TRY
            IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            BEGIN
                SET @message = 'Usuario no encontrado.';
                RAISERROR(@message, 16, 1);
            END

            IF (ISNULL(@Nombre,'') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END

            IF (ISNULL(@Borrar,0) = 1)
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK) WHERE CompraCategoriaId=@ElementoAlterarId)
                BEGIN
                    SET @message='Categoría no encontrada.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE dbo.TblComprasCategorias
                    SET EstaActivo=0
                WHERE CompraCategoriaId=@ElementoAlterarId;

                SET @result='success'; SET @message='Categoría eliminada (lógica).';
                SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
                RETURN;
            END

            IF (ISNULL(@Actualizar,0) = 1)
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK) WHERE CompraCategoriaId=@ElementoAlterarId)
                BEGIN
                    SET @message='Categoría no encontrada.';
                    RAISERROR(@message, 16, 1);
                END

                IF EXISTS(
                    SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK)
                    WHERE Nombre=@Nombre AND CompraCategoriaId<>@ElementoAlterarId AND EstaActivo=1
                )
                BEGIN
                    SET @message='Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE dbo.TblComprasCategorias
                    SET Nombre=@Nombre,
                        EstaActivo=1
                WHERE CompraCategoriaId=@ElementoAlterarId;

                SET @result='success'; SET @message='Categoría actualizada.';
                SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
                RETURN;
            END

            /* CREATE */
            IF EXISTS(
                SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK)
                WHERE Nombre=@Nombre AND EstaActivo=1
            )
            BEGIN
                SET @message='Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasCategorias(Nombre, EstaActivo)
            VALUES(@Nombre, 1);

            SET @elementoId = SCOPE_IDENTITY();

            SET @result='success'; SET @message='Categoría creada.';
            SELECT @result [result], @message [message], @elementoId [elementoId];

        END TRY
        BEGIN CATCH
            SET @result='fail';
            IF (ISNULL(@message,'') = '')
                SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
            SELECT @result [result], @message [message], @elementoId [elementoId];
        END CATCH
    END
GO


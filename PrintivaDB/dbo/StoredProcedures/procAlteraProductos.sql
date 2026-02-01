CREATE OR ALTER PROCEDURE dbo.procAlteraProductos
@ElementoAlterarId INT = 0,
@Nombre VARCHAR(200) = '',
@ProductoCategoriaId INT = 0,
@SKU VARCHAR(200) = '',
@PrecioSugerido DECIMAL(18,2) = NULL,
@loginId INT = 0,
@Actualizar BIT = 0,
@Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoAlterarId,0);

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF(ISNULL(@Nombre,'') = '' AND ISNULL(@Borrar,0) = 0)
        BEGIN
            SET @message = 'Nombre no puede ser vacio.';
            RAISERROR(@message, 16, 1);
        END

        IF(ISNULL(@Borrar,0) = 0)
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblProductosCategorias pc (NOLOCK)
                WHERE pc.ProductoCategoriaId = @ProductoCategoriaId
            )
            BEGIN
                SET @message = 'Categoria de producto no existe.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF EXISTS(
            SELECT 1
            FROM dbo.TblProductos p (NOLOCK)
            WHERE p.ProductoId = @ElementoAlterarId
        )
        BEGIN
            IF(ISNULL(@Actualizar,0) = 1)
            BEGIN
                IF EXISTS(
                    SELECT 1
                    FROM dbo.TblProductos p (NOLOCK)
                    WHERE p.Nombre = @Nombre
                      AND p.ProductoCategoriaId = @ProductoCategoriaId
                      AND p.ProductoId <> @ElementoAlterarId
                      AND p.EstaActivo = 1
                )
                BEGIN
                    SET @message = 'Nombre ya existe con esa categoria actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                    SET tgt.Nombre = @Nombre,
                        tgt.ProductoCategoriaId = @ProductoCategoriaId,
                        tgt.SKU = @SKU,
                        tgt.PrecioSugerido = @PrecioSugerido
                FROM dbo.TblProductos tgt
                WHERE tgt.ProductoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF(ISNULL(@Borrar,0) = 1)
            BEGIN
                UPDATE dbo.TblProductos
                    SET EstaActivo = 0
                WHERE ProductoId = @ElementoAlterarId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS(
                SELECT 1
                FROM dbo.TblProductos p (NOLOCK)
                WHERE p.Nombre = @Nombre
                  AND p.ProductoCategoriaId = @ProductoCategoriaId
                  AND p.EstaActivo = 1
            )
            BEGIN
                SET @message = 'Nombre ya existe con esa categoria actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblProductos(Nombre, ProductoCategoriaId, SKU, PrecioSugerido, EstaActivo)
            VALUES (@Nombre, @ProductoCategoriaId, @SKU, @PrecioSugerido, 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SELECT
            'success' [result],
            @message [message],
            @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SELECT
            'fail' [result],
            CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.') [message],
            @elementoId [elementoId];
    END CATCH
END
GO

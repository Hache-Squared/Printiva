CREATE   PROCEDURE dbo.procAlteraImpresora
    @ElementoAlterarId INT = 0,
    @Nombre NVARCHAR(150) = NULL,
    @Modelo NVARCHAR(150) = NULL,
    @Notas NVARCHAR(500) = NULL,
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId, 0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF @Borrar = 1
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ElementoAlterarId AND i.EstaActivo = 1
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET EstaActivo = 0,
                FechaActualizacion = GETUTCDATE()
            WHERE ImpresoraId = @ElementoAlterarId;

            SET @message = 'Impresora desactivada.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        IF ISNULL(LTRIM(RTRIM(@Nombre)), '') = ''
            RAISERROR('El nombre es requerido.', 16, 1);

        IF @Actualizar = 1
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ElementoAlterarId
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET Nombre = @Nombre,
                Modelo = NULLIF(@Modelo,''),
                Notas = NULLIF(@Notas,''),
                FechaActualizacion = GETUTCDATE(),
                EstaActivo = 1
            WHERE ImpresoraId = @ElementoAlterarId;

            SET @message = 'Impresora actualizada.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        INSERT INTO dbo.TblImpresoras (UsuarioId, Nombre, Modelo, Notas, EstaActivo)
        VALUES (@loginId, @Nombre, NULLIF(@Modelo,''), NULLIF(@Notas,''), 1);

        SET @elementoId = SCOPE_IDENTITY();
        SET @message = 'Impresora creada.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


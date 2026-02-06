CREATE   PROCEDURE dbo.procAlteraUsuarios
    @ElementoAlterarId INT = 0,

    @Nombre NVARCHAR(150) = NULL,
    @Email NVARCHAR(256) = NULL,
    @PasswordHash NVARCHAR(MAX) = NULL,     -- solo si cambia o crea
    @EsAdmin BIT = 0,
    @PermisosJson NVARCHAR(MAX) = N'[]',

    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0,
    @Reactivar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'fail';
    DECLARE @message NVARCHAR(MAX) = N'';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);
    DECLARE @EmailNormalizado NVARCHAR(256) = UPPER(LTRIM(RTRIM(ISNULL(@Email,N''))));

    BEGIN TRY
        /* ===== seguridad: SOLO admin altera usuarios ===== */
        IF NOT EXISTS(
            SELECT 1 FROM dbo.Usuarios
            WHERE Id = @loginId AND EstaActivo = 1 AND EsAdmin = 1
        )
        BEGIN
            SET @message = N'No autorizado.';
            RAISERROR(@message, 16, 1);
        END

        /* ===== desactivar ===== */
        IF (ISNULL(@Borrar,0) = 1)
        BEGIN
            IF (@ElementoAlterarId = @loginId)
                RAISERROR('No puedes desactivarte a ti mismo.',16,1);

            /* no permitir desactivar el último admin activo */
            IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Id=@ElementoAlterarId AND EsAdmin=1 AND EstaActivo=1)
               AND (SELECT COUNT(1) FROM dbo.Usuarios WHERE EsAdmin=1 AND EstaActivo=1) <= 1
            BEGIN
                RAISERROR('No puedes desactivar al último admin.',16,1);
            END

            UPDATE dbo.Usuarios
            SET EstaActivo = 0,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE Id = @ElementoAlterarId;

            UPDATE dbo.TblUsuariosPermisos
            SET EstaActivo = 0
            WHERE UsuarioId = @ElementoAlterarId;

            SET @result='success';
            SET @message='Usuario desactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* ===== reactivar ===== */
        IF (ISNULL(@Reactivar,0) = 1)
        BEGIN
            UPDATE dbo.Usuarios
            SET EstaActivo = 1,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE Id = @ElementoAlterarId;

            SET @result='success';
            SET @message='Usuario reactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* ===== validaciones create/update ===== */
        IF (ISNULL(LTRIM(RTRIM(@Nombre)),N'') = N'')
            RAISERROR('Nombre requerido.',16,1);

        IF (ISNULL(LTRIM(RTRIM(@Email)),N'') = N'')
            RAISERROR('Email requerido.',16,1);

        IF (ISJSON(@PermisosJson)=0)
            RAISERROR('PermisosJson inválido.',16,1);

        /* email único */
        IF EXISTS(
            SELECT 1 FROM dbo.Usuarios
            WHERE EmailNormalizado = @EmailNormalizado
              AND Id <> @ElementoAlterarId
        )
        BEGIN
            RAISERROR('Email ya existe actualmente.',16,1);
        END

        /* ===== UPDATE ===== */
        IF (ISNULL(@Actualizar,0)=1)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios WHERE Id=@ElementoAlterarId)
                RAISERROR('Usuario no encontrado.',16,1);

            UPDATE dbo.Usuarios
            SET Nombre = @Nombre,
                Email = @Email,
                EmailNormalizado = @EmailNormalizado,
                EsAdmin = ISNULL(@EsAdmin,0),
                PasswordHash = COALESCE(NULLIF(@PasswordHash,N''), PasswordHash),
                EstaActivo = 1,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE Id = @ElementoAlterarId;

            /* Permisos: reset + merge */
            UPDATE dbo.TblUsuariosPermisos
            SET EstaActivo = 0
            WHERE UsuarioId = @ElementoAlterarId;

            ;WITH P AS (
                SELECT DISTINCT value AS PermisoKey
                FROM OPENJSON(@PermisosJson)
            )
            MERGE dbo.TblUsuariosPermisos AS T
            USING P AS S
            ON T.UsuarioId = @ElementoAlterarId AND T.PermisoKey = S.PermisoKey
            WHEN MATCHED THEN
                UPDATE SET EstaActivo = 1
            WHEN NOT MATCHED THEN
                INSERT (UsuarioId, PermisoKey, EstaActivo)
                VALUES (@ElementoAlterarId, S.PermisoKey, 1);

            SET @result='success';
            SET @message='Usuario actualizado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* ===== CREATE ===== */
        IF (ISNULL(@PasswordHash,N'')=N'')
            RAISERROR('Password requerido para crear usuario.',16,1);

        INSERT INTO dbo.Usuarios(Email, EmailNormalizado, PasswordHash, Nombre, EstaActivo, EsAdmin)
        VALUES(@Email, @EmailNormalizado, @PasswordHash, @Nombre, 1, ISNULL(@EsAdmin,0));

        SET @elementoId = SCOPE_IDENTITY();

        /* permisos */
        ;WITH P AS (
            SELECT DISTINCT value AS PermisoKey
            FROM OPENJSON(@PermisosJson)
        )
        INSERT INTO dbo.TblUsuariosPermisos(UsuarioId, PermisoKey, EstaActivo)
        SELECT @elementoId, PermisoKey, 1
        FROM P;

        /* seed de datos extra del usuario */
        IF OBJECT_ID('dbo.CrearDatosUsuarioNuevo','P') IS NOT NULL
            EXEC dbo.CrearDatosUsuarioNuevo @UsuarioId = @elementoId;

        SET @result='success';
        SET @message='Usuario creado.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;

    END TRY
    BEGIN CATCH
        SET @result='fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;
    END CATCH
END
GO


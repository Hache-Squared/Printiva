CREATE   PROCEDURE dbo.procObtenerUsuarioDetalle
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Id, Nombre, Email, EmailNormalizado, EstaActivo, EsAdmin
    FROM dbo.Usuarios
    WHERE Id = @UsuarioId;

    SELECT PermisoKey
    FROM dbo.TblUsuariosPermisos
    WHERE UsuarioId = @UsuarioId AND EstaActivo = 1
    ORDER BY PermisoKey;
END
GO


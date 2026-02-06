CREATE   PROCEDURE dbo.procObtenerUsuarios
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id,
        u.Nombre,
        u.Email,
        u.EstaActivo,
        u.EsAdmin,
        Permisos = STRING_AGG(CASE WHEN p.EstaActivo=1 THEN p.PermisoKey END, ',')
                   WITHIN GROUP (ORDER BY p.PermisoKey)
    FROM dbo.Usuarios u
    LEFT JOIN dbo.TblUsuariosPermisos p
        ON p.UsuarioId = u.Id
    GROUP BY u.Id, u.Nombre, u.Email, u.EstaActivo, u.EsAdmin
    ORDER BY u.Id DESC;
END
GO


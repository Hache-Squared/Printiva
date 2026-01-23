CREATE OR ALTER PROCEDURE dbo.procObtenerImpresoras
    @loginId INT,
    @ElementoObtenerId INT = NULL,
    @SoloActivas BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
    BEGIN
        RAISERROR('Usuario no encontrado.', 16, 1);
        RETURN;
    END

    SELECT
        i.ImpresoraId,
        i.UsuarioId,
        i.Nombre,
        i.Modelo,
        i.Notas,
        i.EstaActivo,
        i.FechaCreacion,
        i.FechaActualizacion
    FROM dbo.TblImpresoras i (NOLOCK)
    WHERE i.UsuarioId = @loginId
      AND (@ElementoObtenerId IS NULL OR i.ImpresoraId = @ElementoObtenerId)
      AND (@SoloActivas = 0 OR i.EstaActivo = 1)
    ORDER BY i.EstaActivo DESC, i.Nombre ASC, i.ImpresoraId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procObtenerClientes
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ClienteId,
        UsuarioId,
        Nombre,
        Telefono,
        Instagram,
        WhatsApp,
        Email,
        Direccion,
        FechaCreacion
    FROM dbo.TblClientes
    WHERE UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR ClienteId = @elementoObtenerId)
    ORDER BY Nombre;
END
CREATE   PROCEDURE dbo.procObtenerClientes
  @loginId INT,
  @elementoObtenerId INT = NULL,
  @SoloActivos BIT = 1
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
    FechaCreacion,
    EstaActivo,
    FechaActualizacion
  FROM dbo.TblClientes WITH (NOLOCK)
  WHERE UsuarioId = @loginId
    AND (@elementoObtenerId IS NULL OR ClienteId = @elementoObtenerId)
    AND (@SoloActivos = 0 OR EstaActivo = 1)
  ORDER BY Nombre;
END
GO


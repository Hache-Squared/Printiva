CREATE   PROCEDURE dbo.procObtenerPagoTipos
AS
BEGIN
	SET NOCOUNT ON;
	SELECT PagoTipoId, Nombre FROM dbo.TblPagoTipos (NOLOCK) ORDER BY PagoTipoId ASC;
END
GO


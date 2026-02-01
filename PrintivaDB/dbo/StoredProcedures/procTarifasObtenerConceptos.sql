

/* =========================================================
   2) SP: LISTAR CONCEPTOS
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerConceptos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TarifaConceptoId, Codigo, Nombre, Unidad, Orden
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE EstaActivo = 1
    ORDER BY Orden ASC, Nombre ASC;
END
GO


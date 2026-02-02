

/* =========================================================
   8) SP: DIAGNÓSTICO (SIN VIGENCIAS)
      - Solo devuelve conceptos que NO tienen tarifa global (sin scope)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasDiagnostico
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH conceptos AS (
        SELECT TarifaConceptoId, Codigo, Nombre
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE EstaActivo = 1
    ),
    existentes_global AS (
        SELECT TarifaConceptoId
        FROM dbo.TblTarifas WITH (NOLOCK)
        WHERE UsuarioId = @loginId
          AND EstaActivo = 1
          AND ImpresoraId IS NULL
          AND InventarioId IS NULL
    )
    SELECT
        c.Codigo,
        c.Nombre,
        CASE WHEN eg.TarifaConceptoId IS NULL THEN 1 ELSE 0 END AS FaltaTarifaGlobal
    FROM conceptos c
    LEFT JOIN existentes_global eg
        ON eg.TarifaConceptoId = c.TarifaConceptoId
    WHERE eg.TarifaConceptoId IS NULL
    ORDER BY c.Codigo;
END
GO


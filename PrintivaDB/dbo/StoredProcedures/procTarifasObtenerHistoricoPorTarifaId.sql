

/* =========================================================
   7) SP: HISTÓRICO POR TARIFA
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP(100)
        l.TarifaLogId,
        l.Accion,
        l.MontoAntes, l.MonedaAntes,
        l.MontoDespues, l.MonedaDespues,
        l.EstaActivoAntes, l.EstaActivoDespues,
        l.FechaAccion
    FROM dbo.TblTarifasLog l WITH (NOLOCK)
    WHERE l.TarifaId = @TarifaId
      AND l.UsuarioId = @loginId
    ORDER BY l.FechaAccion DESC, l.TarifaLogId DESC;
END
GO


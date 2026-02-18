

/* =========================================================
   7) SP: HISTÓRICO POR TARIFA
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.TarifaLogId,
        l.Accion,

        l.ImpresoraId,
        l.InventarioId,

        l.NombreAntes, l.NombreDespues,
        l.OrdenAntes,  l.OrdenDespues,

        l.MontoAntes, l.MonedaAntes,
        l.MontoDespues, l.MonedaDespues,

        l.EstaActivoAntes, l.EstaActivoDespues,
        l.FechaAccion
    FROM dbo.TblTarifasLog l WITH (NOLOCK)
    WHERE l.TarifaId = @TarifaId
    ORDER BY l.FechaAccion DESC, l.TarifaLogId DESC;
END
GO


CREATE   PROCEDURE dbo.procObtenerPedidoEstatus
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PedidoEstatusId, Nombre
    FROM dbo.TblPedidoEstatus
    ORDER BY PedidoEstatusId;
END
GO



/* Seed inicial (si no existe) */
IF NOT EXISTS (SELECT 1 FROM dbo.TblProduccionEstatus WHERE EstaActivo=1)
BEGIN
    INSERT INTO dbo.TblProduccionEstatus (Nombre, Orden, BadgeClass)
    VALUES
    (N'En producción',       1, 'bg-primary'),
    (N'Post-proceso',        2, 'bg-warning text-dark'),
    (N'Listo para entrega',  3, 'bg-info text-dark'),
    (N'Entregado',           4, 'bg-success');
END
GO


/* Seed transiciones básicas (forward-only) */
DECLARE @p1 INT = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus WHERE Nombre=N'En producción' AND EstaActivo=1);
DECLARE @p2 INT = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus WHERE Nombre=N'Post-proceso' AND EstaActivo=1);
DECLARE @p3 INT = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus WHERE Nombre=N'Listo para entrega' AND EstaActivo=1);
DECLARE @p4 INT = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus WHERE Nombre=N'Entregado' AND EstaActivo=1);

IF @p1 IS NOT NULL AND @p2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TblProduccionEstatusTransiciones WHERE DesdeEstatusId=@p1 AND HaciaEstatusId=@p2)
    INSERT dbo.TblProduccionEstatusTransiciones VALUES (@p1,@p2);

IF @p2 IS NOT NULL AND @p3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TblProduccionEstatusTransiciones WHERE DesdeEstatusId=@p2 AND HaciaEstatusId=@p3)
    INSERT dbo.TblProduccionEstatusTransiciones VALUES (@p2,@p3);

IF @p3 IS NOT NULL AND @p4 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TblProduccionEstatusTransiciones WHERE DesdeEstatusId=@p3 AND HaciaEstatusId=@p4)
    INSERT dbo.TblProduccionEstatusTransiciones VALUES (@p3,@p4);
GO

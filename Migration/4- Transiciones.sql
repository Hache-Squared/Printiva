
IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Nuevo')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Nuevo');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'En modelado')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('En modelado');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Modelado listo')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Modelado listo');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Aprobado')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Aprobado');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'En producción')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('En producción');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Post-proceso')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Post-proceso');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Listo para entrega')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Listo para entrega');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Entregado')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Entregado');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus WHERE Nombre = 'Cancelado')
    INSERT INTO dbo.TblPedidoEstatus(Nombre) VALUES ('Cancelado');

DECLARE @Nuevo INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Nuevo');
DECLARE @EnModelado INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='En modelado');
DECLARE @ModeladoListo INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Modelado listo');
DECLARE @Aprobado INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Aprobado');
DECLARE @EnProduccion INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='En producción');
DECLARE @Post INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Post-proceso');
DECLARE @ListoEntrega INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Listo para entrega');
DECLARE @Entregado INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Entregado');
DECLARE @Cancelado INT = (SELECT PedidoEstatusId FROM dbo.TblPedidoEstatus WHERE Nombre='Cancelado');

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Nuevo AND HaciaEstatusId=@EnModelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Nuevo,@EnModelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@EnModelado AND HaciaEstatusId=@ModeladoListo)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@EnModelado,@ModeladoListo);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@ModeladoListo AND HaciaEstatusId=@Aprobado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@ModeladoListo,@Aprobado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Aprobado AND HaciaEstatusId=@EnProduccion)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Aprobado,@EnProduccion);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@EnProduccion AND HaciaEstatusId=@Post)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@EnProduccion,@Post);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Post AND HaciaEstatusId=@ListoEntrega)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Post,@ListoEntrega);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@ListoEntrega AND HaciaEstatusId=@Entregado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@ListoEntrega,@Entregado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Nuevo AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Nuevo,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@EnModelado AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@EnModelado,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@ModeladoListo AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@ModeladoListo,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Aprobado AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Aprobado,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@EnProduccion AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@EnProduccion,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@Post AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@Post,@Cancelado);

IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidosEstatusTransiciones WHERE DesdeEstatusId=@ListoEntrega AND HaciaEstatusId=@Cancelado)
    INSERT INTO dbo.TblPedidosEstatusTransiciones(DesdeEstatusId,HaciaEstatusId) VALUES (@ListoEntrega,@Cancelado);
GO

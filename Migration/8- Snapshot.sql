-- Agrega columnas "snapshot" solo si no existen (seguro para correr varias veces)

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','PedidoId') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD PedidoId INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','PedidoItemId') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD PedidoItemId INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','ProductoId') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD ProductoId INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','CantidadItem') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD CantidadItem INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','DesdeEstatusId') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD DesdeEstatusId INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','HaciaEstatusId') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD HaciaEstatusId INT NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','Notas') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD Notas NVARCHAR(500) NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','RecetaNombre') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD RecetaNombre NVARCHAR(200) NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','InsumoNombre') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD InsumoNombre NVARCHAR(200) NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','UnidadNombre') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD UnidadNombre NVARCHAR(100) NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','DisponibleAntes') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD DisponibleAntes DECIMAL(18,2) NULL;

IF COL_LENGTH('dbo.TblProduccionInventarioConsumo','DisponibleDespues') IS NULL
    ALTER TABLE dbo.TblProduccionInventarioConsumo ADD DisponibleDespues DECIMAL(18,2) NULL;
GO

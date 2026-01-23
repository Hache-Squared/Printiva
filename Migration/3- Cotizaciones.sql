IF OBJECT_ID('dbo.TblCotizacionesEstatus','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblCotizacionesEstatus(
		CotizacionEstatusId INT PRIMARY KEY IDENTITY(1,1),
		Nombre VARCHAR(100) NOT NULL
	);

	INSERT INTO dbo.TblCotizacionesEstatus(Nombre)
	VALUES ('Borrador'),('Enviada'),('Aceptada'),('Rechazada'),('Cancelada');
END
GO

IF OBJECT_ID('dbo.TblCotizacionConceptoTipos','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblCotizacionConceptoTipos(
		ConceptoTipoId INT PRIMARY KEY IDENTITY(1,1),
		Nombre VARCHAR(100) NOT NULL
	);

	INSERT INTO dbo.TblCotizacionConceptoTipos(Nombre)
	VALUES ('Modelado'),('Produccion');
END
GO

IF OBJECT_ID('dbo.TblPagoTipos','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblPagoTipos(
		PagoTipoId INT PRIMARY KEY IDENTITY(1,1),
		Nombre VARCHAR(100) NOT NULL
	);

	INSERT INTO dbo.TblPagoTipos(Nombre)
	VALUES ('Modelado'),('Produccion'),('General');
END
GO

IF OBJECT_ID('dbo.TblCotizaciones','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblCotizaciones(
		CotizacionId INT PRIMARY KEY IDENTITY(1,1),
		PedidoId INT NOT NULL,
		CotizacionEstatusId INT NOT NULL,
		FechaCreacion DATETIME NOT NULL,
		FechaVigencia DATETIME NULL,
		Notas VARCHAR(MAX) NULL,
		EstaActivo BIT NOT NULL CONSTRAINT DF_TblCotizaciones_EstaActivo DEFAULT(1),

		CONSTRAINT FK_TblCotizaciones_Estatus FOREIGN KEY(CotizacionEstatusId)
			REFERENCES dbo.TblCotizacionesEstatus(CotizacionEstatusId)
	);
END
GO

IF COL_LENGTH('dbo.TblCotizaciones', 'PedidoId') IS NOT NULL
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM sys.foreign_keys
		WHERE name = 'FK_TblCotizaciones_TblPedidos'
	)
	BEGIN
		ALTER TABLE dbo.TblCotizaciones
		ADD CONSTRAINT FK_TblCotizaciones_TblPedidos
		FOREIGN KEY (PedidoId) REFERENCES dbo.TblPedidos(PedidoId);
	END
END
GO

IF OBJECT_ID('dbo.TblCotizacionItems','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblCotizacionItems(
		CotizacionItemId INT PRIMARY KEY IDENTITY(1,1),
		CotizacionId INT NOT NULL,
		ConceptoTipoId INT NOT NULL,
		ProductoId INT NULL,
		Concepto VARCHAR(200) NOT NULL,
		Cantidad DECIMAL(10,2) NOT NULL,
		PrecioUnitario DECIMAL(10,2) NOT NULL,
		Notas VARCHAR(500) NULL,
		EstaActivo BIT NOT NULL CONSTRAINT DF_TblCotizacionItems_EstaActivo DEFAULT(1),

		CONSTRAINT FK_TblCotizacionItems_Cotizaciones FOREIGN KEY(CotizacionId)
			REFERENCES dbo.TblCotizaciones(CotizacionId),

		CONSTRAINT FK_TblCotizacionItems_ConceptoTipos FOREIGN KEY(ConceptoTipoId)
			REFERENCES dbo.TblCotizacionConceptoTipos(ConceptoTipoId)
	);
END
GO

IF OBJECT_ID('dbo.TblPagos','U') IS NULL
BEGIN
	CREATE TABLE dbo.TblPagos(
		PagoId INT PRIMARY KEY IDENTITY(1,1),
		CotizacionId INT NOT NULL,
		PagoTipoId INT NOT NULL,
		Monto DECIMAL(10,2) NOT NULL,
		FechaPago DATETIME NOT NULL,
		Metodo VARCHAR(100) NULL,
		Referencia VARCHAR(200) NULL,
		Notas VARCHAR(500) NULL,
		FechaCreacion DATETIME NOT NULL CONSTRAINT DF_TblPagos_FechaCreacion DEFAULT(GETDATE()),
		EstaActivo BIT NOT NULL CONSTRAINT DF_TblPagos_EstaActivo DEFAULT(1),

		CONSTRAINT FK_TblPagos_Cotizaciones FOREIGN KEY(CotizacionId)
			REFERENCES dbo.TblCotizaciones(CotizacionId),

		CONSTRAINT FK_TblPagos_PagoTipos FOREIGN KEY(PagoTipoId)
			REFERENCES dbo.TblPagoTipos(PagoTipoId)
	);
END
GO

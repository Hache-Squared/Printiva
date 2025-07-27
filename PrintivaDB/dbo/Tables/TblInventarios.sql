CREATE TABLE TblInventarios(
	InventarioId INT PRIMARY KEY IDENTITY(1,1),
	InventarioMarcaId INT NOT NULL,
	InventarioTipoId INT NOT NULL,
	InventarioNombreId INT NOT NULL,
	InventarioColorId INT NOT NULL,
	Cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
	InventarioUnidadId INT NOT NULL,
	FechaCreacion DATETIME DEFAULT GETUTCDATE(),

	CONSTRAINT FK_TblInventarios_TblInventariosMarcas FOREIGN KEY(InventarioMarcaId)
		REFERENCES dbo.TblInventariosMarcas(InventarioMarcaId),
	
	CONSTRAINT FK_TblInventarios_TblInventariosTipos FOREIGN KEY(InventarioTipoId)
		REFERENCES dbo.TblInventariosTipos(InventarioTipoId),

	CONSTRAINT FK_TblInventarios_TblInventariosUnidades FOREIGN KEY(InventarioUnidadId)
		REFERENCES dbo.TblInventariosUnidades(InventarioUnidadId),

	CONSTRAINT FK_TblInventarios_TblInventariosColores FOREIGN KEY(InventarioColorId)
		REFERENCES dbo.TblInventariosColores(InventarioColorId),

	CONSTRAINT FK_TblInventarios_TblInventariosNombres FOREIGN KEY(InventarioNombreId)
		REFERENCES dbo.TblInventariosNombres(InventarioNombreId)
)
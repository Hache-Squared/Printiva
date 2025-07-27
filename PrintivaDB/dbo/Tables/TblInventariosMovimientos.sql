CREATE TABLE TblInventariosMovimientos(
	InventarioMovimientoId INT PRIMARY KEY IDENTITY(1,1),
	InventarioId INT NOT NULL,
	TipoMovimientoId INT NOT NULL,
	Cantidad INT NOT NULL DEFAULT 0,
	Costo DECIMAL(10,2) DEFAULT 0,
	FechaCreacion DATETIME DEFAULT GETUTCDATE(),
	UsuarioId INT NOT NULL,

	CONSTRAINT FK_TblInventariosMovimientos_TblInventarios FOREIGN KEY(InventarioId)
		REFERENCES dbo.TblInventarios(InventarioId),
	
	CONSTRAINT FK_TblInventariosMovimientos_TblInventariosMovimientoTipos FOREIGN KEY(TipoMovimientoId)
		REFERENCES dbo.TblInventariosMovimientoTipos(TipoMovimientoId),
	
	CONSTRAINT FK_TblInventariosMovimientos_Usuarios FOREIGN KEY(UsuarioId)
		REFERENCES dbo.Usuarios(Id)
	
)
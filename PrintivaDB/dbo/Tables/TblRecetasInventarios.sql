CREATE TABLE TblRecetasInventarios(
	RecetaId INT NOT NULL,
	InventarioId INT NOT NULL,
	Cantidad DECIMAL(10,2) NOT NULL DEFAULT 0

	CONSTRAINT FK_TblRecetasInventarios_TblRecetas FOREIGN KEY(RecetaId)
		REFERENCES dbo.TblRecetas(RecetaId)

	CONSTRAINT FK_TblRecetasInventarios_TblInventarios FOREIGN KEY(InventarioId)
		REFERENCES dbo.TblInventarios(InventarioId),

	PRIMARY KEY(RecetaId, InventarioId)
)
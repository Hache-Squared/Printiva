CREATE TABLE TblRecetas(
	RecetaId INT PRIMARY KEY IDENTITY(1,1),
	Nombre VARCHAR(200) NOT NULL,
	ProductoId INT NOT NULL,
	TiempoImpresion VARCHAR(200) NOT NULL

	CONSTRAINT FK_TblRecetas_TblProductos FOREIGN KEY(ProductoId)
		REFERENCES dbo.TblProductos(ProductoId)
)
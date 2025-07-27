CREATE TABLE TblProductos(
	ProductoId INT PRIMARY KEY IDENTITY(1,1),
	Nombre VARCHAR(200) NOT NULL,
	ProductoCategoriaId INT NOT NULL,
	SKU VARCHAR(200)

	CONSTRAINT FK_TblProductos_TblProductosCategorias FOREIGN KEY(ProductoCategoriaId)
		REFERENCES dbo.TblProductosCategorias(ProductoCategoriaId)
)
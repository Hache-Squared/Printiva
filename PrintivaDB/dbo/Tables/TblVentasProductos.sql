CREATE TABLE TblVentasProductos(
	VentaId INT NOT NULL,
	ProductoId INT NOT NULL,
	Cantidad INT NOT NULL DEFAULT 0,
	CostoUnitario DECIMAL(10,2) NOT NULL DEFAULT 0

	CONSTRAINT FK_TblVentasProductos_TblVentas FOREIGN KEY(VentaId)
		REFERENCES dbo.TblVentas(VentaId)

	CONSTRAINT FK_TblVentasProductos_TblProductos FOREIGN KEY(ProductoId)
		REFERENCES TblProductos(ProductoId),

	PRIMARY KEY(VentaId, ProductoId)
)
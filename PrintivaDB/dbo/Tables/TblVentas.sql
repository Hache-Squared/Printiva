CREATE TABLE TblVentas(
	VentaId INT PRIMARY KEY IDENTITY(1,1),
	ClienteId INT NULL,
	Descripcion VARCHAR(MAX),
	CostoTotal DECIMAL(10,2) DEFAULT 0,
	FechaCreacion DATETIME DEFAULT GETUTCDATE(),
	UsuarioId INT NOT NULL,

	CONSTRAINT FK_TblVentas_TblClientes FOREIGN KEY(ClienteId)
	REFERENCES dbo.TblClientes(ClienteId),

	CONSTRAINT FK_TblVentas_Usuarios FOREIGN KEY(UsuarioId)
	REFERENCES dbo.Usuarios(Id)
)
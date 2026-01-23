CREATE TABLE dbo.TblProduccionItems
(
    ProduccionItemId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PedidoId INT NOT NULL,
    PedidoItemId INT NOT NULL,
    UsuarioId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad INT NOT NULL,

    ProduccionEstatusId INT NOT NULL,
    Notas NVARCHAR(500) NULL,

    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_TblProduccionItems_FechaCreacion DEFAULT(GETDATE()),
    FechaActualizacion DATETIME NULL,
    EstaActivo BIT NOT NULL CONSTRAINT DF_TblProduccionItems_EstaActivo DEFAULT(1),

    CONSTRAINT UX_TblProduccionItems_PedidoItem UNIQUE (PedidoItemId),
    CONSTRAINT FK_TblProduccionItems_Estatus FOREIGN KEY (ProduccionEstatusId) REFERENCES dbo.TblProduccionEstatus(ProduccionEstatusId)
);
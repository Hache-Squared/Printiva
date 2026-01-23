CREATE TABLE dbo.TblPedidos
(
    PedidoId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UsuarioId INT NOT NULL,
    ClienteId INT NOT NULL,
    PedidoEstatusId INT NOT NULL,
    FechaCreacion DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    FechaEntregaEstimada DATETIME2 NULL,
    Notas NVARCHAR(500) NULL,
    TotalEstimado DECIMAL(18,2) NULL,
    CONSTRAINT FK_TblPedidos_Clientes FOREIGN KEY (ClienteId) REFERENCES dbo.TblClientes(ClienteId),
    CONSTRAINT FK_TblPedidos_Estatus FOREIGN KEY (PedidoEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId)
);
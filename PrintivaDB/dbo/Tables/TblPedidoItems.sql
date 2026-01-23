CREATE TABLE dbo.TblPedidoItems
(
    PedidoItemId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PedidoId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitarioEstimado DECIMAL(18,2) NULL,
    Notas NVARCHAR(250) NULL,
    CONSTRAINT FK_TblPedidoItems_Pedidos FOREIGN KEY (PedidoId) REFERENCES dbo.TblPedidos(PedidoId)
);
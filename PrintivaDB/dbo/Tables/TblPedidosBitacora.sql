CREATE TABLE dbo.TblPedidosBitacora(
    PedidoBitacoraId INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT NOT NULL,
    UsuarioId INT NOT NULL,
    DesdeEstatusId INT NOT NULL,
    HaciaEstatusId INT NOT NULL,
    FechaMovimiento DATETIME NOT NULL CONSTRAINT DF_TblPedidosBitacora_FechaMovimiento DEFAULT(GETDATE()),
    Notas VARCHAR(500) NULL,
    CONSTRAINT FK_TblPedidosBitacora_Pedido FOREIGN KEY(PedidoId) REFERENCES dbo.TblPedidos(PedidoId),
    CONSTRAINT FK_TblPedidosBitacora_Desde FOREIGN KEY(DesdeEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId),
    CONSTRAINT FK_TblPedidosBitacora_Hacia FOREIGN KEY(HaciaEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId)
);
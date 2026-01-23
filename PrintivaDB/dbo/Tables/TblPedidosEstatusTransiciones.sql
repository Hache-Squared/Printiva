CREATE TABLE dbo.TblPedidosEstatusTransiciones(
    PedidoEstatusTransicionId INT IDENTITY(1,1) PRIMARY KEY,
    DesdeEstatusId INT NOT NULL,
    HaciaEstatusId INT NOT NULL,
    CONSTRAINT UQ_TblPedidosEstatusTransiciones UNIQUE(DesdeEstatusId, HaciaEstatusId),
    CONSTRAINT FK_TblPedidosEstatusTransiciones_Desde FOREIGN KEY(DesdeEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId),
    CONSTRAINT FK_TblPedidosEstatusTransiciones_Hacia FOREIGN KEY(HaciaEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId)
);
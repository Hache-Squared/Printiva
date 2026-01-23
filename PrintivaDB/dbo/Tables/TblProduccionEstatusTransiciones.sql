CREATE TABLE dbo.TblProduccionEstatusTransiciones
(
    DesdeEstatusId INT NOT NULL,
    HaciaEstatusId INT NOT NULL,
    CONSTRAINT PK_TblProduccionEstatusTransiciones PRIMARY KEY (DesdeEstatusId, HaciaEstatusId),
    CONSTRAINT FK_ProdTrans_Desde FOREIGN KEY (DesdeEstatusId) REFERENCES dbo.TblProduccionEstatus(ProduccionEstatusId),
    CONSTRAINT FK_ProdTrans_Hacia FOREIGN KEY (HaciaEstatusId) REFERENCES dbo.TblProduccionEstatus(ProduccionEstatusId)
);
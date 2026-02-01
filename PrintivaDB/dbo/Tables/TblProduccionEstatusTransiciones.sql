CREATE TABLE [dbo].[TblProduccionEstatusTransiciones] (
    [DesdeEstatusId] INT NOT NULL,
    [HaciaEstatusId] INT NOT NULL
);
GO

ALTER TABLE [dbo].[TblProduccionEstatusTransiciones]
    ADD CONSTRAINT [FK_ProdTrans_Hacia] FOREIGN KEY ([HaciaEstatusId]) REFERENCES [dbo].[TblProduccionEstatus] ([ProduccionEstatusId]);
GO

ALTER TABLE [dbo].[TblProduccionEstatusTransiciones]
    ADD CONSTRAINT [FK_ProdTrans_Desde] FOREIGN KEY ([DesdeEstatusId]) REFERENCES [dbo].[TblProduccionEstatus] ([ProduccionEstatusId]);
GO

ALTER TABLE [dbo].[TblProduccionEstatusTransiciones]
    ADD CONSTRAINT [PK_TblProduccionEstatusTransiciones] PRIMARY KEY CLUSTERED ([DesdeEstatusId] ASC, [HaciaEstatusId] ASC);
GO


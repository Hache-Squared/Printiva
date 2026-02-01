CREATE TABLE [dbo].[TblPedidosEstatusTransiciones] (
    [PedidoEstatusTransicionId] INT IDENTITY (1, 1) NOT NULL,
    [DesdeEstatusId]            INT NOT NULL,
    [HaciaEstatusId]            INT NOT NULL,
    PRIMARY KEY CLUSTERED ([PedidoEstatusTransicionId] ASC)
);
GO

ALTER TABLE [dbo].[TblPedidosEstatusTransiciones]
    ADD CONSTRAINT [UQ_TblPedidosEstatusTransiciones] UNIQUE NONCLUSTERED ([DesdeEstatusId] ASC, [HaciaEstatusId] ASC);
GO

ALTER TABLE [dbo].[TblPedidosEstatusTransiciones]
    ADD CONSTRAINT [FK_TblPedidosEstatusTransiciones_Desde] FOREIGN KEY ([DesdeEstatusId]) REFERENCES [dbo].[TblPedidoEstatus] ([PedidoEstatusId]);
GO

ALTER TABLE [dbo].[TblPedidosEstatusTransiciones]
    ADD CONSTRAINT [FK_TblPedidosEstatusTransiciones_Hacia] FOREIGN KEY ([HaciaEstatusId]) REFERENCES [dbo].[TblPedidoEstatus] ([PedidoEstatusId]);
GO


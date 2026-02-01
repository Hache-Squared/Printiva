CREATE TABLE [dbo].[TblPedidosBitacora] (
    [PedidoBitacoraId] INT           IDENTITY (1, 1) NOT NULL,
    [PedidoId]         INT           NOT NULL,
    [UsuarioId]        INT           NOT NULL,
    [DesdeEstatusId]   INT           NOT NULL,
    [HaciaEstatusId]   INT           NOT NULL,
    [FechaMovimiento]  DATETIME      NOT NULL,
    [Notas]            VARCHAR (500) NULL,
    PRIMARY KEY CLUSTERED ([PedidoBitacoraId] ASC)
);
GO

ALTER TABLE [dbo].[TblPedidosBitacora]
    ADD CONSTRAINT [FK_TblPedidosBitacora_Pedido] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[TblPedidos] ([PedidoId]);
GO

ALTER TABLE [dbo].[TblPedidosBitacora]
    ADD CONSTRAINT [FK_TblPedidosBitacora_Desde] FOREIGN KEY ([DesdeEstatusId]) REFERENCES [dbo].[TblPedidoEstatus] ([PedidoEstatusId]);
GO

ALTER TABLE [dbo].[TblPedidosBitacora]
    ADD CONSTRAINT [FK_TblPedidosBitacora_Hacia] FOREIGN KEY ([HaciaEstatusId]) REFERENCES [dbo].[TblPedidoEstatus] ([PedidoEstatusId]);
GO

ALTER TABLE [dbo].[TblPedidosBitacora]
    ADD CONSTRAINT [DF_TblPedidosBitacora_FechaMovimiento] DEFAULT (getdate()) FOR [FechaMovimiento];
GO


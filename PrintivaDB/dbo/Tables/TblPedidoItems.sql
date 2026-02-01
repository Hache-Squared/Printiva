CREATE TABLE [dbo].[TblPedidoItems] (
    [PedidoItemId]           INT             IDENTITY (1, 1) NOT NULL,
    [PedidoId]               INT             NOT NULL,
    [ProductoId]             INT             NOT NULL,
    [Cantidad]               INT             NOT NULL,
    [PrecioUnitarioEstimado] DECIMAL (18, 2) NULL,
    [Notas]                  NVARCHAR (250)  NULL,
    [EstaActivo]             BIT             NOT NULL,
    PRIMARY KEY CLUSTERED ([PedidoItemId] ASC)
);
GO

ALTER TABLE [dbo].[TblPedidoItems]
    ADD CONSTRAINT [FK_TblPedidoItems_Pedidos] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[TblPedidos] ([PedidoId]);
GO

ALTER TABLE [dbo].[TblPedidoItems]
    ADD CONSTRAINT [DF_TblPedidoItems_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


CREATE TABLE [dbo].[TblProduccionInventarioConsumo] (
    [ProduccionInventarioConsumoId] INT             IDENTITY (1, 1) NOT NULL,
    [ProduccionItemId]              INT             NOT NULL,
    [RecetaId]                      INT             NOT NULL,
    [InventarioId]                  INT             NOT NULL,
    [Cantidad]                      DECIMAL (10, 2) NOT NULL,
    [InventarioUnidadId]            INT             NULL,
    [UsuarioId]                     INT             NOT NULL,
    [Fecha]                         DATETIME2 (0)   NOT NULL,
    [PedidoId]                      INT             NULL,
    [PedidoItemId]                  INT             NULL,
    [ProductoId]                    INT             NULL,
    [CantidadItem]                  INT             NULL,
    [DesdeEstatusId]                INT             NULL,
    [HaciaEstatusId]                INT             NULL,
    [Notas]                         NVARCHAR (500)  NULL,
    [RecetaNombre]                  NVARCHAR (200)  NULL,
    [InsumoNombre]                  NVARCHAR (200)  NULL,
    [UnidadNombre]                  NVARCHAR (100)  NULL,
    [DisponibleAntes]               DECIMAL (18, 2) NULL,
    [DisponibleDespues]             DECIMAL (18, 2) NULL,
    PRIMARY KEY CLUSTERED ([ProduccionInventarioConsumoId] ASC)
);
GO
/*
CREATE UNIQUE NONCLUSTERED INDEX [UX_TblProduccionInventarioConsumo_ItemInv]
    ON [dbo].[TblProduccionInventarioConsumo]([ProduccionItemId] ASC, [InventarioId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_TblProdInvConsumo_Fecha]
    ON [dbo].[TblProduccionInventarioConsumo]([Fecha] ASC)
    INCLUDE([PedidoId], [InventarioId], [Cantidad], [UsuarioId], [ProductoId], [RecetaId]);
GO

CREATE NONCLUSTERED INDEX [IX_TblProdInvConsumo_Pedido]
    ON [dbo].[TblProduccionInventarioConsumo]([PedidoId] ASC, [Fecha] ASC)
    INCLUDE([InventarioId], [Cantidad], [UsuarioId], [ProductoId], [RecetaId]);
GO
*/
ALTER TABLE [dbo].[TblProduccionInventarioConsumo]
    ADD CONSTRAINT [DF_TblProduccionInventarioConsumo_Fecha] DEFAULT (sysdatetime()) FOR [Fecha];
GO


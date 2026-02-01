CREATE TABLE [dbo].[TblProduccionItems] (
    [ProduccionItemId]    INT             IDENTITY (1, 1) NOT NULL,
    [PedidoId]            INT             NOT NULL,
    [PedidoItemId]        INT             NOT NULL,
    [UsuarioId]           INT             NOT NULL,
    [ProductoId]          INT             NOT NULL,
    [Cantidad]            INT             NOT NULL,
    [ProduccionEstatusId] INT             NOT NULL,
    [Notas]               NVARCHAR (500)  NULL,
    [FechaCreacion]       DATETIME        NOT NULL,
    [FechaActualizacion]  DATETIME        NULL,
    [EstaActivo]          BIT             NOT NULL,
    [ImpresoraId]         INT             NULL,
    [NotasOperativas]     NVARCHAR (500)  NULL,
    [PesoEstimadoGr]      DECIMAL (10, 2) NULL,
    [PesoRealGr]          DECIMAL (10, 2) NULL,
    [FechaInicio]         DATETIME2 (0)   NULL,
    [FechaFin]            DATETIME2 (0)   NULL,
    [InventarioAplicado]  BIT             NOT NULL,
    [RecetaId]            INT             NULL,
    PRIMARY KEY CLUSTERED ([ProduccionItemId] ASC)
);
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [UX_TblProduccionItems_PedidoItem] UNIQUE NONCLUSTERED ([PedidoItemId] ASC);
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [DF_TblProduccionItems_InventarioAplicado] DEFAULT ((0)) FOR [InventarioAplicado];
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [DF_TblProduccionItems_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [DF_TblProduccionItems_FechaCreacion] DEFAULT (getdate()) FOR [FechaCreacion];
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [FK_TblProduccionItems_Impresoras] FOREIGN KEY ([ImpresoraId]) REFERENCES [dbo].[TblImpresoras] ([ImpresoraId]);
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [FK_TblProduccionItems_TblRecetas] FOREIGN KEY ([RecetaId]) REFERENCES [dbo].[TblRecetas] ([RecetaId]);
GO

ALTER TABLE [dbo].[TblProduccionItems]
    ADD CONSTRAINT [FK_TblProduccionItems_Estatus] FOREIGN KEY ([ProduccionEstatusId]) REFERENCES [dbo].[TblProduccionEstatus] ([ProduccionEstatusId]);
GO


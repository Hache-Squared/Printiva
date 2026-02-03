CREATE TABLE [dbo].[TblCompras] (
    [CompraId]          INT             IDENTITY (1, 1) NOT NULL,
    [Descripcion]       VARCHAR (MAX)   NULL,
    [CompraTipoId]      INT             NOT NULL,
    [FilamentoTipoId]   INT             NULL,
    [CostoTotal]        DECIMAL (10, 2) DEFAULT ((0)) NOT NULL,
    [CompraCategoriaId] INT             NOT NULL,
    [FechaCreacion]     DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [EstaActivo]        BIT             CONSTRAINT [DF_TblCompras_EstaActivo] DEFAULT ((1)) NOT NULL,
    [InventarioId]      INT             NULL,
    [Cantidad]          DECIMAL (10, 2) CONSTRAINT [DF_TblCompras_Cantidad] DEFAULT ((0)) NOT NULL,
    [CostoUnitario]     DECIMAL (18, 2) CONSTRAINT [DF_TblCompras_CostoUnitario] DEFAULT ((0)) NOT NULL,
    [UsuarioId]         INT             NULL,
    PRIMARY KEY CLUSTERED ([CompraId] ASC),
    CONSTRAINT [FK_TblCompras_TblComprasCategorias] FOREIGN KEY ([CompraCategoriaId]) REFERENCES [dbo].[TblComprasCategorias] ([CompraCategoriaId]),
    CONSTRAINT [FK_TblCompras_TblComprasTipos] FOREIGN KEY ([CompraTipoId]) REFERENCES [dbo].[TblComprasTipos] ([CompraTipoId]),
    CONSTRAINT [FK_TblCompras_TblFilamentosTipos] FOREIGN KEY ([FilamentoTipoId]) REFERENCES [dbo].[TblFilamentosTipos] ([FilamentoTipoId]),
    CONSTRAINT [FK_TblCompras_TblInventarios] FOREIGN KEY ([InventarioId]) REFERENCES [dbo].[TblInventarios] ([InventarioId]),
    CONSTRAINT [FK_TblCompras_Usuarios] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id])
);

GO

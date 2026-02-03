CREATE TABLE [dbo].[TblInventariosMovimientos] (
    [InventarioMovimientoId] INT             IDENTITY (1, 1) NOT NULL,
    [InventarioId]           INT             NOT NULL,
    [TipoMovimientoId]       INT             NOT NULL,
    [Cantidad]               DECIMAL (10, 2) NOT NULL,
    [Costo]                  DECIMAL (10, 2) DEFAULT ((0)) NULL,
    [FechaCreacion]          DATETIME        DEFAULT (getutcdate()) NULL,
    [UsuarioId]              INT             NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioMovimientoId] ASC),
    CONSTRAINT [FK_TblInventariosMovimientos_TblInventarios] FOREIGN KEY ([InventarioId]) REFERENCES [dbo].[TblInventarios] ([InventarioId]),
    CONSTRAINT [FK_TblInventariosMovimientos_TblInventariosMovimientoTipos] FOREIGN KEY ([TipoMovimientoId]) REFERENCES [dbo].[TblInventariosMovimientoTipos] ([TipoMovimientoId]),
    CONSTRAINT [FK_TblInventariosMovimientos_Usuarios] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id])
);
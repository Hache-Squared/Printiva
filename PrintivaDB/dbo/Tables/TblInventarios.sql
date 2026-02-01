CREATE TABLE [dbo].[TblInventarios] (
    [InventarioId]       INT             IDENTITY (1, 1) NOT NULL,
    [InventarioMarcaId]  INT             NOT NULL,
    [InventarioTipoId]   INT             NOT NULL,
    [InventarioNombreId] INT             NOT NULL,
    [InventarioColorId]  INT             NOT NULL,
    [Cantidad]           DECIMAL (10, 2) DEFAULT ((0)) NOT NULL,
    [InventarioUnidadId] INT             NOT NULL,
    [FechaCreacion]      DATETIME        DEFAULT (getutcdate()) NULL,
    [EstaActivo]         BIT             CONSTRAINT [DF_TblInventarios_EstaActivo] DEFAULT ((1)) NOT NULL,
    [CostoUnitario]      DECIMAL (18, 2) CONSTRAINT [DF_TblInventarios_CostoUnitario] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioId] ASC),
    CONSTRAINT [FK_TblInventarios_TblInventariosColores] FOREIGN KEY ([InventarioColorId]) REFERENCES [dbo].[TblInventariosColores] ([InventarioColorId]),
    CONSTRAINT [FK_TblInventarios_TblInventariosMarcas] FOREIGN KEY ([InventarioMarcaId]) REFERENCES [dbo].[TblInventariosMarcas] ([InventarioMarcaId]),
    CONSTRAINT [FK_TblInventarios_TblInventariosNombres] FOREIGN KEY ([InventarioNombreId]) REFERENCES [dbo].[TblInventariosNombres] ([InventarioNombreId]),
    CONSTRAINT [FK_TblInventarios_TblInventariosTipos] FOREIGN KEY ([InventarioTipoId]) REFERENCES [dbo].[TblInventariosTipos] ([InventarioTipoId]),
    CONSTRAINT [FK_TblInventarios_TblInventariosUnidades] FOREIGN KEY ([InventarioUnidadId]) REFERENCES [dbo].[TblInventariosUnidades] ([InventarioUnidadId])
);
GO
ALTER TABLE [dbo].[TblInventarios]
    ADD CONSTRAINT [DF_TblInventarios_CostoUnitario] DEFAULT ((0)) FOR [CostoUnitario];
GO


ALTER TABLE [dbo].[TblInventarios]
    ADD CONSTRAINT [DF_TblInventarios_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


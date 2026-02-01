CREATE TABLE [dbo].[TblRecetasInventarios] (
    [RecetaId]     INT             NOT NULL,
    [InventarioId] INT             NOT NULL,
    [Cantidad]     DECIMAL (10, 2) DEFAULT ((0)) NOT NULL,
    [EstaActivo]   BIT             CONSTRAINT [DF_TblRecetasInventarios_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RecetaId] ASC, [InventarioId] ASC),
    CONSTRAINT [FK_TblRecetasInventarios_TblInventarios] FOREIGN KEY ([InventarioId]) REFERENCES [dbo].[TblInventarios] ([InventarioId]),
    CONSTRAINT [FK_TblRecetasInventarios_TblRecetas] FOREIGN KEY ([RecetaId]) REFERENCES [dbo].[TblRecetas] ([RecetaId])
);
GO
ALTER TABLE [dbo].[TblRecetasInventarios]
    ADD CONSTRAINT [DF_TblRecetasInventarios_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


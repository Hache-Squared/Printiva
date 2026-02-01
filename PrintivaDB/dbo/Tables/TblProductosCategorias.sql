CREATE TABLE [dbo].[TblProductosCategorias] (
    [ProductoCategoriaId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]              VARCHAR (200) NOT NULL,
    [EstaActivo]          BIT           CONSTRAINT [DF_TblProductosCategorias_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductoCategoriaId] ASC)
);
GO
ALTER TABLE [dbo].[TblProductosCategorias]
    ADD CONSTRAINT [DF_TblProductosCategorias_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


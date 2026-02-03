CREATE TABLE [dbo].[TblComprasCategorias] (
    [CompraCategoriaId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]            VARCHAR (200) NOT NULL,
    [EstaActivo]        BIT           CONSTRAINT [DF_TblComprasCategorias_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([CompraCategoriaId] ASC)
);

GO
ALTER TABLE [dbo].[TblComprasCategorias]
    ADD CONSTRAINT [DF_TblComprasCategorias_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


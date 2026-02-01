CREATE TABLE [dbo].[TblProductos] (
    [ProductoId]          INT             IDENTITY (1, 1) NOT NULL,
    [Nombre]              VARCHAR (200)   NOT NULL,
    [ProductoCategoriaId] INT             NOT NULL,
    [SKU]                 VARCHAR (200)   NULL,
    [PrecioSugerido]      DECIMAL (18, 2) NULL,
    [EstaActivo]          BIT             CONSTRAINT [DF_TblProductos_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductoId] ASC),
    CONSTRAINT [FK_TblProductos_TblProductosCategorias] FOREIGN KEY ([ProductoCategoriaId]) REFERENCES [dbo].[TblProductosCategorias] ([ProductoCategoriaId])
);
GO

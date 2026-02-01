CREATE TABLE [dbo].[TblInventariosMarcas] (
    [InventarioMarcaId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]            VARCHAR (200) NOT NULL,
    [EstaActivo]        BIT           CONSTRAINT [DF_TblInventariosMarcas_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioMarcaId] ASC)
);
GO

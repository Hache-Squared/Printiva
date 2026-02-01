CREATE TABLE [dbo].[TblInventariosTipos] (
    [InventarioTipoId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]           VARCHAR (200) NOT NULL,
    [EstaActivo]       BIT           CONSTRAINT [DF_TblInventariosTipos_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioTipoId] ASC)
);
GO

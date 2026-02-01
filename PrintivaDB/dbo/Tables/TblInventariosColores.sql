CREATE TABLE [dbo].[TblInventariosColores] (
    [InventarioColorId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]            VARCHAR (200) NOT NULL,
    [Abreviatura]       VARCHAR (200) NOT NULL,
    [EstaActivo]        BIT           CONSTRAINT [DF_TblInventariosColores_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioColorId] ASC)
);
GO

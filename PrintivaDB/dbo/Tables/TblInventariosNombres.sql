CREATE TABLE [dbo].[TblInventariosNombres] (
    [InventarioNombreId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]             VARCHAR (200) NOT NULL,
    [Abreviatura]        VARCHAR (200) NOT NULL,
    [EstaActivo]         BIT           CONSTRAINT [DF_TblInventariosNombres_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InventarioNombreId] ASC)
);
GO
ALTER TABLE [dbo].[TblInventariosNombres]
    ADD CONSTRAINT [DF_TblInventariosNombres_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


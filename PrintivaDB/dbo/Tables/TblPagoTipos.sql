CREATE TABLE [dbo].[TblPagoTipos] (
    [PagoTipoId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]     VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([PagoTipoId] ASC)
);
GO


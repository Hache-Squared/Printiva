CREATE TABLE [dbo].[TblCotizacionConceptoTipos] (
    [ConceptoTipoId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]         VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([ConceptoTipoId] ASC)
);
GO


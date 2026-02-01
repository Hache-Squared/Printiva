CREATE TABLE [dbo].[TblCotizacionItems] (
    [CotizacionItemId] INT             IDENTITY (1, 1) NOT NULL,
    [CotizacionId]     INT             NOT NULL,
    [ConceptoTipoId]   INT             NOT NULL,
    [ProductoId]       INT             NULL,
    [Concepto]         VARCHAR (200)   NOT NULL,
    [Cantidad]         DECIMAL (10, 2) NOT NULL,
    [PrecioUnitario]   DECIMAL (10, 2) NOT NULL,
    [Notas]            VARCHAR (500)   NULL,
    [EstaActivo]       BIT             NOT NULL,
    PRIMARY KEY CLUSTERED ([CotizacionItemId] ASC)
);
GO

ALTER TABLE [dbo].[TblCotizacionItems]
    ADD CONSTRAINT [FK_TblCotizacionItems_ConceptoTipos] FOREIGN KEY ([ConceptoTipoId]) REFERENCES [dbo].[TblCotizacionConceptoTipos] ([ConceptoTipoId]);
GO

ALTER TABLE [dbo].[TblCotizacionItems]
    ADD CONSTRAINT [FK_TblCotizacionItems_Cotizaciones] FOREIGN KEY ([CotizacionId]) REFERENCES [dbo].[TblCotizaciones] ([CotizacionId]);
GO

ALTER TABLE [dbo].[TblCotizacionItems]
    ADD CONSTRAINT [DF_TblCotizacionItems_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


CREATE TABLE [dbo].[TblRecetas] (
    [RecetaId]        INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]          VARCHAR (200) NOT NULL,
    [ProductoId]      INT           NOT NULL,
    [TiempoImpresion] VARCHAR (200) NOT NULL,
    [EstaActivo]      BIT           CONSTRAINT [DF_TblRecetas_EstaActivo] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RecetaId] ASC)
);
GO
ALTER TABLE [dbo].[TblRecetas]
    ADD CONSTRAINT [DF_TblRecetas_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


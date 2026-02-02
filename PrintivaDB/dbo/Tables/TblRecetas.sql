CREATE TABLE [dbo].[TblRecetas] (
    [RecetaId]           INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]             VARCHAR (200) NOT NULL,
    [ProductoId]         INT           NOT NULL,
    [TiempoImpresion]    VARCHAR (200) NOT NULL,
    [EstaActivo]         BIT           CONSTRAINT [DF_TblRecetas_EstaActivo] DEFAULT ((1)) NOT NULL,
    [TiempoImpresionMin] INT           NULL,
    [TiempoPostMin]      INT           NULL,
    PRIMARY KEY CLUSTERED ([RecetaId] ASC),
    CONSTRAINT [CK_TblRecetas_TiempoImpresionMin_Positive] CHECK ([TiempoImpresionMin] IS NULL OR [TiempoImpresionMin]>=(0)),
    CONSTRAINT [CK_TblRecetas_TiempoPostMin_Positive] CHECK ([TiempoPostMin] IS NULL OR [TiempoPostMin]>=(0))
);
GO


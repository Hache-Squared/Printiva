CREATE TABLE [dbo].[TblCotizacionesEstatus] (
    [CotizacionEstatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]              VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([CotizacionEstatusId] ASC)
);
GO


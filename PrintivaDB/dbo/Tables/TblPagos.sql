CREATE TABLE [dbo].[TblPagos] (
    [PagoId]        INT             IDENTITY (1, 1) NOT NULL,
    [CotizacionId]  INT             NOT NULL,
    [PagoTipoId]    INT             NOT NULL,
    [Monto]         DECIMAL (10, 2) NOT NULL,
    [FechaPago]     DATETIME        NOT NULL,
    [Metodo]        VARCHAR (100)   NULL,
    [Referencia]    VARCHAR (200)   NULL,
    [Notas]         VARCHAR (500)   NULL,
    [FechaCreacion] DATETIME        NOT NULL,
    [EstaActivo]    BIT             NOT NULL,
    PRIMARY KEY CLUSTERED ([PagoId] ASC)
);
GO

ALTER TABLE [dbo].[TblPagos]
    ADD CONSTRAINT [DF_TblPagos_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblPagos]
    ADD CONSTRAINT [DF_TblPagos_FechaCreacion] DEFAULT (getdate()) FOR [FechaCreacion];
GO

ALTER TABLE [dbo].[TblPagos]
    ADD CONSTRAINT [FK_TblPagos_Cotizaciones] FOREIGN KEY ([CotizacionId]) REFERENCES [dbo].[TblCotizaciones] ([CotizacionId]);
GO

ALTER TABLE [dbo].[TblPagos]
    ADD CONSTRAINT [FK_TblPagos_PagoTipos] FOREIGN KEY ([PagoTipoId]) REFERENCES [dbo].[TblPagoTipos] ([PagoTipoId]);
GO


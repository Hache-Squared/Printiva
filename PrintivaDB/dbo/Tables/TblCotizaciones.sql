CREATE TABLE [dbo].[TblCotizaciones] (
    [CotizacionId]        INT           IDENTITY (1, 1) NOT NULL,
    [PedidoId]            INT           NOT NULL,
    [CotizacionEstatusId] INT           NOT NULL,
    [FechaCreacion]       DATETIME      NOT NULL,
    [FechaVigencia]       DATETIME      NULL,
    [Notas]               VARCHAR (MAX) NULL,
    [EstaActivo]          BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([CotizacionId] ASC)
);
GO

ALTER TABLE [dbo].[TblCotizaciones]
    ADD CONSTRAINT [FK_TblCotizaciones_TblPedidos] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[TblPedidos] ([PedidoId]);
GO

ALTER TABLE [dbo].[TblCotizaciones]
    ADD CONSTRAINT [FK_TblCotizaciones_Estatus] FOREIGN KEY ([CotizacionEstatusId]) REFERENCES [dbo].[TblCotizacionesEstatus] ([CotizacionEstatusId]);
GO

ALTER TABLE [dbo].[TblCotizaciones]
    ADD CONSTRAINT [DF_TblCotizaciones_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


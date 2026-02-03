CREATE TABLE [dbo].[TblComprasTipos] (
    [CompraTipoId]          INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]                VARCHAR (200) NOT NULL,
    [EstaActivo]            BIT           CONSTRAINT [DF_TblComprasTipos_EstaActivo] DEFAULT ((1)) NOT NULL,
    [EsInventario]          BIT           CONSTRAINT [DF_TblComprasTipos_EsInventario] DEFAULT ((0)) NOT NULL,
    [RequiereFilamentoTipo] BIT           CONSTRAINT [DF_TblComprasTipos_RequiereFilamento] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([CompraTipoId] ASC)
);

GO
ALTER TABLE [dbo].[TblComprasTipos]
    ADD CONSTRAINT [DF_TblComprasTipos_EsInventario] DEFAULT ((0)) FOR [EsInventario];
GO


ALTER TABLE [dbo].[TblComprasTipos]
    ADD CONSTRAINT [DF_TblComprasTipos_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


ALTER TABLE [dbo].[TblComprasTipos]
    ADD CONSTRAINT [DF_TblComprasTipos_RequiereFilamento] DEFAULT ((0)) FOR [RequiereFilamentoTipo];
GO


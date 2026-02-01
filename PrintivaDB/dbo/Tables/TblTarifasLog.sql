CREATE TABLE [dbo].[TblTarifasLog] (
    [TarifaLogId]        INT             IDENTITY (1, 1) NOT NULL,
    [TarifaId]           INT             NOT NULL,
    [UsuarioId]          INT             NOT NULL,
    [TarifaConceptoId]   INT             NOT NULL,
    [ImpresoraId]        INT             NULL,
    [InventarioTipoId]   INT             NULL,
    [InventarioNombreId] INT             NULL,
    [Accion]             VARCHAR (20)    NOT NULL,
    [MontoAntes]         DECIMAL (18, 4) NULL,
    [MonedaAntes]        CHAR (3)        NULL,
    [MontoDespues]       DECIMAL (18, 4) NULL,
    [MonedaDespues]      CHAR (3)        NULL,
    [EstaActivoAntes]    BIT             NULL,
    [EstaActivoDespues]  BIT             NULL,
    [FechaAccion]        DATETIME2 (0)   NOT NULL
);
GO

ALTER TABLE [dbo].[TblTarifasLog]
    ADD CONSTRAINT [PK_TblTarifasLog] PRIMARY KEY CLUSTERED ([TarifaLogId] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_TblTarifasLog_Usuario_Fecha]
    ON [dbo].[TblTarifasLog]([UsuarioId] ASC, [FechaAccion] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_TblTarifasLog_TarifaId_Fecha]
    ON [dbo].[TblTarifasLog]([TarifaId] ASC, [FechaAccion] DESC);
GO

ALTER TABLE [dbo].[TblTarifasLog]
    ADD CONSTRAINT [DF_TblTarifasLog_FechaAccion] DEFAULT (sysdatetime()) FOR [FechaAccion];
GO


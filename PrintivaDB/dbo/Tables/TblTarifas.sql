CREATE TABLE [dbo].[TblTarifas] (
    [TarifaId]              INT             IDENTITY (1, 1) NOT NULL,
    [UsuarioId]             INT             NOT NULL,
    [TarifaConceptoId]      INT             NOT NULL,
    [ImpresoraId]           INT             NULL,
    [InventarioTipoId]      INT             NULL,
    [InventarioNombreId]    INT             NULL,
    [Monto]                 DECIMAL (18, 4) NOT NULL,
    [Moneda]                CHAR (3)        CONSTRAINT [DF_TblTarifas_Moneda] DEFAULT ('MXN') NOT NULL,
    [EstaActivo]            BIT             CONSTRAINT [DF_TblTarifas_EstaActivo] DEFAULT ((1)) NOT NULL,
    [FechaCreacion]         DATETIME2 (0)   CONSTRAINT [DF_TblTarifas_FechaCreacion] DEFAULT (sysdatetime()) NOT NULL,
    [FechaActualizacion]    DATETIME2 (0)   NULL,
    [ImpresoraIdKey]        AS              (isnull([ImpresoraId],(0))) PERSISTED NOT NULL,
    [InventarioTipoIdKey]   AS              (isnull([InventarioTipoId],(0))) PERSISTED NOT NULL,
    [InventarioNombreIdKey] AS              (isnull([InventarioNombreId],(0))) PERSISTED NOT NULL,
    [Nombre]                NVARCHAR (80)   CONSTRAINT [DF_TblTarifas_Nombre] DEFAULT (N'') NOT NULL,
    [Orden]                 INT             CONSTRAINT [DF_TblTarifas_Orden] DEFAULT ((100)) NOT NULL,
    [InventarioId]          INT             NULL,
    CONSTRAINT [PK_TblTarifas] PRIMARY KEY CLUSTERED ([TarifaId] ASC),
    CONSTRAINT [FK_TblTarifas_TarifaConceptos] FOREIGN KEY ([TarifaConceptoId]) REFERENCES [dbo].[TblTarifaConceptos] ([TarifaConceptoId])
);
GO

CREATE NONCLUSTERED INDEX [IX_TblTarifas_Usuario_Concepto]
    ON [dbo].[TblTarifas]([UsuarioId] ASC, [TarifaConceptoId] ASC, [EstaActivo] ASC)
    INCLUDE([Monto], [Moneda], [ImpresoraId], [InventarioTipoId], [InventarioNombreId], [FechaCreacion], [FechaActualizacion]);
GO

CREATE NONCLUSTERED INDEX [IX_TblTarifas_Lookup]
    ON [dbo].[TblTarifas]([UsuarioId] ASC, [TarifaConceptoId] ASC, [EstaActivo] ASC, [ImpresoraId] ASC, [InventarioId] ASC)
    INCLUDE([Monto], [Moneda], [Nombre], [Orden], [FechaCreacion], [FechaActualizacion]);
GO


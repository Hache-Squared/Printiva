CREATE TABLE [dbo].[TblTarifas] (
    [TarifaId]              INT             IDENTITY (1, 1) NOT NULL,
    [UsuarioId]             INT             NOT NULL,
    [TarifaConceptoId]      INT             NOT NULL,
    [ImpresoraId]           INT             NULL,
    [InventarioTipoId]      INT             NULL,
    [InventarioNombreId]    INT             NULL,
    [Monto]                 DECIMAL (18, 4) NOT NULL,
    [Moneda]                CHAR (3)        NOT NULL,
    [EstaActivo]            BIT             NOT NULL,
    [FechaCreacion]         DATETIME2 (0)   NOT NULL,
    [FechaActualizacion]    DATETIME2 (0)   NULL,
    [ImpresoraIdKey]        AS              (isnull([ImpresoraId],(0))) PERSISTED NOT NULL,
    [InventarioTipoIdKey]   AS              (isnull([InventarioTipoId],(0))) PERSISTED NOT NULL,
    [InventarioNombreIdKey] AS              (isnull([InventarioNombreId],(0))) PERSISTED NOT NULL
);
GO

ALTER TABLE [dbo].[TblTarifas]
    ADD CONSTRAINT [DF_TblTarifas_Moneda] DEFAULT ('MXN') FOR [Moneda];
GO

ALTER TABLE [dbo].[TblTarifas]
    ADD CONSTRAINT [DF_TblTarifas_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblTarifas]
    ADD CONSTRAINT [DF_TblTarifas_FechaCreacion] DEFAULT (sysdatetime()) FOR [FechaCreacion];
GO

ALTER TABLE [dbo].[TblTarifas]
    ADD CONSTRAINT [FK_TblTarifas_TarifaConceptos] FOREIGN KEY ([TarifaConceptoId]) REFERENCES [dbo].[TblTarifaConceptos] ([TarifaConceptoId]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_TblTarifas_Activo_Scope]
    ON [dbo].[TblTarifas]([UsuarioId] ASC, [TarifaConceptoId] ASC, [ImpresoraIdKey] ASC, [InventarioTipoIdKey] ASC, [InventarioNombreIdKey] ASC) WHERE ([EstaActivo]=(1));
GO

CREATE NONCLUSTERED INDEX [IX_TblTarifas_Usuario_Concepto]
    ON [dbo].[TblTarifas]([UsuarioId] ASC, [TarifaConceptoId] ASC, [EstaActivo] ASC)
    INCLUDE([Monto], [Moneda], [ImpresoraId], [InventarioTipoId], [InventarioNombreId], [FechaCreacion], [FechaActualizacion]);
GO

ALTER TABLE [dbo].[TblTarifas]
    ADD CONSTRAINT [PK_TblTarifas] PRIMARY KEY CLUSTERED ([TarifaId] ASC);
GO


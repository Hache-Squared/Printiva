CREATE TABLE [dbo].[TblTarifaConceptos] (
    [TarifaConceptoId]   INT            IDENTITY (1, 1) NOT NULL,
    [Codigo]             VARCHAR (40)   NOT NULL,
    [Nombre]             NVARCHAR (120) NOT NULL,
    [Unidad]             NVARCHAR (30)  NOT NULL,
    [Orden]              INT            NOT NULL,
    [EstaActivo]         BIT            NOT NULL,
    [FechaCreacion]      DATETIME2 (0)  NOT NULL,
    [FechaActualizacion] DATETIME2 (0)  NULL
);
GO

ALTER TABLE [dbo].[TblTarifaConceptos]
    ADD CONSTRAINT [PK_TblTarifaConceptos] PRIMARY KEY CLUSTERED ([TarifaConceptoId] ASC);
GO

ALTER TABLE [dbo].[TblTarifaConceptos]
    ADD CONSTRAINT [DF_TblTarifaConceptos_Orden] DEFAULT ((100)) FOR [Orden];
GO

ALTER TABLE [dbo].[TblTarifaConceptos]
    ADD CONSTRAINT [DF_TblTarifaConceptos_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblTarifaConceptos]
    ADD CONSTRAINT [DF_TblTarifaConceptos_FechaCreacion] DEFAULT (sysdatetime()) FOR [FechaCreacion];
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_TblTarifaConceptos_Codigo]
    ON [dbo].[TblTarifaConceptos]([Codigo] ASC);
GO


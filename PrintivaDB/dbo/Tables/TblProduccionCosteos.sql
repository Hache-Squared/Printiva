CREATE TABLE [dbo].[TblProduccionCosteos] (
    [ProduccionCosteoId] INT             IDENTITY (1, 1) NOT NULL,
    [ProduccionItemId]   INT             NOT NULL,
    [UsuarioId]          INT             NOT NULL,
    [TipoCodigo]         VARCHAR (30)    NOT NULL,
    [Moneda]             VARCHAR (3)     NOT NULL,
    [Total]              DECIMAL (18, 4) NOT NULL,
    [Fecha]              DATETIME2 (0)   NOT NULL,
    [EstaActivo]         BIT             NOT NULL
);
GO

ALTER TABLE [dbo].[TblProduccionCosteos]
    ADD CONSTRAINT [DF_TblProduccionCosteos_Fecha] DEFAULT (sysdatetime()) FOR [Fecha];
GO

ALTER TABLE [dbo].[TblProduccionCosteos]
    ADD CONSTRAINT [DF_TblProduccionCosteos_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_TblProduccionCosteos_Item_Tipo_Usuario]
    ON [dbo].[TblProduccionCosteos]([ProduccionItemId] ASC, [UsuarioId] ASC, [TipoCodigo] ASC) WHERE ([EstaActivo]=(1));
GO

ALTER TABLE [dbo].[TblProduccionCosteos]
    ADD CONSTRAINT [PK_TblProduccionCosteos] PRIMARY KEY CLUSTERED ([ProduccionCosteoId] ASC);
GO


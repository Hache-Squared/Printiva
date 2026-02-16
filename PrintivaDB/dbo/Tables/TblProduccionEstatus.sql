CREATE TABLE [dbo].[TblProduccionEstatus] (
    [ProduccionEstatusId] INT            IDENTITY (1, 1) NOT NULL,
    [Nombre]              NVARCHAR (100) NOT NULL,
    [Orden]               INT            NOT NULL,
    [BadgeClass]          VARCHAR (60)   NOT NULL,
    [EstaActivo]          BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([ProduccionEstatusId] ASC)
);
GO

--CREATE UNIQUE NONCLUSTERED INDEX [UX_TblProduccionEstatus_Nombre]
--    ON [dbo].[TblProduccionEstatus]([Nombre] ASC) WHERE ([EstaActivo]=(1));
--GO

ALTER TABLE [dbo].[TblProduccionEstatus]
    ADD CONSTRAINT [DF_TblProduccionEstatus_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblProduccionEstatus]
    ADD CONSTRAINT [DF_TblProduccionEstatus_Badge] DEFAULT ('bg-secondary') FOR [BadgeClass];
GO


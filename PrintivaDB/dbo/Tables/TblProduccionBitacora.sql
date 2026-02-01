CREATE TABLE [dbo].[TblProduccionBitacora] (
    [ProduccionBitacoraId] INT            IDENTITY (1, 1) NOT NULL,
    [ProduccionItemId]     INT            NOT NULL,
    [PedidoId]             INT            NOT NULL,
    [PedidoItemId]         INT            NOT NULL,
    [UsuarioId]            INT            NOT NULL,
    [DesdeEstatusId]       INT            NOT NULL,
    [HaciaEstatusId]       INT            NOT NULL,
    [Notas]                NVARCHAR (500) NULL,
    [Fecha]                DATETIME       NOT NULL,
    PRIMARY KEY CLUSTERED ([ProduccionBitacoraId] ASC)
);
GO

ALTER TABLE [dbo].[TblProduccionBitacora]
    ADD CONSTRAINT [DF_TblProduccionBitacora_Fecha] DEFAULT (getdate()) FOR [Fecha];
GO


CREATE TABLE [dbo].[TblProduccionCosteosDetalle] (
    [ProduccionCosteoDetalleId] INT             IDENTITY (1, 1) NOT NULL,
    [ProduccionCosteoId]        INT             NOT NULL,
    [ConceptoCodigo]            VARCHAR (50)    NOT NULL,
    [InventarioId]              INT             NULL,
    [ImpresoraId]               INT             NULL,
    [TarifaId]                  INT             NOT NULL,
    [TarifaNombre]              NVARCHAR (200)  NOT NULL,
    [TarifaOrden]               INT             NOT NULL,
    [MontoTarifa]               DECIMAL (18, 4) NOT NULL,
    [Cantidad]                  DECIMAL (18, 4) NOT NULL,
    [Subtotal]                  DECIMAL (18, 4) NOT NULL,
    [Moneda]                    VARCHAR (3)     NOT NULL,
    [Fecha]                     DATETIME2 (0)   NOT NULL
);
GO

ALTER TABLE [dbo].[TblProduccionCosteosDetalle]
    ADD CONSTRAINT [DF_TblProduccionCosteosDetalle_Fecha] DEFAULT (sysdatetime()) FOR [Fecha];
GO

ALTER TABLE [dbo].[TblProduccionCosteosDetalle]
    ADD CONSTRAINT [PK_TblProduccionCosteosDetalle] PRIMARY KEY CLUSTERED ([ProduccionCosteoDetalleId] ASC);
GO

ALTER TABLE [dbo].[TblProduccionCosteosDetalle]
    ADD CONSTRAINT [FK_TblProduccionCosteosDetalle_Costeo] FOREIGN KEY ([ProduccionCosteoId]) REFERENCES [dbo].[TblProduccionCosteos] ([ProduccionCosteoId]);
GO


CREATE TABLE [dbo].[TblPedidoEstatus] (
    [PedidoEstatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Nombre]          NVARCHAR (60) NOT NULL,
    PRIMARY KEY CLUSTERED ([PedidoEstatusId] ASC)
);
GO


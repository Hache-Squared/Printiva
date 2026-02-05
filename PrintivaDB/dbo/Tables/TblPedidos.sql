CREATE TABLE [dbo].[TblPedidos] (
    [PedidoId]             INT             IDENTITY (1, 1) NOT NULL,
    [UsuarioId]            INT             NOT NULL,
    [ClienteId]            INT             NOT NULL,
    [PedidoEstatusId]      INT             NOT NULL,
    [FechaCreacion]        DATETIME2 (7)   DEFAULT (sysdatetime()) NOT NULL,
    [FechaEntregaEstimada] DATETIME2 (7)   NULL,
    [Notas]                NVARCHAR (500)  NULL,
    [TotalEstimado]        DECIMAL (18, 2) NULL,
    [EstaActivo]           BIT             CONSTRAINT [DF_TblPedidos_EstaActivo] DEFAULT ((1)) NOT NULL,
    [MostrarEnKanban]      BIT             CONSTRAINT [DF_TblPedidos_MostrarEnKanban] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PedidoId] ASC),
    CONSTRAINT [FK_TblPedidos_Clientes] FOREIGN KEY ([ClienteId]) REFERENCES [dbo].[TblClientes] ([ClienteId]),
    CONSTRAINT [FK_TblPedidos_Estatus] FOREIGN KEY ([PedidoEstatusId]) REFERENCES [dbo].[TblPedidoEstatus] ([PedidoEstatusId])
);
GO


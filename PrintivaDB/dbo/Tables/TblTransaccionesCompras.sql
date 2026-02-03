CREATE TABLE [dbo].[TblTransaccionesCompras] (
    [TransaccionCompraId] INT             IDENTITY (1, 1) NOT NULL,
    [CompraId]            INT             NOT NULL,
    [UsuarioId]           INT             NOT NULL,
    [Operacion]           VARCHAR (20)    NOT NULL,
    [Descripcion]         NVARCHAR (300)  NULL,
    [InventarioId]        INT             NULL,
    [Cantidad]            DECIMAL (18, 4) DEFAULT ((0)) NOT NULL,
    [CostoUnitario]       DECIMAL (18, 4) DEFAULT ((0)) NOT NULL,
    [CostoTotal]          DECIMAL (18, 4) DEFAULT ((0)) NOT NULL,
    [FechaCompra]         DATE            NOT NULL,
    [FechaLog]            DATETIME2 (0)   DEFAULT (sysdatetime()) NOT NULL,
    PRIMARY KEY CLUSTERED ([TransaccionCompraId] ASC)
);
GO


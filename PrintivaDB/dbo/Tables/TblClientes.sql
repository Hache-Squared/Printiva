CREATE TABLE [dbo].[TblClientes] (
    [ClienteId]          INT            IDENTITY (1, 1) NOT NULL,
    [UsuarioId]          INT            NOT NULL,
    [Nombre]             NVARCHAR (150) NOT NULL,
    [Telefono]           NVARCHAR (30)  NULL,
    [Instagram]          NVARCHAR (80)  NULL,
    [WhatsApp]           NVARCHAR (30)  NULL,
    [Email]              NVARCHAR (120) NULL,
    [Direccion]          NVARCHAR (250) NULL,
    [FechaCreacion]      DATETIME2 (7)  DEFAULT (sysdatetime()) NOT NULL,
    [EstaActivo]         BIT            CONSTRAINT [DF_TblClientes_EstaActivo] DEFAULT ((1)) NOT NULL,
    [FechaActualizacion] DATETIME2 (7)  NULL,
    PRIMARY KEY CLUSTERED ([ClienteId] ASC)
);
GO
ALTER TABLE [dbo].[TblClientes]
    ADD CONSTRAINT [DF_TblClientes_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO


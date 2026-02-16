CREATE TABLE [dbo].[TblImpresoras] (
    [ImpresoraId]        INT            IDENTITY (1, 1) NOT NULL,
    [UsuarioId]          INT            NOT NULL,
    [Nombre]             NVARCHAR (150) NOT NULL,
    [Modelo]             NVARCHAR (150) NULL,
    [Notas]              NVARCHAR (500) NULL,
    [EstaActivo]         BIT            NOT NULL,
    [FechaCreacion]      DATETIME2 (0)  NOT NULL,
    [FechaActualizacion] DATETIME2 (0)  NULL
);
GO

ALTER TABLE [dbo].[TblImpresoras]
    ADD CONSTRAINT [PK_TblImpresoras] PRIMARY KEY CLUSTERED ([ImpresoraId] ASC);
GO

ALTER TABLE [dbo].[TblImpresoras]
    ADD CONSTRAINT [FK_TblImpresoras_Usuarios] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO

ALTER TABLE [dbo].[TblImpresoras]
    ADD CONSTRAINT [DF_TblImpresoras_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblImpresoras]
    ADD CONSTRAINT [DF_TblImpresoras_FechaCreacion] DEFAULT (sysdatetime()) FOR [FechaCreacion];
GO


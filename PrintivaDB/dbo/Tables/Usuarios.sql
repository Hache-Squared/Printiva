CREATE TABLE [dbo].[Usuarios] (
    [Id]                 INT            IDENTITY (1, 1) NOT NULL,
    [Email]              NVARCHAR (256) NOT NULL,
    [EmailNormalizado]   NVARCHAR (256) NOT NULL,
    [PasswordHash]       NVARCHAR (MAX) NOT NULL,
    [Nombre]             NVARCHAR (150) NULL,
    [EstaActivo]         BIT            CONSTRAINT [DF_Usuarios_EstaActivo] DEFAULT ((1)) NOT NULL,
    [EsAdmin]            BIT            CONSTRAINT [DF_Usuarios_EsAdmin] DEFAULT ((0)) NOT NULL,
    [FechaCreacion]      DATETIME2 (0)  CONSTRAINT [DF_Usuarios_FechaCreacion] DEFAULT (sysutcdatetime()) NOT NULL,
    [FechaActualizacion] DATETIME2 (0)  NULL,
    CONSTRAINT [PK_Usuarios] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
--CREATE UNIQUE NONCLUSTERED INDEX [UX_Usuarios_EmailNormalizado]
--    ON [dbo].[Usuarios]([EmailNormalizado] ASC);
--GO


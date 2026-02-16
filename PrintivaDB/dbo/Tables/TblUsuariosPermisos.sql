CREATE TABLE [dbo].[TblUsuariosPermisos] (
    [UsuarioPermisoId] INT            IDENTITY (1, 1) NOT NULL,
    [UsuarioId]        INT            NOT NULL,
    [PermisoKey]       NVARCHAR (100) NOT NULL,
    [EstaActivo]       BIT            NOT NULL,
    [FechaCreacion]    DATETIME2 (0)  NOT NULL,
    PRIMARY KEY CLUSTERED ([UsuarioPermisoId] ASC)
);
GO

ALTER TABLE [dbo].[TblUsuariosPermisos]
    ADD CONSTRAINT [DF_TblUsuariosPermisos_FechaCreacion] DEFAULT (sysutcdatetime()) FOR [FechaCreacion];
GO

ALTER TABLE [dbo].[TblUsuariosPermisos]
    ADD CONSTRAINT [DF_TblUsuariosPermisos_EstaActivo] DEFAULT ((1)) FOR [EstaActivo];
GO

ALTER TABLE [dbo].[TblUsuariosPermisos]
    ADD CONSTRAINT [FK_TblUsuariosPermisos_Usuarios] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO

--CREATE UNIQUE NONCLUSTERED INDEX [UX_TblUsuariosPermisos_Usuario_Permiso]
--    ON [dbo].[TblUsuariosPermisos]([UsuarioId] ASC, [PermisoKey] ASC);
--GO


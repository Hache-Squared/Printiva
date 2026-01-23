/* =========================
   IMPRESORAS (CRUD)
========================= */

IF OBJECT_ID('dbo.TblImpresoras','U') IS NULL
BEGIN
    CREATE TABLE dbo.TblImpresoras
    (
        ImpresoraId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblImpresoras PRIMARY KEY,
        UsuarioId INT NOT NULL,
        Nombre NVARCHAR(150) NOT NULL,
        Modelo NVARCHAR(150) NULL,
        Notas NVARCHAR(500) NULL,
        EstaActivo BIT NOT NULL CONSTRAINT DF_TblImpresoras_EstaActivo DEFAULT(1),
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TblImpresoras_FechaCreacion DEFAULT(SYSDATETIME()),
        FechaActualizacion DATETIME2(0) NULL
    );

    ALTER TABLE dbo.TblImpresoras
      ADD CONSTRAINT FK_TblImpresoras_Usuarios
      FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios(Id);

    -- Evita duplicados en impresoras activas por usuario (sin hardcodear)
    CREATE UNIQUE INDEX UX_TblImpresoras_Usuario_Nombre_Activo
      ON dbo.TblImpresoras(UsuarioId, Nombre)
      WHERE EstaActivo = 1;

    CREATE INDEX IX_TblImpresoras_Usuario_Activo
      ON dbo.TblImpresoras(UsuarioId, EstaActivo);
END
GO

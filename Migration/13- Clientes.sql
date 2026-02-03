/* =========================================================
   CLIENTES - TABLA + COLUMNAS (idempotente)
   ========================================================= */
IF OBJECT_ID('dbo.TblClientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TblClientes
    (
        ClienteId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UsuarioId INT NOT NULL,

        Nombre NVARCHAR(150) NOT NULL,
        Telefono NVARCHAR(30) NULL,
        Instagram NVARCHAR(80) NULL,
        WhatsApp NVARCHAR(30) NULL,
        Email NVARCHAR(120) NULL,
        Direccion NVARCHAR(250) NULL,

        FechaCreacion DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),

        -- NUEVO: borrado lógico
        EstaActivo BIT NOT NULL CONSTRAINT DF_TblClientes_EstaActivo DEFAULT(1),

        -- opcional útil
        FechaActualizacion DATETIME2 NULL
    );

    CREATE INDEX IX_TblClientes_UsuarioId ON dbo.TblClientes(UsuarioId);
    CREATE INDEX IX_TblClientes_UsuarioId_EstaActivo ON dbo.TblClientes(UsuarioId, EstaActivo);
END
ELSE
BEGIN
    IF COL_LENGTH('dbo.TblClientes', 'EstaActivo') IS NULL
        ALTER TABLE dbo.TblClientes
        ADD EstaActivo BIT NOT NULL CONSTRAINT DF_TblClientes_EstaActivo DEFAULT(1);

    IF COL_LENGTH('dbo.TblClientes', 'FechaActualizacion') IS NULL
        ALTER TABLE dbo.TblClientes
        ADD FechaActualizacion DATETIME2 NULL;

    IF COL_LENGTH('dbo.TblClientes', 'Email') IS NULL
        ALTER TABLE dbo.TblClientes
        ADD Email NVARCHAR(120) NULL;

    -- Por si alguien dejó "Correo" en una versión vieja:
    IF COL_LENGTH('dbo.TblClientes', 'Correo') IS NOT NULL AND COL_LENGTH('dbo.TblClientes', 'Email') IS NOT NULL
    BEGIN
        -- opcional: migra datos de Correo -> Email si Email está vacío
        UPDATE dbo.TblClientes
        SET Email = Email
        WHERE Email IS NULL 

        -- NO borro Correo automáticamente por seguridad
    END
END
GO
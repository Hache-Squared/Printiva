/* =========================
   PRODUCCION: CAMPOS EXTRA
========================= */

IF COL_LENGTH('dbo.TblProduccionItems','ImpresoraId') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD ImpresoraId INT NULL;

IF COL_LENGTH('dbo.TblProduccionItems','NotasOperativas') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD NotasOperativas NVARCHAR(500) NULL;

IF COL_LENGTH('dbo.TblProduccionItems','PesoEstimadoGr') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD PesoEstimadoGr DECIMAL(10,2) NULL;

IF COL_LENGTH('dbo.TblProduccionItems','PesoRealGr') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD PesoRealGr DECIMAL(10,2) NULL;

IF COL_LENGTH('dbo.TblProduccionItems','FechaInicio') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD FechaInicio DATETIME2(0) NULL;

IF COL_LENGTH('dbo.TblProduccionItems','FechaFin') IS NULL
    ALTER TABLE dbo.TblProduccionItems ADD FechaFin DATETIME2(0) NULL;

IF COL_LENGTH('dbo.TblProduccionItems','InventarioAplicado') IS NULL
    ALTER TABLE dbo.TblProduccionItems
        ADD InventarioAplicado BIT NOT NULL
            CONSTRAINT DF_TblProduccionItems_InventarioAplicado DEFAULT(0);

-- FK (si no existe)
IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_TblProduccionItems_Impresoras'
)
BEGIN
    ALTER TABLE dbo.TblProduccionItems
      ADD CONSTRAINT FK_TblProduccionItems_Impresoras
      FOREIGN KEY (ImpresoraId) REFERENCES dbo.TblImpresoras(ImpresoraId);
END
GO

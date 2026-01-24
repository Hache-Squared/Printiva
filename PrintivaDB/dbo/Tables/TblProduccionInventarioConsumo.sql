

/* =========================================================
   1) Log de consumo por ProduccionItem (con unidad snapshot)
========================================================= */
IF OBJECT_ID('dbo.TblProduccionInventarioConsumo', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TblProduccionInventarioConsumo
    (
        ProduccionInventarioConsumoId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ProduccionItemId INT NOT NULL,
        RecetaId INT NOT NULL,
        InventarioId INT NOT NULL,
        Cantidad DECIMAL(10,2) NOT NULL,
        InventarioUnidadId INT NULL,
        UsuarioId INT NOT NULL,
        Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_TblProduccionInventarioConsumo_Fecha DEFAULT SYSDATETIME()
    );

    CREATE UNIQUE INDEX UX_TblProduccionInventarioConsumo_ItemInv
        ON dbo.TblProduccionInventarioConsumo (ProduccionItemId, InventarioId);
END
GO
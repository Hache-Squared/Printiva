CREATE TABLE dbo.TblProduccionCosteos
(
    ProduccionCosteoId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblProduccionCosteos PRIMARY KEY,
    ProduccionItemId INT NOT NULL,
    UsuarioId INT NOT NULL,
    TipoCodigo VARCHAR(30) NOT NULL, -- 'MATERIAL'
    Moneda VARCHAR(3) NOT NULL,
    Total DECIMAL(18,4) NOT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_TblProduccionCosteos_Fecha DEFAULT SYSDATETIME(),
    EstaActivo BIT NOT NULL CONSTRAINT DF_TblProduccionCosteos_EstaActivo DEFAULT 1
);

CREATE UNIQUE INDEX UX_TblProduccionCosteos_Item_Tipo_Usuario
ON dbo.TblProduccionCosteos(ProduccionItemId, UsuarioId, TipoCodigo)
WHERE EstaActivo = 1;

CREATE TABLE dbo.TblProduccionCosteosDetalle
(
    ProduccionCosteoDetalleId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblProduccionCosteosDetalle PRIMARY KEY,
    ProduccionCosteoId INT NOT NULL,
    ConceptoCodigo VARCHAR(50) NOT NULL,
    InventarioId INT NULL,
    ImpresoraId INT NULL,

    TarifaId INT NOT NULL,
    TarifaNombre NVARCHAR(200) NOT NULL,
    TarifaOrden INT NOT NULL,

    MontoTarifa DECIMAL(18,4) NOT NULL,
    Cantidad DECIMAL(18,4) NOT NULL,
    Subtotal DECIMAL(18,4) NOT NULL,
    Moneda VARCHAR(3) NOT NULL,

    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_TblProduccionCosteosDetalle_Fecha DEFAULT SYSDATETIME()
);

ALTER TABLE dbo.TblProduccionCosteosDetalle
ADD CONSTRAINT FK_TblProduccionCosteosDetalle_Costeo
FOREIGN KEY (ProduccionCosteoId) REFERENCES dbo.TblProduccionCosteos(ProduccionCosteoId);
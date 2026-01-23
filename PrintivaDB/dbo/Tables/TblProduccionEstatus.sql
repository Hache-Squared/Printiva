 CREATE TABLE dbo.TblProduccionEstatus
(
    ProduccionEstatusId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Orden INT NOT NULL,
    BadgeClass VARCHAR(60) NOT NULL CONSTRAINT DF_TblProduccionEstatus_Badge DEFAULT('bg-secondary'),
    EstaActivo BIT NOT NULL CONSTRAINT DF_TblProduccionEstatus_EstaActivo DEFAULT(1)
);

CREATE UNIQUE INDEX UX_TblProduccionEstatus_Nombre
ON dbo.TblProduccionEstatus(Nombre)
WHERE EstaActivo = 1;
/* =========================================================
   BORRADO LÓGICO: Agregar EstaActivo bit a tablas de inventario
========================================================= */

-- 1) TblInventariosNombres
IF COL_LENGTH('dbo.TblInventariosNombres', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventariosNombres
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblInventariosNombres_EstaActivo DEFAULT (1);

END
GO

-- 2) TblInventariosColores
IF COL_LENGTH('dbo.TblInventariosColores', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventariosColores
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblInventariosColores_EstaActivo DEFAULT (1);

END
GO

-- 3) TblInventariosTipos
IF COL_LENGTH('dbo.TblInventariosTipos', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventariosTipos
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblInventariosTipos_EstaActivo DEFAULT (1);

END
GO

-- 4) TblInventariosMarcas
IF COL_LENGTH('dbo.TblInventariosMarcas', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventariosMarcas
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblInventariosMarcas_EstaActivo DEFAULT (1);

END
GO

-- 5) TblInventarios
IF COL_LENGTH('dbo.TblInventarios', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventarios
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblInventarios_EstaActivo DEFAULT (1);

END
GO

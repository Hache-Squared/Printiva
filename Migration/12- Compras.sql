/* ==========================================================
   COMPRAS 2.0 - MIGRACION
   - Borrado lógico
   - Integración a InventariosMovimientos
   - Tipos con flags EsInventario / RequiereFilamentoTipo
   ========================================================== */

BEGIN TRY
    BEGIN TRAN;

    /* -----------------------------
       1) TblCompras: columnas nuevas
       ----------------------------- */
    IF COL_LENGTH('dbo.TblCompras', 'EstaActivo') IS NULL
    BEGIN
        ALTER TABLE dbo.TblCompras
        ADD EstaActivo BIT NOT NULL
            CONSTRAINT DF_TblCompras_EstaActivo DEFAULT(1);
    END

    IF COL_LENGTH('dbo.TblCompras', 'InventarioId') IS NULL
    BEGIN
        ALTER TABLE dbo.TblCompras
        ADD InventarioId INT NULL;
    END

    IF COL_LENGTH('dbo.TblCompras', 'Cantidad') IS NULL
    BEGIN
        ALTER TABLE dbo.TblCompras
        ADD Cantidad DECIMAL(10,2) NOT NULL
            CONSTRAINT DF_TblCompras_Cantidad DEFAULT(0);
    END

    IF COL_LENGTH('dbo.TblCompras', 'CostoUnitario') IS NULL
    BEGIN
        ALTER TABLE dbo.TblCompras
        ADD CostoUnitario DECIMAL(18,2) NOT NULL
            CONSTRAINT DF_TblCompras_CostoUnitario DEFAULT(0);
    END

    /* (Opcional) UsuarioId para auditoría/ownership.
       Si tu app es single-user puedes dejarlo NULL.
       Si lo quieres forzar, primero llena valores y luego cambia a NOT NULL. */
    IF COL_LENGTH('dbo.TblCompras', 'UsuarioId') IS NULL
    BEGIN
        ALTER TABLE dbo.TblCompras
        ADD UsuarioId INT NULL;
    END

    /* FK TblCompras -> TblInventarios */
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = 'FK_TblCompras_TblInventarios' AND parent_object_id = OBJECT_ID('dbo.TblCompras')
    )
    BEGIN
        ALTER TABLE dbo.TblCompras WITH CHECK
        ADD CONSTRAINT FK_TblCompras_TblInventarios
            FOREIGN KEY (InventarioId) REFERENCES dbo.TblInventarios(InventarioId);
    END

    /* FK TblCompras -> Usuarios */
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = 'FK_TblCompras_Usuarios' AND parent_object_id = OBJECT_ID('dbo.TblCompras')
    )
    BEGIN
        ALTER TABLE dbo.TblCompras WITH CHECK
        ADD CONSTRAINT FK_TblCompras_Usuarios
            FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios(Id);
    END

    /* -----------------------------
       2) TblComprasTipos: flags + borrado lógico
       ----------------------------- */
    IF COL_LENGTH('dbo.TblComprasTipos', 'EstaActivo') IS NULL
    BEGIN
        ALTER TABLE dbo.TblComprasTipos
        ADD EstaActivo BIT NOT NULL
            CONSTRAINT DF_TblComprasTipos_EstaActivo DEFAULT(1);
    END

    IF COL_LENGTH('dbo.TblComprasTipos', 'EsInventario') IS NULL
    BEGIN
        ALTER TABLE dbo.TblComprasTipos
        ADD EsInventario BIT NOT NULL
            CONSTRAINT DF_TblComprasTipos_EsInventario DEFAULT(0);
    END

    IF COL_LENGTH('dbo.TblComprasTipos', 'RequiereFilamentoTipo') IS NULL
    BEGIN
        ALTER TABLE dbo.TblComprasTipos
        ADD RequiereFilamentoTipo BIT NOT NULL
            CONSTRAINT DF_TblComprasTipos_RequiereFilamento DEFAULT(0);
    END

    /* -----------------------------
       3) TblComprasCategorias: borrado lógico
       ----------------------------- */
    IF COL_LENGTH('dbo.TblComprasCategorias', 'EstaActivo') IS NULL
    BEGIN
        ALTER TABLE dbo.TblComprasCategorias
        ADD EstaActivo BIT NOT NULL
            CONSTRAINT DF_TblComprasCategorias_EstaActivo DEFAULT(1);
    END

    

    /* -----------------------------
       4) TblInventariosMovimientos: Cantidad como decimal (compat con filamento gramos)
       ----------------------------- */
    IF EXISTS (
        SELECT 1
        FROM sys.columns c
        JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('dbo.TblInventariosMovimientos')
          AND c.name = 'Cantidad'
          AND t.name IN ('int')
    )
    BEGIN
        ALTER TABLE dbo.TblInventariosMovimientos
        ALTER COLUMN Cantidad DECIMAL(10,2) NOT NULL;
    END

    /* -----------------------------
       5) Asegurar tipos de movimiento base (si tu catálogo ya existe, no duplica)
       ----------------------------- */
    IF NOT EXISTS (SELECT 1 FROM dbo.TblInventariosMovimientoTipos WHERE Nombre = 'COMPRA')
        INSERT INTO dbo.TblInventariosMovimientoTipos(Nombre) VALUES ('COMPRA');

    IF NOT EXISTS (SELECT 1 FROM dbo.TblInventariosMovimientoTipos WHERE Nombre = 'AJUSTE_COMPRA')
        INSERT INTO dbo.TblInventariosMovimientoTipos(Nombre) VALUES ('AJUSTE_COMPRA');

    IF NOT EXISTS (SELECT 1 FROM dbo.TblInventariosMovimientoTipos WHERE Nombre = 'REVERSA_COMPRA')
        INSERT INTO dbo.TblInventariosMovimientoTipos(Nombre) VALUES ('REVERSA_COMPRA');

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF (XACT_STATE() <> 0) ROLLBACK TRAN;
    THROW;
END CATCH;
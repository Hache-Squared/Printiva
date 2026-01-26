IF COL_LENGTH('dbo.TblInventarios', 'CostoUnitario') IS NULL
BEGIN
    ALTER TABLE dbo.TblInventarios
    ADD CostoUnitario DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_TblInventarios_CostoUnitario DEFAULT(0);
END
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_TblProdInvConsumo_Fecha' AND object_id=OBJECT_ID('dbo.TblProduccionInventarioConsumo'))
BEGIN
    CREATE INDEX IX_TblProdInvConsumo_Fecha
    ON dbo.TblProduccionInventarioConsumo (Fecha)
    INCLUDE (PedidoId, InventarioId, Cantidad, UsuarioId, ProductoId, RecetaId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_TblProdInvConsumo_Pedido' AND object_id=OBJECT_ID('dbo.TblProduccionInventarioConsumo'))
BEGIN
    CREATE INDEX IX_TblProdInvConsumo_Pedido
    ON dbo.TblProduccionInventarioConsumo (PedidoId, Fecha)
    INCLUDE (InventarioId, Cantidad, UsuarioId, ProductoId, RecetaId);
END
GO


-- 2) TblPedidos
IF COL_LENGTH('dbo.TblPedidos', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblPedidos
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblPedidos_EstaActivo DEFAULT (1);
END
GO

-- 2) TblPedidoItems
IF COL_LENGTH('dbo.TblPedidoItems', 'EstaActivo') IS NULL
BEGIN
    ALTER TABLE dbo.TblPedidoItems
    ADD EstaActivo BIT NOT NULL
        CONSTRAINT DF_TblPedidoItems_EstaActivo DEFAULT (1);
END
GO
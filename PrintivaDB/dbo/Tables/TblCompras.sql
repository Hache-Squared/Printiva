CREATE TABLE [dbo].[TblCompras]
(
	[CompraId] INT NOT NULL PRIMARY KEY IDENTITY(1,1), 
    [Descripcion] VARCHAR(MAX) NULL, 
    [CompraTipoId] INT NOT NULL, 
    [FilamentoTipoId] INT NULL, 
    [CostoTotal] DECIMAL(10, 2) NOT NULL DEFAULT 0, 
    [CompraCategoriaId] INT NOT NULL, 
    [FechaCreacion] DATETIME NOT NULL DEFAULT GETUTCDATE(), 
    CONSTRAINT FK_TblCompras_TblComprasTipos FOREIGN KEY (CompraTipoId) REFERENCES TblComprasTipos(CompraTipoId), 
    CONSTRAINT [FK_TblCompras_TblFilamentosTipos] FOREIGN KEY ([FilamentoTipoId]) REFERENCES [TblFilamentosTipos]([FilamentoTipoId]), 
    CONSTRAINT [FK_TblCompras_TblComprasCategorias] FOREIGN KEY ([CompraCategoriaId]) REFERENCES [TblComprasCategorias]([CompraCategoriaId]) 
)

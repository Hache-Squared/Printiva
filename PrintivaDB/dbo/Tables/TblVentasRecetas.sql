CREATE TABLE [dbo].[TblVentasRecetas]
(
	[VentaRecetaId] INT NOT NULL PRIMARY KEY IDENTITY(1,1), 
    [VentaId] INT NOT NULL, 
    [RecetaId] INT NOT NULL, 
    [Cantidad] DECIMAL(10, 2) NOT NULL, 
    [CostoUnitario] DECIMAL(10, 2) NOT NULL, 
    CONSTRAINT [FK_TblVentasRecetas_TblRecetas] FOREIGN KEY ([RecetaId]) REFERENCES [TblRecetas]([RecetaId]), 
    CONSTRAINT [FK_TblVentasRecetas_TblVentas] FOREIGN KEY ([VentaId]) REFERENCES [TblVentas]([VentaId])
)

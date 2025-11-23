CREATE TABLE [dbo].[TblComprasRecurrentes]
(
	[CompraRecurrenteId] INT NOT NULL PRIMARY KEY IDENTITY(1, 1), 
    [CompraId] INT NOT NULL, 
    CONSTRAINT [FK_TblComprasRecurrentes_TblCompras] FOREIGN KEY ([CompraId]) REFERENCES [TblCompras]([CompraId])
)

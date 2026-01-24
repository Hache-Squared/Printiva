/* =========================================================
   0) Asegura TipoMovimiento "Consumo"
========================================================= */
IF NOT EXISTS (
    SELECT 1
    FROM dbo.TblInventariosMovimientoTipos WITH (NOLOCK)
    WHERE UPPER(LTRIM(RTRIM(Nombre))) = 'CONSUMO'
)
BEGIN
    INSERT dbo.TblInventariosMovimientoTipos (Nombre)
    VALUES (N'Consumo');
END
GO


ALTER TABLE dbo.TblProduccionItems
ADD RecetaId INT NULL;
GO

-- opcional pero recomendado
ALTER TABLE dbo.TblProduccionItems
ADD CONSTRAINT FK_TblProduccionItems_TblRecetas
FOREIGN KEY (RecetaId) REFERENCES dbo.TblRecetas(RecetaId);
GO

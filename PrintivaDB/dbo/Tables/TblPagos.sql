CREATE TABLE dbo.TblPagos(
    PagoId INT PRIMARY KEY IDENTITY(1,1),
    CotizacionId INT NOT NULL,
    PagoTipoId INT NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    FechaPago DATETIME NOT NULL,
    Metodo VARCHAR(100) NULL,
    Referencia VARCHAR(200) NULL,
    Notas VARCHAR(500) NULL,
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_TblPagos_FechaCreacion DEFAULT(GETDATE()),
    EstaActivo BIT NOT NULL CONSTRAINT DF_TblPagos_EstaActivo DEFAULT(1),

    CONSTRAINT FK_TblPagos_Cotizaciones FOREIGN KEY(CotizacionId)
        REFERENCES dbo.TblCotizaciones(CotizacionId),

    CONSTRAINT FK_TblPagos_PagoTipos FOREIGN KEY(PagoTipoId)
        REFERENCES dbo.TblPagoTipos(PagoTipoId)
);
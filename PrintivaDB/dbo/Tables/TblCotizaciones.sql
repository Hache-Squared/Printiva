CREATE TABLE dbo.TblCotizaciones(
    CotizacionId INT PRIMARY KEY IDENTITY(1,1),
    PedidoId INT NOT NULL,
    CotizacionEstatusId INT NOT NULL,
    FechaCreacion DATETIME NOT NULL,
    FechaVigencia DATETIME NULL,
    Notas VARCHAR(MAX) NULL,
    EstaActivo BIT NOT NULL CONSTRAINT DF_TblCotizaciones_EstaActivo DEFAULT(1),

    CONSTRAINT FK_TblCotizaciones_Estatus FOREIGN KEY(CotizacionEstatusId)
        REFERENCES dbo.TblCotizacionesEstatus(CotizacionEstatusId)
);
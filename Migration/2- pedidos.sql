CREATE TABLE dbo.TblClientes
(
    ClienteId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UsuarioId INT NOT NULL,
    Nombre NVARCHAR(150) NOT NULL,
    Telefono NVARCHAR(30) NULL,
    Instagram NVARCHAR(80) NULL,
    WhatsApp NVARCHAR(30) NULL,
    Email NVARCHAR(120) NULL,
    Direccion NVARCHAR(250) NULL,
    FechaCreacion DATETIME2 NOT NULL DEFAULT (SYSDATETIME())
);

CREATE TABLE dbo.TblPedidoEstatus
(
    PedidoEstatusId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre NVARCHAR(60) NOT NULL
);

CREATE TABLE dbo.TblPedidos
(
    PedidoId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UsuarioId INT NOT NULL,
    ClienteId INT NOT NULL,
    PedidoEstatusId INT NOT NULL,
    FechaCreacion DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    FechaEntregaEstimada DATETIME2 NULL,
    Notas NVARCHAR(500) NULL,
    TotalEstimado DECIMAL(18,2) NULL,
    CONSTRAINT FK_TblPedidos_Clientes FOREIGN KEY (ClienteId) REFERENCES dbo.TblClientes(ClienteId),
    CONSTRAINT FK_TblPedidos_Estatus FOREIGN KEY (PedidoEstatusId) REFERENCES dbo.TblPedidoEstatus(PedidoEstatusId)
);

CREATE TABLE dbo.TblPedidoItems
(
    PedidoItemId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PedidoId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitarioEstimado DECIMAL(18,2) NULL,
    Notas NVARCHAR(250) NULL,
    CONSTRAINT FK_TblPedidoItems_Pedidos FOREIGN KEY (PedidoId) REFERENCES dbo.TblPedidos(PedidoId)
);

INSERT INTO dbo.TblPedidoEstatus (Nombre)
VALUES
(N'Nuevo'),
(N'En modelado'),
(N'Modelado listo'),
(N'Aprobado'),
(N'En producción'),
(N'Post-proceso'),
(N'Listo para entrega'),
(N'Entregado'),
(N'Cancelado');



--------------------------------------
---PROCEDURES----
CREATE OR ALTER PROCEDURE dbo.procObtenerClientes
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ClienteId,
        UsuarioId,
        Nombre,
        Telefono,
        Instagram,
        WhatsApp,
        Email,
        Direccion,
        FechaCreacion
    FROM dbo.TblClientes
    WHERE UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR ClienteId = @elementoObtenerId)
    ORDER BY Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.procObtenerPedidoEstatus
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PedidoEstatusId, Nombre
    FROM dbo.TblPedidoEstatus
    ORDER BY PedidoEstatusId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procObtenerPedidos
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PedidoId,
        p.UsuarioId,
        p.ClienteId,
        c.Nombre AS ClienteNombre,
        p.PedidoEstatusId,
        e.Nombre AS EstatusNombre,
        p.FechaCreacion,
        p.FechaEntregaEstimada,
        p.Notas,
        p.TotalEstimado
    FROM dbo.TblPedidos p
    INNER JOIN dbo.TblClientes c ON c.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus e ON e.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR p.PedidoId = @elementoObtenerId)
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.procObtenerPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        SELECT TOP 0
            i.PedidoItemId,
            i.PedidoId,
            i.ProductoId,
            CAST(NULL AS NVARCHAR(200)) AS ProductoNombre,
            i.Cantidad,
            i.PrecioUnitarioEstimado,
            i.Notas;
        RETURN;
    END

    SELECT
        i.PedidoItemId,
        i.PedidoId,
        i.ProductoId,
        p.Nombre AS ProductoNombre,
        i.Cantidad,
        i.PrecioUnitarioEstimado,
        i.Notas
    FROM dbo.TblPedidoItems i
    INNER JOIN dbo.TblProductos p ON p.ProductoId = i.ProductoId
    WHERE i.PedidoId = @pedidoId
    ORDER BY i.PedidoItemId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procCrearPedido
    @loginId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TblPedidos (UsuarioId, ClienteId, PedidoEstatusId, FechaEntregaEstimada, Notas, TotalEstimado)
    VALUES (@loginId, @clienteId, @pedidoEstatusId, @fechaEntregaEstimada, @notas, @totalEstimado);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS PedidoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procActualizarPedido
    @loginId INT,
    @pedidoId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TblPedidos
    SET ClienteId = @clienteId,
        PedidoEstatusId = @pedidoEstatusId,
        FechaEntregaEstimada = @fechaEntregaEstimada,
        Notas = @notas,
        TotalEstimado = @totalEstimado
    WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
END
GO

CREATE OR ALTER PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
        DELETE FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.procReemplazarPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
        RETURN;

    DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
END
GO

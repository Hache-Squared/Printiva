CREATE   PROCEDURE dbo.procObtenerComprasV2
        @ElementoObtenerId INT = 0,
        @loginId INT = 0,
        @SoloActivos BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @message VARCHAR(MAX) = '';
        DECLARE @elementoId INT = ISNULL(@ElementoObtenerId,0);

        BEGIN TRY
            IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            BEGIN
                SET @message = 'Usuario no encontrado.';
                RAISERROR(@message, 16, 1);
            END

            CREATE TABLE #TempData(
                CompraId INT,
                Descripcion VARCHAR(MAX),
                CompraTipoId INT,
                CompraTipo VARCHAR(200),
                EsInventario BIT,
                RequiereFilamentoTipo BIT,

                FilamentoTipoId INT NULL,
                FilamentoTipo VARCHAR(200) NULL,

                CompraCategoriaId INT,
                CompraCategoria VARCHAR(200),

                InventarioId INT NULL,
                InventarioNombre VARCHAR(200) NULL,
                InventarioNombreAbreviatura VARCHAR(200) NULL,
                InventarioColor VARCHAR(200) NULL,
                InventarioColorAbreviatura VARCHAR(200) NULL,
                InventarioUnidad VARCHAR(200) NULL,

                Cantidad DECIMAL(10,2),
                CostoUnitario DECIMAL(18,2),
                CostoTotal DECIMAL(18,2),

                FechaCreacion DATETIME,
                EstaActivo BIT,
                UsuarioId INT NULL
            );

            INSERT INTO #TempData(
                CompraId, Descripcion,
                CompraTipoId, CompraTipo, EsInventario, RequiereFilamentoTipo,
                FilamentoTipoId, FilamentoTipo,
                CompraCategoriaId, CompraCategoria,
                InventarioId, InventarioNombre, InventarioNombreAbreviatura, InventarioColor, InventarioColorAbreviatura, InventarioUnidad,
                Cantidad, CostoUnitario, CostoTotal,
                FechaCreacion, EstaActivo, UsuarioId
            )
            SELECT
                c.CompraId,
                c.Descripcion,
                c.CompraTipoId,
                ct.Nombre,
                ct.EsInventario,
                ct.RequiereFilamentoTipo,

                c.FilamentoTipoId,
                ft.Nombre,

                c.CompraCategoriaId,
                cc.Nombre,

                c.InventarioId,
                invNom.Nombre,
                invNom.Abreviatura,
                invCol.Nombre,
                invCol.Abreviatura,
                invUni.Nombre,

                c.Cantidad,
                c.CostoUnitario,
                c.CostoTotal,

                c.FechaCreacion,
                c.EstaActivo,
                c.UsuarioId
            FROM dbo.TblCompras c (NOLOCK)
            INNER JOIN dbo.TblComprasTipos ct (NOLOCK) ON c.CompraTipoId = ct.CompraTipoId
            INNER JOIN dbo.TblComprasCategorias cc (NOLOCK) ON c.CompraCategoriaId = cc.CompraCategoriaId
            LEFT JOIN dbo.TblFilamentosTipos ft (NOLOCK) ON c.FilamentoTipoId = ft.FilamentoTipoId
            LEFT JOIN dbo.TblInventarios inv (NOLOCK) ON c.InventarioId = inv.InventarioId
            LEFT JOIN dbo.TblInventariosNombres invNom (NOLOCK) ON inv.InventarioNombreId = invNom.InventarioNombreId
            LEFT JOIN dbo.TblInventariosColores invCol (NOLOCK) ON inv.InventarioColorId = invCol.InventarioColorId
            LEFT JOIN dbo.TblInventariosUnidades invUni (NOLOCK) ON inv.InventarioUnidadId = invUni.InventarioUnidadId
            WHERE (@SoloActivos = 0 OR c.EstaActivo = 1);

            IF (@elementoId = 0)
                SELECT * FROM #TempData ORDER BY FechaCreacion DESC;
            ELSE
                SELECT * FROM #TempData WHERE CompraId = @elementoId;

            DROP TABLE IF EXISTS #TempData;
        END TRY
        BEGIN CATCH
            IF (ISNULL(@message,'') = '')
                SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
            SELECT 'fail' [result], @message [message], @elementoId [elementoId];
        END CATCH
    END
GO


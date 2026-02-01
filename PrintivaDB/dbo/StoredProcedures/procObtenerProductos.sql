CREATE   PROCEDURE dbo.procObtenerProductos
@ElementoObtenerId INT = 0,
@loginId INT = 0,
@SoloActivos BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoObtenerId,0);

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        CREATE TABLE #TempData(
            ProductoId INT,
            Nombre VARCHAR(200),
            ProductoCategoriaId INT,
            ProductoCategoria VARCHAR(200),
            SKU VARCHAR(200),
            PrecioSugerido DECIMAL(18,2),
            EstaActivo BIT
        );

        INSERT INTO #TempData(
            ProductoId,
            Nombre,
            ProductoCategoriaId,
            ProductoCategoria,
            SKU,
            PrecioSugerido,
            EstaActivo
        )
        SELECT
            p.ProductoId,
            p.Nombre,
            p.ProductoCategoriaId,
            pc.Nombre,
            p.SKU,
            p.PrecioSugerido,
            p.EstaActivo
        FROM dbo.TblProductos p (NOLOCK)
        INNER JOIN dbo.TblProductosCategorias pc (NOLOCK)
            ON p.ProductoCategoriaId = pc.ProductoCategoriaId
        WHERE (@SoloActivos = 0 OR p.EstaActivo = 1);

        IF(ISNULL(@elementoId,0) = 0)
        BEGIN
            SELECT
                ProductoId,
                Nombre,
                ProductoCategoriaId,
                ProductoCategoria,
                SKU,
                PrecioSugerido,
                EstaActivo
            FROM #TempData
            ORDER BY Nombre;
        END
        ELSE
        BEGIN
            SELECT
                ProductoId,
                Nombre,
                ProductoCategoriaId,
                ProductoCategoria,
                SKU,
                PrecioSugerido,
                EstaActivo
            FROM #TempData t
            WHERE t.ProductoId = @elementoId;
        END
    END TRY
    BEGIN CATCH
        SELECT
            'fail' [result],
            CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.') [message],
            @elementoId [elementoId];
    END CATCH

    DROP TABLE IF EXISTS #TempData;
END
GO


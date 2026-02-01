/*
===============================================================================
Author: AGHH (adaptado para Compras)
Date: 16/11/2025
Description: Obtención de compras con JOINs a tipos y categorías
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procObtenerCompras
    @ElementoObtenerId INT = 0,
    @loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoObtenerId, 0);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        -- Temp table con campos que coincidan con la entidad Compra
        CREATE TABLE #TempData (
            CompraId INT,
            Descripcion VARCHAR(500),  -- Ajusta el tamaño según tu esquema
            CompraTipoId INT,
            FilamentoTipoId INT,
            CompraCategoriaId INT,
            CostoTotal DECIMAL(18,2),
            FechaCreacion DATETIME,
            CompraTipo VARCHAR(200),
            FilamentoTipo VARCHAR(200),
            CompraCategoria VARCHAR(200)
        );

        INSERT INTO #TempData (
            CompraId,
            Descripcion,
            CompraTipoId,
            FilamentoTipoId,
            CompraCategoriaId,
            CostoTotal,
            FechaCreacion,
            CompraTipo,
            FilamentoTipo,
            CompraCategoria
        )
        SELECT
            c.CompraId,
            c.Descripcion,
            c.CompraTipoId,
            c.FilamentoTipoId,
            c.CompraCategoriaId,
            c.CostoTotal,
            c.FechaCreacion,
            ct.Nombre AS CompraTipo,  -- Asume que TblComprasTipos tiene campo 'Nombre'
            ft.Nombre AS FilamentoTipo,  -- Asume que TblFilamentoTipos tiene 'Nombre'
            cc.Nombre AS CompraCategoria  -- Asume que TblComprasCategorias tiene 'Nombre'
        FROM dbo.TblCompras c (NOLOCK)
        INNER JOIN dbo.TblComprasTipos ct (NOLOCK) ON c.CompraTipoId = ct.CompraTipoId
        LEFT JOIN dbo.TblFilamentosTipos ft (NOLOCK) ON c.FilamentoTipoId = ft.FilamentoTipoId
        INNER JOIN dbo.TblComprasCategorias cc (NOLOCK) ON c.CompraCategoriaId = cc.CompraCategoriaId;

        IF (ISNULL(@elementoId, 0) = 0)
        BEGIN
            -- Retorna todos
            SELECT
                CompraId,
                Descripcion,
                CompraTipoId,
                FilamentoTipoId,
                CompraCategoriaId,
                CostoTotal,
                FechaCreacion,
                CompraTipo,
                FilamentoTipo,
                CompraCategoria
            FROM #TempData;
        END
        ELSE
        BEGIN
            -- Retorna por ID
            SELECT
                CompraId,
                Descripcion,
                CompraTipoId,
                FilamentoTipoId,
                CompraCategoriaId,
                CostoTotal,
                FechaCreacion,
                CompraTipo,
                FilamentoTipo,
                CompraCategoria
            FROM #TempData t
            WHERE t.CompraId = @elementoId;
        END
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, '') = '')
        BEGIN
            SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        END
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END CATCH

    DROP TABLE IF EXISTS #TempData;
END
/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Description: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Description     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE PROCEDURE dbo.procObtenerRecetaInventario
@ElementoObtenerId INT = 0,
@loginId INT = 0
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(100) = '';
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
            RecetaId INT,
            InventarioId INT,
            InventarioMarcaId INT,
            InventarioTipoId INT,
            InventarioNombreId INT,
            InventarioColorId INT,
            InventarioUnidadId INT,
            CantidadAsignada DECIMAL(10,2),
            InventarioMarca VARCHAR(200),
            InventarioTipo VARCHAR(200),
            InventarioNombre VARCHAR(200),
            InventarioNombreAbreviatura VARCHAR(200),
            InventarioColor VARCHAR(200),
            InventarioColorAbreviatura VARCHAR(200),
            InventarioUnidad VARCHAR(200)
        );

        INSERT INTO #TempData(
            RecetaId,
            InventarioId,
            InventarioMarcaId,
            InventarioTipoId,
            InventarioNombreId,
            InventarioColorId,
            InventarioUnidadId,
            CantidadAsignada,
            InventarioMarca,
            InventarioTipo,
            InventarioNombre,
            InventarioNombreAbreviatura,
            InventarioColor,
            InventarioColorAbreviatura,
            InventarioUnidad
        )
        SELECT 
            r.RecetaId,
            i.InventarioId,
            i.InventarioMarcaId,
            i.InventarioTipoId,
            i.InventarioNombreId,
            i.InventarioColorId,
            i.InventarioUnidadId,
            ri.Cantidad,
            im.Nombre,
            it.Nombre,
            ins.Nombre,
            ins.Abreviatura,
            ic.Nombre,
            ic.Abreviatura,
            iu.Nombre
        FROM dbo.TblRecetas r (NOLOCK)
        INNER JOIN dbo.TblRecetasInventarios ri (NOLOCK)
            ON ri.RecetaId = r.RecetaId
           AND ri.EstaActivo = 1  -- ✅ SOLO ACTIVOS
        INNER JOIN dbo.TblInventarios i (NOLOCK)
            ON ri.InventarioId = i.InventarioId
        INNER JOIN dbo.TblInventariosColores ic (NOLOCK)
            ON i.InventarioColorId = ic.InventarioColorId
        INNER JOIN dbo.TblInventariosMarcas im (NOLOCK)
            ON i.InventarioMarcaId = im.InventarioMarcaId
        INNER JOIN dbo.TblInventariosNombres ins (NOLOCK)
            ON i.InventarioNombreId = ins.InventarioNombreId
        INNER JOIN dbo.TblInventariosTipos it (NOLOCK)
            ON i.InventarioTipoId = it.InventarioTipoId
        INNER JOIN dbo.TblInventariosUnidades iu (NOLOCK)
            ON i.InventarioUnidadId = iu.InventarioUnidadId;

        IF (ISNULL(@elementoId,0) = 0)
        BEGIN 
            SELECT 
                RecetaId,
                InventarioId,
                InventarioMarcaId,
                InventarioTipoId,
                InventarioNombreId,
                InventarioColorId,
                InventarioUnidadId,
                CantidadAsignada,
                InventarioMarca,
                InventarioTipo,
                InventarioNombre,
                InventarioNombreAbreviatura,
                InventarioColor,
                InventarioColorAbreviatura,
                InventarioUnidad
            FROM #TempData;
        END
        ELSE 
        BEGIN 
            SELECT 
                RecetaId,
                InventarioId,
                InventarioMarcaId,
                InventarioTipoId,
                InventarioNombreId,
                InventarioColorId,
                InventarioUnidadId,
                CantidadAsignada,
                InventarioMarca,
                InventarioTipo,
                InventarioNombre,
                InventarioNombreAbreviatura,
                InventarioColor,
                InventarioColorAbreviatura,
                InventarioUnidad
            FROM #TempData t
            WHERE t.RecetaId = @elementoId;
        END

    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF(ISNULL(@message,'') = '')
        BEGIN 
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        END
        
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END CATCH

    DROP TABLE IF EXISTS #TempData;
END
GO
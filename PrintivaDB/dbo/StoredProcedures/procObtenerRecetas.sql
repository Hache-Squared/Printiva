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
CREATE PROCEDURE dbo.procObtenerRecetas
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
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
			Nombre VARCHAR(200),
			ProductoId INT,
			TiempoImpresion VARCHAR(200),
			ProductoNombre VARCHAR(200),
			ProductoCategoriaId INT,
			ProductoCategoria VARCHAR(200),
			ProductoSKU VARCHAR(200),
			TiempoImpresionMin INT,
			TiempoPostMin INT
		)


		INSERT INTO #TempData(
			RecetaId,
			Nombre,
			ProductoId,
			TiempoImpresion,
			ProductoNombre,
			ProductoCategoriaId,
			ProductoCategoria,
			ProductoSKU,
			TiempoImpresionMin,
			TiempoPostMin
		)
		SELECT 
			r.RecetaId,
			r.Nombre,
			r.ProductoId,
			r.TiempoImpresion,
			p.Nombre,
			p.ProductoCategoriaId,
			pc.Nombre,
			p.SKU
			, COALESCE(r.TiempoImpresionMin, TRY_CONVERT(int, NULLIF(r.TiempoImpresion,'')), 0) AS TiempoImpresionMin
			, COALESCE(r.TiempoPostMin, 0) AS TiempoPostMin
		FROM dbo.TblRecetas r (NOLOCK)
		LEFT JOIN dbo.TblProductos p (NOLOCK)
			ON r.ProductoId = p.ProductoId
		LEFT JOIN dbo.TblProductosCategorias pc (NOLOCK)
			ON p.ProductoCategoriaId = pc.ProductoCategoriaId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				RecetaId,
				Nombre,
				ProductoId,
				TiempoImpresion,
				ProductoNombre,
				ProductoCategoriaId,
				ProductoCategoria,
				ProductoSKU,
				TiempoImpresionMin,
				TiempoPostMin
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				RecetaId,
				Nombre,
				ProductoId,
				TiempoImpresion,
				ProductoNombre,
				ProductoCategoriaId,
				ProductoCategoria,
				ProductoSKU,
				TiempoImpresionMin,
				TiempoPostMin
			FROM #TempData t
			WHERE t.RecetaId = @elementoId
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
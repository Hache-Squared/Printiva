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
CREATE PROCEDURE dbo.procObtenerProductos
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
			ProductoId INT,
			Nombre VARCHAR(200),
			ProductoCategoriaId INT,
			ProductoCategoria VARCHAR(200),
			SKU VARCHAR(200)
		)


		INSERT INTO #TempData(
			ProductoId,
			Nombre,
			ProductoCategoriaId,
			ProductoCategoria,
			SKU
		)
		SELECT 
			p.ProductoId,
			p.Nombre,
			p.ProductoCategoriaId,
			pc.Nombre,
			p.SKU
		FROM dbo.TblProductos p (NOLOCK)
		INNER JOIN dbo.TblProductosCategorias pc (NOLOCK)
			ON p.ProductoCategoriaId = pc.ProductoCategoriaId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				ProductoId,
				Nombre,
				ProductoCategoriaId,
				ProductoCategoria,
				SKU
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				ProductoId,
				Nombre,
				ProductoCategoriaId,
				ProductoCategoria,
				SKU
			FROM #TempData t
			WHERE t.ProductoId = @elementoId
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
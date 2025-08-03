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
CREATE PROCEDURE dbo.procAlteraProductos
@ElementoAlterarId INT = 0,
@Nombre					VARCHAR(200) = '',
@ProductoCategoriaId	VARCHAR(200) = '',
@SKU					VARCHAR(200) = '',
@loginId				INT = 0,
@Actualizar				BIT = 0,
@Borrar					BIT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoAlterarId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		IF(ISNULL(@Nombre, '') = '')
		BEGIN 
			SET @message = 'Nombre no puede ser vacio.';
			RAISERROR(@message, 16, 1);
		END

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.TblProductosCategorias im (NOLOCK)
			WHERE im.ProductoCategoriaId = @ProductoCategoriaId
		)
		BEGIN 
			SET @message = 'Categoria de producto no existe.';
			RAISERROR(@message, 16, 1);
		END

		IF EXISTS(
			SELECT 1 
			FROM dbo.TblProductos im (NOLOCK)
			WHERE im.ProductoId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblProductos im (NOLOCK)
					WHERE im.Nombre = @Nombre
					AND im.ProductoCategoriaId = @ProductoCategoriaId
				)
				BEGIN
					SET @message = 'Nombre ya existe con esa categoria actualmente.';
					RAISERROR(@message, 16, 1);
				END

				UPDATE tgt
					SET tgt.Nombre = @Nombre,
						tgt.ProductoCategoriaId = @ProductoCategoriaId
				FROM dbo.TblProductos tgt
				WHERE tgt.ProductoId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 
				DELETE tgt
				FROM dbo.TblProductos tgt
				WHERE tgt.ProductoId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblProductos im (NOLOCK)
				WHERE im.Nombre = @Nombre
				AND im.ProductoCategoriaId = @ProductoCategoriaId
			)
			BEGIN
				SET @message = 'Nombre ya existe con esa categoria actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblProductos(Nombre, ProductoCategoriaId, SKU)
			VALUES (@Nombre, @ProductoCategoriaId, @SKU);

			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SET @result = 'success';
		SET @message = IIF(@message = '','Ningun error', @message);


		SELECT @result [result],
			   @message [message],
			   @elementoId [elementoId];
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
END
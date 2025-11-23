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
CREATE PROCEDURE dbo.procActualizarRegistrosInventarios
@ElementoAlterarId	 INT = 0,
@InventarioMarcaId	 INT = 0,
@InventarioTipoId	 INT = 0,
@InventarioColorId	 INT = 0,
@Cantidad			 DECIMAL(10,2) = 0,
@InventarioUnidadId	 INT = 0,
@InventarioNombreId	 INT = 0,
@loginId			 INT = 0,
@Actualizar			 BIT = 0,
@Borrar				 BIT = 0
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

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.TblInventarios i (NOLOCK)
			WHERE i.InventarioId = @ElementoAlterarId
		)
		BEGIN
			SET @message = 'Inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		IF(
			ISNULL(@Actualizar, 0) = 1
		)
		BEGIN
			
			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosMarcas im (NOLOCK)
				WHERE im.InventarioMarcaId = @InventarioMarcaId
			)
			BEGIN 
				SET @message = 'Marca no encontrada.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosTipos im (NOLOCK)
				WHERE im.InventarioTipoId = @InventarioTipoId
			)
			BEGIN 
				SET @message = 'Tipo de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosColores ic (NOLOCK)
				WHERE ic.InventarioColorId = @InventarioColorId
			)
			BEGIN 
				SET @message = 'Color de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosUnidades ic (NOLOCK)
				WHERE ic.InventarioUnidadId = @InventarioUnidadId
			)
			BEGIN 
				SET @message = 'Unidad de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosNombres ic (NOLOCK)
				WHERE ic.InventarioNombreId = @InventarioNombreId
			)
			BEGIN 
				SET @message = 'Nombre de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF(ISNULL(@Cantidad, 0) = 0)
			BEGIN 
				SET @message = 'Cantidad debe tener un valor.';
				RAISERROR(@message, 16, 1);
			END
	
			IF(ISNUMERIC(@Cantidad) = 0)
			BEGIN 
				SET @message = 'Cantidad no es un numero.';
				RAISERROR(@message, 16, 1);
			END

			IF(@Cantidad < 0)
			BEGIN 
				SET @message = 'Cantidad debe ser positivo.';
				RAISERROR(@message, 16, 1);
			END

			UPDATE tgt
				SET tgt.InventarioMarcaId = @InventarioMarcaId,
					tgt.InventarioTipoId = @InventarioTipoId,
					tgt.InventarioUnidadId = @InventarioUnidadId,
					tgt.InventarioColorId = @InventarioColorId,
					tgt.InventarioNombreId = @InventarioNombreId,
					tgt.Cantidad = @Cantidad
			FROM dbo.TblInventarios tgt
			WHERE tgt.InventarioId = @ElementoAlterarId

			SET @message = 'Elemento Actualizado';
		END

		IF(
			ISNULL(@Borrar, 0) = 1
		)
		BEGIN 
			DELETE tgt
			FROM dbo.TblInventarios tgt
			WHERE tgt.InventarioId = @ElementoAlterarId

			SET @message = 'Elemento Eliminado';
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
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
CREATE PROCEDURE dbo.procInsertarMovimientoInventario
@InventarioId	INT = 0,
@TipoMovimiento VARCHAR(200) = '',
@Cantidad		INT = 0,
@Costo			INT = 0,
@loginId		INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';

	BEGIN TRY


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
			WHERE i.InventarioId = @InventarioId
		)
		BEGIN
			SET @message = 'Inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		DECLARE @TipoMovimientoId INT = (
			SELECT TOP 1 mt.TipoMovimientoId
			FROM dbo.TblInventariosMovimientoTipos mt (NOLOCK)
			WHERE mt.Nombre = @TipoMovimiento
			ORDER BY mt.TipoMovimientoId DESC
		);

		IF(ISNULL(@TipoMovimientoId, 0) = 0)
		BEGIN 
			SET @message = 'Tipo de movimiento para inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		INSERT INTO dbo.TblInventariosMovimientos(
			InventarioId,
			TipoMovimientoId,
			Cantidad,
			Costo,
			UsuarioId
		)
		VALUES(
			@InventarioId,
			@TipoMovimientoId,
			@Cantidad,
			@Costo,
			@loginId
		);
		

		SET @result = 'success';
		SET @message = 'Movimiento Registrado';


		SELECT @result [result],
			   @message [message];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN 
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		
		SELECT @result [result],
			   @message [message];
	END CATCH
END
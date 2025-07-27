/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Desrciption: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Desrciption     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE PROCEDURE dbo.procAlteraInventarios
@loginId			INT = 0,
@InventarioMarcaId  INT = 0,
@InventarioTipoId   INT = 0,
@InventarioColorId	INT = 0,
@Cantidad			DECIMAL(10,2) = 0,
@TipoMovimiento		VARCHAR(200) = '',
@InventarioUnidad   VARCHAR(200) = ''
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

		IF(TRY_PARSE(@Cantidad AS DECIMAL(10,2)) <= 0)
		BEGIN 
			SET @message = 'Cantidad debe ser mayor a cero.';
			RAISERROR(@message, 16, 1);
		END

		DECLARE @InventarioUnidadId INT = (
			SELECT TOP 1 mt.InventarioUnidadId
			FROM dbo.TblInventariosUnidades mt (NOLOCK)
			WHERE mt.Nombre = @InventarioUnidad
			ORDER BY mt.InventarioUnidadId DESC
		);

		IF(ISNULL(@InventarioUnidadId, 0) = 0)
		BEGIN 
			SET @message = 'Tipo de unidad para inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		MERGE dbo.TblInventarios AS tgt
		USING (
			SELECT 
				@Cantidad			[Cantidad],
				@InventarioMarcaId  [InventarioMarcaId],
				@InventarioTipoId   [InventarioTipoId],
				@InventarioColorId	[InventarioColorId],
				@TipoMovimiento		[TipoMovimiento],
				@TipoMovimientoId   [TipoMovimientoId],
				@InventarioUnidadId [InventarioUnidadId]
		) AS src 
			ON  (
				tgt.InventarioMarcaId = src.InventarioMarcaId AND 
				tgt.InventarioTipoId = src.InventarioTipoId AND 
				tgt.InventarioColorId = src.InventarioColorId
			)
		WHEN MATCHED THEN
			UPDATE SET tgt.Cantidad = (
				SELECT 
					CASE 
						WHEN UPPER(src.TipoMovimiento) = 'COMPRA' THEN
							tgt.Cantidad + src.Cantidad
						WHEN UPPER(src.TipoMovimiento) = 'VENTA' THEN
							tgt.Cantidad - src.Cantidad
						ELSE 0
					END Cantidad
			)
		WHEN NOT MATCHED THEN
			INSERT (
				InventarioMarcaId,
				InventarioTipoId,
				InventarioColorId,
				Cantidad,
				InventarioUnidadId
			)
			VALUES(
				src.InventarioMarcaId,
				src.InventarioTipoId,
				src.InventarioColorId,
				src.Cantidad,
				src.InventarioUnidadId
			);

		SET @result = 'success';
		SET @message = 'Alteración a inventario correcta.';


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
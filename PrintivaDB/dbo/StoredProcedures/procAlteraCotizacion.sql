CREATE OR ALTER PROCEDURE dbo.procAlteraCotizacion
@ElementoAlterarId INT = 0,
@PedidoId INT = 0,
@CotizacionEstatusId INT = 1,
@FechaVigencia DATETIME = NULL,
@Notas VARCHAR(MAX) = NULL,
@loginId INT = 0,
@Actualizar BIT = 0,
@Borrar BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result VARCHAR(20) = 'success';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
		BEGIN
			RAISERROR('Usuario no encontrado.',16,1);
		END

		IF(ISNULL(@Borrar,0) = 1)
		BEGIN
			IF NOT EXISTS(
				SELECT 1
				FROM dbo.TblCotizaciones c (NOLOCK)
				WHERE c.CotizacionId = @elementoId AND ISNULL(c.EstaActivo,1) = 1
			)
			BEGIN
				RAISERROR('Cotizacion no encontrada.',16,1);
			END

			BEGIN TRAN;

			IF OBJECT_ID('dbo.TblCotizacionItems','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionItems','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionItems','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblCotizacionItems
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			IF OBJECT_ID('dbo.TblCotizacionesItems','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionesItems','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionesItems','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblCotizacionesItems
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			IF OBJECT_ID('dbo.TblPagos','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblPagos','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblPagos','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblPagos
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			UPDATE dbo.TblCotizaciones
			SET EstaActivo = 0
			WHERE CotizacionId = @elementoId;

			COMMIT;

			SET @message = 'Elemento Eliminado';
			SELECT @result [result], @message [message], @elementoId [elementoId];
			RETURN;
		END

		IF(ISNULL(@PedidoId,0) = 0)
		BEGIN
			RAISERROR('PedidoId no puede ser 0.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId)
		BEGIN
			RAISERROR('Pedido no existe.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizacionesEstatus e (NOLOCK) WHERE e.CotizacionEstatusId = @CotizacionEstatusId)
		BEGIN
			RAISERROR('Estatus de cotizacion no existe.',16,1);
		END

		IF EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @elementoId)
		BEGIN
			IF(ISNULL(@Actualizar,0) = 1)
			BEGIN
				UPDATE dbo.TblCotizaciones
				SET PedidoId = @PedidoId,
					CotizacionEstatusId = @CotizacionEstatusId,
					FechaVigencia = @FechaVigencia,
					Notas = @Notas
				WHERE CotizacionId = @elementoId;

				SET @message = 'Elemento Actualizado';
			END
			ELSE
			BEGIN
				SET @message = 'Sin cambios';
			END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TblCotizaciones(
				PedidoId, CotizacionEstatusId, FechaCreacion, FechaVigencia, Notas, EstaActivo
			)
			VALUES(
				@PedidoId, @CotizacionEstatusId, GETDATE(), @FechaVigencia, @Notas, 1
			);

			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SELECT @result [result], @message [message], @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		IF(XACT_STATE() <> 0) ROLLBACK;
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
	END CATCH
END
GO

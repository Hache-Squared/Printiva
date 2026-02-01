CREATE   PROCEDURE dbo.procAlteraPago
@ElementoAlterarId INT = 0,
@CotizacionId INT = 0,
@PagoTipoId INT = 0,
@Monto DECIMAL(10,2) = 0,
@FechaPago DATETIME = NULL,
@Metodo VARCHAR(100) = NULL,
@Referencia VARCHAR(200) = NULL,
@Notas VARCHAR(500) = NULL,
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

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
		BEGIN
			RAISERROR('Cotizacion no encontrada.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblPagoTipos pt (NOLOCK) WHERE pt.PagoTipoId = @PagoTipoId)
		BEGIN
			RAISERROR('Tipo de pago no existe.',16,1);
		END

		IF(ISNULL(@Monto,0) <= 0)
		BEGIN
			RAISERROR('Monto invalido.',16,1);
		END

		IF(@FechaPago IS NULL)
		BEGIN
			RAISERROR('FechaPago requerida.',16,1);
		END

		IF EXISTS(SELECT 1 FROM dbo.TblPagos p (NOLOCK) WHERE p.PagoId = @elementoId)
		BEGIN
			IF(ISNULL(@Borrar,0) = 1)
			BEGIN
				UPDATE dbo.TblPagos
				SET EstaActivo = 0
				WHERE PagoId = @elementoId;

				SET @message = 'Elemento Eliminado';
			END
			ELSE IF(ISNULL(@Actualizar,0) = 1)
			BEGIN
				UPDATE dbo.TblPagos
				SET PagoTipoId = @PagoTipoId,
					Monto = @Monto,
					FechaPago = @FechaPago,
					Metodo = @Metodo,
					Referencia = @Referencia,
					Notas = @Notas
				WHERE PagoId = @elementoId;

				SET @message = 'Elemento Actualizado';
			END
			ELSE
			BEGIN
				SET @message = 'Sin cambios';
			END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TblPagos(
				CotizacionId, PagoTipoId, Monto, FechaPago, Metodo, Referencia, Notas, EstaActivo
			)
			VALUES(
				@CotizacionId, @PagoTipoId, @Monto, @FechaPago, @Metodo, @Referencia, @Notas, 1
			);

			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SELECT @result [result], @message [message], @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
	END CATCH
END
GO


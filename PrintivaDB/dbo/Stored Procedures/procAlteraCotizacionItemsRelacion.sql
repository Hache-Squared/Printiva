CREATE OR ALTER PROCEDURE dbo.procAlteraCotizacionItemsRelacion
@loginId INT = 0,
@CotizacionId INT = 0,
@Json VARCHAR(MAX) = '[]'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result VARCHAR(20) = 'success';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = ISNULL(@CotizacionId,0);

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
		BEGIN
			RAISERROR('Usuario no encontrado.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
		BEGIN
			RAISERROR('Cotizacion no encontrada.',16,1);
		END

		SET @Json = ISNULL(@Json,'[]');

		IF(ISJSON(@Json) = 0)
		BEGIN
			RAISERROR('Json no valido.',16,1);
		END

		CREATE TABLE #Temp(
			CotizacionItemId INT,
			ConceptoTipoId INT,
			ProductoId INT,
			Concepto VARCHAR(200),
			Cantidad DECIMAL(10,2),
			PrecioUnitario DECIMAL(10,2),
			Notas VARCHAR(500)
		);

		INSERT INTO #Temp(
			CotizacionItemId, ConceptoTipoId, ProductoId, Concepto, Cantidad, PrecioUnitario, Notas
		)
		SELECT
			ISNULL(CotizacionItemId,0),
			ConceptoTipoId,
			ProductoId,
			Concepto,
			Cantidad,
			PrecioUnitario,
			Notas
		FROM OPENJSON(@Json) WITH (
			CotizacionItemId INT '$.CotizacionItemId',
			ConceptoTipoId INT '$.ConceptoTipoId',
			ProductoId INT '$.ProductoId',
			Concepto VARCHAR(200) '$.Concepto',
			Cantidad DECIMAL(10,2) '$.Cantidad',
			PrecioUnitario DECIMAL(10,2) '$.PrecioUnitario',
			Notas VARCHAR(500) '$.Notas'
		);

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.Concepto,'') = '')
		BEGIN
			RAISERROR('Algunos conceptos estan vacios.',16,1);
		END

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.Cantidad,0) <= 0)
		BEGIN
			RAISERROR('Algunas cantidades son invalidas.',16,1);
		END

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.PrecioUnitario,0) < 0)
		BEGIN
			RAISERROR('Algunos precios son invalidos.',16,1);
		END

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			LEFT JOIN dbo.TblCotizacionConceptoTipos ct (NOLOCK)
				ON t.ConceptoTipoId = ct.ConceptoTipoId
			WHERE ct.ConceptoTipoId IS NULL
		)
		BEGIN
			RAISERROR('Algunos tipos de concepto no existen.',16,1);
		END

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE t.ProductoId IS NOT NULL AND t.ProductoId <> 0
			AND NOT EXISTS(SELECT 1 FROM dbo.TblProductos p (NOLOCK) WHERE p.ProductoId = t.ProductoId)
		)
		BEGIN
			RAISERROR('Algunos productos no existen.',16,1);
		END

		MERGE dbo.TblCotizacionItems AS TARGET
		USING (
			SELECT
				@CotizacionId AS CotizacionId,
				t.CotizacionItemId,
				t.ConceptoTipoId,
				NULLIF(t.ProductoId,0) AS ProductoId,
				t.Concepto,
				t.Cantidad,
				t.PrecioUnitario,
				t.Notas
			FROM #Temp t
		) AS SOURCE
		ON (
			TARGET.CotizacionId = SOURCE.CotizacionId
			AND TARGET.CotizacionItemId = SOURCE.CotizacionItemId
			AND SOURCE.CotizacionItemId <> 0
		)
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.ConceptoTipoId = SOURCE.ConceptoTipoId,
				TARGET.ProductoId = SOURCE.ProductoId,
				TARGET.Concepto = SOURCE.Concepto,
				TARGET.Cantidad = SOURCE.Cantidad,
				TARGET.PrecioUnitario = SOURCE.PrecioUnitario,
				TARGET.Notas = SOURCE.Notas,
				TARGET.EstaActivo = 1
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CotizacionId, ConceptoTipoId, ProductoId, Concepto, Cantidad, PrecioUnitario, Notas, EstaActivo)
			VALUES (SOURCE.CotizacionId, SOURCE.ConceptoTipoId, SOURCE.ProductoId, SOURCE.Concepto, SOURCE.Cantidad, SOURCE.PrecioUnitario, SOURCE.Notas, 1)
		WHEN NOT MATCHED BY SOURCE AND TARGET.CotizacionId = @CotizacionId THEN
			UPDATE SET TARGET.EstaActivo = 0;

		SET @message = 'Items Actualizados';

		SELECT @result [result], @message [message], @elementoId [elementoId];

		DROP TABLE IF EXISTS #Temp;
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
		DROP TABLE IF EXISTS #Temp;
	END CATCH
END
GO

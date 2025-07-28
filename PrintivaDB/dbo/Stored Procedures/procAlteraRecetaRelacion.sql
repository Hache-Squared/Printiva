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
CREATE PROCEDURE dbo.procAlteraRecetaRelacion
@loginId			INT = 0,
@ElementoAlterarId  INT = 0,
@Json				VARCHAR(MAX) = '[]'
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
			FROM dbo.TblRecetas r (NOLOCK)
			WHERE r.RecetaId = @elementoId
		)
		BEGIN
			SET @message = 'Receta no encontrada.';
			RAISERROR(@message, 16, 1);
		END

		SET @Json = ISNULL(@Json, '[]')
		
		IF(ISJSON(@Json) = 0)
		BEGIN 
			SET @message = 'Json no valido.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #Temp(
			Id INT PRIMARY KEY IDENTITY(1,1),
			InventarioId INT,
			Cantidad DECIMAL(10,2)
		)

		INSERT INTO #Temp(InventarioId, Cantidad)
		SELECT 
			InventarioId,
			Cantidad
		FROM OPENJSON(@Json) WITH (
			InventarioId INT '$.InventarioId',
			Cantidad	 DECIMAL(10,2) '$.Cantidad'
		);

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE ISNULL(t.Cantidad,0) = 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades no tienen valor.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE ISNumeric(t.Cantidad) = 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades no son un numero.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE t.Cantidad < 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades son negativas.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			LEFT JOIN dbo.TblInventarios i (NOLOCK)
				ON t.InventarioId = i.InventarioId
			WHERE i.InventarioId IS NULL
		)
		BEGIN 
			SET @message = 'Algunos elementos de inventario no existen.';
			RAISERROR(@message, 16, 1);
		END;

		MERGE dbo.TblRecetasInventarios AS TARGET
		USING (
			SELECT 
				@elementoId [RecetaId],
				t.InventarioId [InventarioId],
				t.Cantidad [Cantidad]
			FROM #Temp t
		) AS SOURCE  
			ON (
				TARGET.RecetaId = SOURCE.RecetaId AND
				TARGET.InventarioId = SOURCE.InventarioId
			)
		WHEN MATCHED THEN 
			UPDATE SET TARGET.Cantidad = SOURCE.Cantidad
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (
				RecetaId,
				InventarioId,
				Cantidad
			)
			VALUES(
				SOURCE.RecetaId,
				SOURCE.InventarioId,
				SOURCE.Cantidad
			)
		WHEN NOT MATCHED BY SOURCE THEN
			DELETE; 

			

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
	DROP TABLE IF EXISTS #Temp;
END
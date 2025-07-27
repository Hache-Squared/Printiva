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
CREATE PROCEDURE dbo.procAlteraInventariosMarca
@loginId INT = 0
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
			SET @message = 'Usuario no encontrado';
			RAISERROR(@message, 16, 1);
		END


		SET @result = 'success';
		SET @message = 'Ningun error';


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
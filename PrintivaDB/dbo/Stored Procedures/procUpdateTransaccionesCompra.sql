-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
CREATE PROCEDURE [dbo].[procUpdateTransaccionesCompra]  
 @UsuarioId int,  
 @FechaTransaccion date,  
 @Monto decimal(18,2),  
 @Nota nvarchar(1000) = NULL  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
  DECLARE @cuentaDefault INT = (
	SELECT TOP 1 c.Id
	FROM Cuentas c (NOLOCK)
	WHERE c.Nombre = 'Efectivo'
  )

  DECLARE @CategoriaDefault INT = (
	SELECT TOP 1 c.Id
	FROM Categorias c (NOLOCK)
	WHERE c.Nombre = 'Compra'
  )

    -- Insert statements for procedure here  
 INSERT INTO Transacciones(UsuarioId, FechaTransaccion, Monto, CategoriaId,  
 CuentaId, Nota)  
 Values(@UsuarioId, @FechaTransaccion, ABS(@Monto), @CategoriaDefault, @cuentaDefault, @Nota)  
  
 UPDATE Cuentas  
 SET Balance += @Monto  
 WHERE Id = @cuentaDefault;  
  
 SELECT SCOPE_IDENTITY();  
END  
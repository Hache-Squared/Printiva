--En este archivo servira para incluir valores por defecto a nuestra base de datos

DECLARE @version VARCHAR(100) = '1.0.0';


IF(@version = '1.0.0')
BEGIN 
	CREATE TABLE #TempCatalogoInventarioUnidades(
		Nombre VARCHAR(200)
	);

	INSERT INTO #TempCatalogoInventarioUnidades(Nombre)
	VALUES ('Unidad'),
		   ('Gramos');

	INSERT INTO dbo.TblInventariosUnidades(Nombre)
	SELECT temp.Nombre
	FROM #TempCatalogoInventarioUnidades temp
	LEFT JOIN dbo.TblInventariosUnidades it (NOLOCK)
		ON temp.Nombre = it.Nombre
	WHERE it.Nombre IS NULL
	
	DROP TABLE IF EXISTS #TempCatalogoInventarioUnidades;
END;

IF(@version = '1.0.0')
BEGIN 
	CREATE TABLE #TempCatalogoInventarioMovimientosTipos(
		Nombre VARCHAR(200)
	);

	INSERT INTO #TempCatalogoInventarioMovimientosTipos(Nombre)
	VALUES ('Compra'),
		   ('Venta');

	INSERT INTO dbo.TblInventariosMovimientoTipos(Nombre)
	SELECT temp.Nombre
	FROM #TempCatalogoInventarioMovimientosTipos temp
	LEFT JOIN dbo.TblInventariosMovimientoTipos it (NOLOCK)
		ON temp.Nombre = it.Nombre
	WHERE it.Nombre IS NULL
	
	DROP TABLE IF EXISTS #TempCatalogoInventarioMovimientosTipos;
END;

IF(@version = '1.0.0')
BEGIN 

	IF NOT EXISTS (
		SELECT 1 
		FROM TiposCuentas c
		WHERE c.Nombre = 'Efectivo'
	)
	BEGIN 
		INSERT INTO TiposCuentas(Nombre, UsuarioId, Orden)
		VALUES('Efectivo', 1, 1);
	END



	IF NOT EXISTS (
		SELECT 1 
		FROM Cuentas c
		WHERE c.Nombre = 'Efectivo'
	)
	BEGIN
	
		DECLARE @tipoCuentaId INT = (
			SELECT TOP 1 Id
			FROM TiposCuentas t
			WHERE t.Nombre = 'Efectivo'
		) 

		INSERT INTO Cuentas(Nombre, TipoCuentaId, Balance, Descripcion)
		VALUES('Efectivo', @tipoCuentaId, 0, '')
	END

	IF NOT EXISTS (
		SELECT 1
		FROM TiposOperaciones c (NOLOCK)
		WHERE c.Descripcion = 'Ingreso'
	)
	BEGIN 
		INSERT INTO TiposOperaciones(Descripcion)
		VALUES('Ingreso')
	END

	IF NOT EXISTS (
		SELECT 1
		FROM TiposOperaciones c (NOLOCK)
		WHERE c.Descripcion = 'Gasto'
	)
	BEGIN 
		INSERT INTO TiposOperaciones(Descripcion)
		VALUES('Gasto')
	END


	IF NOT EXISTS (
		SELECT 1
		FROM Categorias c (NOLOCK)
		WHERE c.Nombre = 'Compra'
	)
	BEGIN 
	
		INSERT INTO Categorias(Nombre, TipoOperacionId, UsuarioId)
		VALUES('Compra', 2, 1)
	END

	IF NOT EXISTS (
		SELECT 1
		FROM Categorias c (NOLOCK)
		WHERE c.Nombre = 'Venta'
	)
	BEGIN 
		INSERT INTO Categorias(Nombre, TipoOperacionId, UsuarioId)
		VALUES('Venta', 1, 1)
	END
END
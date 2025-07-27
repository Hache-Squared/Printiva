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

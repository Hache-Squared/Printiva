DECLARE @version VARCHAR(100) = '1.0.0';


IF(@version = '1.0.0')
BEGIN 
	CREATE TABLE #TempCatalogoInventarioUnidades(
		Nombre VARCHAR(200)
	);

	INSERT INTO #TempCatalogoInventarioUnidades(Nombre)
	VALUES ('Unidad'),
		   ('Gramos');

	INSERT INTO dbo.TblInventariosTipos(Nombre)
	SELECT temp.Nombre
	FROM #TempCatalogoInventarioUnidades temp
	LEFT JOIN dbo.TblInventariosTipos it (NOLOCK)
		ON temp.Nombre = it.Nombre
	WHERE it.Nombre IS NULL
	
	DROP TABLE IF EXISTS #TempCatalogoInventarioUnidades;
END;

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
    @objId INT,
    @type  CHAR(2),
    @name  NVARCHAR(512),
    @def   NVARCHAR(MAX),
    @u     NVARCHAR(MAX),
    @pos   INT,
    @body  NVARCHAR(MAX),
    @head  NVARCHAR(50);

DECLARE cur CURSOR FAST_FORWARD FOR
SELECT o.object_id, o.[type],
       QUOTENAME(SCHEMA_NAME(o.schema_id)) + N'.' + QUOTENAME(o.name) AS ObjName
FROM sys.objects o
JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE (m.uses_ansi_nulls = 0 OR m.uses_quoted_identifier = 0)
  AND o.[type] IN ('P','V','FN','IF','TF')
ORDER BY o.[type], ObjName;

OPEN cur;
FETCH NEXT FROM cur INTO @objId, @type, @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @def = sm.[definition]
    FROM sys.sql_modules sm
    WHERE sm.object_id = @objId;

    SET @u = UPPER(@def);
    SET @pos = NULL;

    -- encuentra el inicio del statement (CREATE/ALTER...) tolerando espacios/comentarios con %
    IF @type = 'P'
    BEGIN
        SET @pos = NULLIF(PATINDEX('%CREATE%PROCEDURE%', @u), 0);
        IF @pos IS NULL SET @pos = NULLIF(PATINDEX('%CREATE%PROC%', @u), 0);
        IF @pos IS NULL SET @pos = NULLIF(PATINDEX('%ALTER%PROCEDURE%', @u), 0);
        IF @pos IS NULL SET @pos = NULLIF(PATINDEX('%ALTER%PROC%', @u), 0);
    END
    ELSE IF @type = 'V'
    BEGIN
        SET @pos = NULLIF(PATINDEX('%CREATE%VIEW%', @u), 0);
        IF @pos IS NULL SET @pos = NULLIF(PATINDEX('%ALTER%VIEW%', @u), 0);
    END
    ELSE
    BEGIN
        SET @pos = NULLIF(PATINDEX('%CREATE%FUNCTION%', @u), 0);
        IF @pos IS NULL SET @pos = NULLIF(PATINDEX('%ALTER%FUNCTION%', @u), 0);
    END

    IF @pos IS NULL
    BEGIN
        PRINT N'FAIL-> ' + @name + N' | No encontré CREATE/ALTER en definition';
        FETCH NEXT FROM cur INTO @objId, @type, @name;
        CONTINUE;
    END

    -- recorta desde el inicio detectado
    SET @body = LTRIM(SUBSTRING(@def, @pos, 2147483647));

    -- FORZAR: si empieza con CREATE, cámbialo a ALTER (solo la primera palabra)
    SET @head = UPPER(LEFT(LTRIM(@body), 6));
    IF @head = N'CREATE'
    BEGIN
        -- reemplaza solo el primer "CREATE" al inicio del string
        SET @body = STUFF(LTRIM(@body), 1, 6, N'ALTER');
    END

    BEGIN TRY
        -- para que queden grabadas bien las opciones en sys.sql_modules
        SET ANSI_NULLS ON;
        SET QUOTED_IDENTIFIER ON;

        EXEC sys.sp_executesql @body;

        PRINT N'OK  -> ' + @name;
    END TRY
    BEGIN CATCH
        PRINT N'FAIL-> ' + @name + N' | ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM cur INTO @objId, @type, @name;
END

CLOSE cur;
DEALLOCATE cur;

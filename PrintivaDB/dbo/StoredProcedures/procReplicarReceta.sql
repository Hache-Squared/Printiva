CREATE   PROCEDURE dbo.procReplicarReceta
    @loginId           INT = 0,
    @RecetaIdOrigen    INT = 0,
    @NombreNuevo       VARCHAR(200) = NULL,   -- opcional
    @ProductoIdNuevo   INT = NULL             -- opcional: si quieres clonar a otro producto
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result     VARCHAR(100) = '';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblRecetas r (NOLOCK)
            WHERE r.RecetaId = @RecetaIdOrigen AND r.EstaActivo = 1
        )
            RAISERROR('Receta origen no encontrada o inactiva.', 16, 1);

        DECLARE
            @NombreFinal       VARCHAR(200),
            @NombreBase        VARCHAR(200),
            @ProductoIdFinal   INT,
            @TiempoImpresion   VARCHAR(200),
            @TiempoImpMin      INT,
            @TiempoPostMin     INT;

        SELECT
            @ProductoIdFinal = COALESCE(@ProductoIdNuevo, r.ProductoId),
            @TiempoImpresion = r.TiempoImpresion,
            @TiempoImpMin    = COALESCE(r.TiempoImpresionMin, TRY_CONVERT(INT, NULLIF(r.TiempoImpresion,'')), 0),
            @TiempoPostMin   = COALESCE(r.TiempoPostMin, 0),
            @NombreBase      = r.Nombre
        FROM dbo.TblRecetas r
        WHERE r.RecetaId = @RecetaIdOrigen;

        -- Nombre: si no mandas, genera " (copia)" y asegura unicidad
        IF (NULLIF(@NombreNuevo,'') IS NULL)
        BEGIN
            SET @NombreBase  = CONCAT(@NombreBase, ' (copia)');
            SET @NombreFinal = @NombreBase;

            DECLARE @i INT = 2;
            WHILE EXISTS (SELECT 1 FROM dbo.TblRecetas WHERE Nombre = @NombreFinal)
            BEGIN
                SET @NombreFinal = CONCAT(@NombreBase, ' ', @i);
                SET @i += 1;
            END
        END
        ELSE
        BEGIN
            SET @NombreFinal = @NombreNuevo;

            -- si quieres que truene cuando el nombre existe, deja esto así:
            IF EXISTS (SELECT 1 FROM dbo.TblRecetas WHERE Nombre = @NombreFinal)
                RAISERROR('Nombre ya existe actualmente.', 16, 1);

            -- (si prefieres auto-sufijo también aquí, te lo ajusto)
        END

        BEGIN TRAN;

        INSERT INTO dbo.TblRecetas
        (
            Nombre,
            ProductoId,
            TiempoImpresion,
            TiempoImpresionMin,
            TiempoPostMin,
            EstaActivo
        )
        VALUES
        (
            @NombreFinal,
            @ProductoIdFinal,
            ISNULL(@TiempoImpresion,''),
            ISNULL(@TiempoImpMin,0),
            ISNULL(@TiempoPostMin,0),
            1
        );

        SET @elementoId = SCOPE_IDENTITY();

        -- Copiar materiales (solo activos)
        INSERT INTO dbo.TblRecetasInventarios (RecetaId, InventarioId, Cantidad, EstaActivo)
        SELECT
            @elementoId,
            ri.InventarioId,
            ri.Cantidad,
            1
        FROM dbo.TblRecetasInventarios ri
        WHERE ri.RecetaId = @RecetaIdOrigen
          AND ri.EstaActivo = 1;

        COMMIT;

        SET @result = 'success';
        SET @message = 'Receta replicada';

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


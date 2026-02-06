CREATE   PROCEDURE dbo.procProduccionAccionesDisponibles
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pr WITH (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.EstaActivo=1
    )
    BEGIN
        SELECT TOP 0
            'mover' AS AccionCodigo,
            '' AS AccionTexto,
            0 AS HaciaEstatusId,
            CAST(0 AS BIT) AS RequiereConfirmacion,
            CAST(0 AS BIT) AS Bloqueada,
            '' AS Motivo;
        RETURN;
    END

    DECLARE @DesdeId INT,
            @ProductoId INT,
            @CantidadItem INT,
            @InventarioAplicado BIT,
            @RecetaItemId INT;

    SELECT
        @DesdeId = pr.ProduccionEstatusId,
        @ProductoId = pr.ProductoId,
        @CantidadItem = pr.Cantidad,
        @InventarioAplicado = pr.InventarioAplicado,
        @RecetaItemId = pr.RecetaId
    FROM dbo.TblProduccionItems pr WITH (NOLOCK)
    WHERE pr.ProduccionItemId = @ProduccionItemId;

    DECLARE @PostId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus WITH (NOLOCK)
        WHERE EstaActivo=1 AND (
               Nombre = N'Post-procesado'
            OR Nombre = N'Post-proceso'
            OR Nombre = N'Post Procesado'
            OR Nombre LIKE N'Post%'
        )
        ORDER BY Orden ASC
    );

    DECLARE @PostBloqueada BIT = 0;
    DECLARE @PostMotivo NVARCHAR(500) = N'';

    IF (@PostId IS NOT NULL
        AND ISNULL(@InventarioAplicado,0)=0
        AND EXISTS (
            SELECT 1
            FROM dbo.TblProduccionEstatusTransiciones WITH (NOLOCK)
            WHERE DesdeEstatusId=@DesdeId AND HaciaEstatusId=@PostId
        )
    )
    BEGIN
        IF @RecetaItemId IS NULL
        BEGIN
            SET @PostBloqueada = 1;
            SET @PostMotivo = N'Selecciona una receta para este item antes de pasar a Post-procesado.';
        END
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblRecetas r WITH (NOLOCK)
            WHERE r.RecetaId=@RecetaItemId AND r.ProductoId=@ProductoId AND r.EstaActivo=1
        )
        BEGIN
            SET @PostBloqueada = 1;
            SET @PostMotivo = N'La receta seleccionada no es válida o no está activa.';
        END
        ELSE
        BEGIN
            DECLARE @Req TABLE (InventarioId INT PRIMARY KEY, Requiere DECIMAL(18,2) NOT NULL);

            INSERT INTO @Req (InventarioId, Requiere)
            SELECT
                ri.InventarioId,
                CAST(SUM(ri.Cantidad) * @CantidadItem AS DECIMAL(18,2))
            FROM dbo.TblRecetasInventarios ri WITH (NOLOCK)
            WHERE ri.RecetaId=@RecetaItemId AND ri.EstaActivo=1
            GROUP BY ri.InventarioId;

            IF NOT EXISTS (SELECT 1 FROM @Req)
            BEGIN
                SET @PostBloqueada = 1;
                SET @PostMotivo = N'La receta seleccionada no tiene insumos (TblRecetasInventarios).';
            END
            ELSE
            BEGIN
                ;WITH F AS
                (
                    SELECT
                        r.InventarioId,
                        COALESCE(n.Nombre, CONCAT(N'InventarioId=', r.InventarioId)) AS NombreInsumo,
                        r.Requiere,
                        CAST(ISNULL(i.Cantidad,0) AS DECIMAL(18,2)) AS Disponible,
                        i.InventarioUnidadId
                    FROM @Req r
                    LEFT JOIN dbo.TblInventarios i WITH (NOLOCK)
                           ON i.InventarioId=r.InventarioId
                          AND i.EstaActivo=1
                    LEFT JOIN dbo.TblInventariosNombres n WITH (NOLOCK)
                           ON n.InventarioNombreId = i.InventarioNombreId
                    WHERE i.InventarioId IS NULL OR i.Cantidad < r.Requiere
                )
                SELECT
                    @PostBloqueada = CASE WHEN EXISTS (SELECT 1 FROM F) THEN 1 ELSE 0 END,
                    @PostMotivo =
                        CASE WHEN EXISTS (SELECT 1 FROM F) THEN
                            N'Falta inventario: ' +
                            STUFF((
                                SELECT
                                    N'; ' + f.NombreInsumo +
                                    N' requiere=' + CAST(f.Requiere AS NVARCHAR(40)) +
                                    N' disponible=' + CAST(f.Disponible AS NVARCHAR(40)) +
                                    N' unidad=' + ISNULL(u.Nombre, N'(sin unidad)')
                                FROM F f
                                LEFT JOIN dbo.TblInventariosUnidades u WITH (NOLOCK)
                                       ON u.InventarioUnidadId = f.InventarioUnidadId
                                FOR XML PATH(''), TYPE
                            ).value('.','nvarchar(max)'), 1, 2, N'')
                        ELSE N'' END;
            END
        END
    END

    SELECT
        'mover' AS AccionCodigo,
        CONCAT('Mover a: ', pe.Nombre) AS AccionTexto,
        t.HaciaEstatusId,
        CAST(CASE WHEN pe.Nombre = N'Entregado' THEN 1 ELSE 0 END AS BIT) AS RequiereConfirmacion,
        CAST(CASE WHEN t.HaciaEstatusId = @PostId THEN @PostBloqueada ELSE 0 END AS BIT) AS Bloqueada,
        CASE WHEN t.HaciaEstatusId = @PostId THEN @PostMotivo ELSE '' END AS Motivo
    FROM dbo.TblProduccionEstatusTransiciones t WITH (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus pe WITH (NOLOCK)
        ON pe.ProduccionEstatusId = t.HaciaEstatusId
    WHERE t.DesdeEstatusId = @DesdeId
      AND pe.EstaActivo = 1
    ORDER BY pe.Orden ASC;
END
GO


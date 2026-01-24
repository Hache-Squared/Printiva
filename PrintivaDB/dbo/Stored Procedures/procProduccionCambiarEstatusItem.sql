CREATE OR ALTER PROCEDURE dbo.procProduccionCambiarEstatusItem
    @ProduccionItemId INT,
    @HaciaEstatusId INT,
    @Notas NVARCHAR(500) = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = 'Estatus actualizado.';
    DECLARE @elementoId INT = @ProduccionItemId;

    BEGIN TRY
        IF (@HaciaEstatusId IS NULL OR @HaciaEstatusId <= 0)
            THROW 50000, 'Acción inválida: HaciaEstatusId vacío/0 (UI).', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblProduccionItems pr WITH (NOLOCK)
            WHERE pr.ProduccionItemId=@ProduccionItemId
              AND pr.UsuarioId=@loginId
              AND pr.EstaActivo=1
        )
            THROW 50000, 'Item de producción no encontrado.', 1;

        BEGIN TRAN;

        -- Lock item para evitar doble consumo
        DECLARE @DesdeId INT;
        DECLARE @PedidoId INT;
        DECLARE @PedidoItemId INT;
        DECLARE @ProductoId INT;
        DECLARE @CantidadItem INT;
        DECLARE @InventarioAplicado BIT;
        DECLARE @RecetaId INT;

        SELECT
            @DesdeId = pr.ProduccionEstatusId,
            @PedidoId = pr.PedidoId,
            @PedidoItemId = pr.PedidoItemId,
            @ProductoId = pr.ProductoId,
            @CantidadItem = pr.Cantidad,
            @InventarioAplicado = pr.InventarioAplicado,
            @RecetaId = pr.RecetaId
        FROM dbo.TblProduccionItems pr WITH (UPDLOCK, HOLDLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.UsuarioId=@loginId
          AND pr.EstaActivo=1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblProduccionEstatusTransiciones WITH (NOLOCK)
            WHERE DesdeEstatusId=@DesdeId AND HaciaEstatusId=@HaciaEstatusId
        )
        BEGIN
            DECLARE @MensajeError NVARCHAR(200) = CONCAT('Transición no permitida. Desde=', @DesdeId, ' Hacia=', @HaciaEstatusId);
            THROW 50000, @MensajeError, 1;
        END

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

        -- Si va a Post y aún no se aplicó inventario: validar receta + inventario y descontar
        IF (@PostId IS NOT NULL AND @HaciaEstatusId=@PostId AND ISNULL(@InventarioAplicado,0)=0)
        BEGIN
            IF @RecetaId IS NULL
                THROW 50000, 'Selecciona una receta antes de pasar a Post-procesado.', 1;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblRecetas r WITH (NOLOCK)
                WHERE r.RecetaId=@RecetaId
                  AND r.ProductoId=@ProductoId
                  AND r.EstaActivo=1
            )
                THROW 50000, 'La receta seleccionada no es válida o no está activa.', 1;

            DECLARE @Req TABLE (InventarioId INT PRIMARY KEY, Requiere DECIMAL(18,2) NOT NULL);

            INSERT INTO @Req (InventarioId, Requiere)
            SELECT
                ri.InventarioId,
                CAST(SUM(ri.Cantidad) * @CantidadItem AS DECIMAL(18,2))
            FROM dbo.TblRecetasInventarios ri WITH (NOLOCK)
            WHERE ri.RecetaId=@RecetaId AND ri.EstaActivo=1
            GROUP BY ri.InventarioId;

            IF NOT EXISTS (SELECT 1 FROM @Req)
                THROW 50000, 'La receta seleccionada no tiene insumos (TblRecetasInventarios).', 1;

            -- FIX: tabla variable para faltantes (evita CTE + IF)
            DECLARE @Faltantes TABLE
            (
                InventarioId INT NOT NULL,
                NombreInsumo NVARCHAR(200) NOT NULL,
                Requiere DECIMAL(18,2) NOT NULL,
                Disponible DECIMAL(18,2) NOT NULL,
                InventarioUnidadId INT NULL
            );

            INSERT INTO @Faltantes (InventarioId, NombreInsumo, Requiere, Disponible, InventarioUnidadId)
            SELECT
                r.InventarioId,
                COALESCE(n.Nombre, CONCAT(N'InventarioId=', r.InventarioId)) AS NombreInsumo,
                r.Requiere,
                CAST(ISNULL(i.Cantidad,0) AS DECIMAL(18,2)) AS Disponible,
                i.InventarioUnidadId
            FROM @Req r
            LEFT JOIN dbo.TblInventarios i WITH (UPDLOCK, HOLDLOCK)
                   ON i.InventarioId=r.InventarioId
                  AND i.EstaActivo=1
            LEFT JOIN dbo.TblInventariosNombres n WITH (NOLOCK)
                   ON n.InventarioNombreId = i.InventarioNombreId
            WHERE i.InventarioId IS NULL OR i.Cantidad < r.Requiere;

            IF EXISTS (SELECT 1 FROM @Faltantes)
            BEGIN
                DECLARE @msg NVARCHAR(MAX) =
                    N'Inventario insuficiente: ' +
                    STUFF((
                        SELECT
                            N'; ' + f.NombreInsumo +
                            N' requiere=' + CAST(f.Requiere AS NVARCHAR(40)) +
                            N' disponible=' + CAST(f.Disponible AS NVARCHAR(40)) +
                            N' unidad=' + ISNULL(u.Nombre, N'(sin unidad)')
                        FROM @Faltantes f
                        LEFT JOIN dbo.TblInventariosUnidades u WITH (NOLOCK)
                               ON u.InventarioUnidadId = f.InventarioUnidadId
                        FOR XML PATH(''), TYPE
                    ).value('.','nvarchar(max)'), 1, 2, N'');
                THROW 50000, @msg, 1;
            END

            /* ============================
               >>> SOLO LO NUEVO: SNAPSHOT LOG <<<
               - arma detalle con nombres + disponibles antes/después
               - se inserta 1 fila por InventarioId requerido
               ============================ */

            DECLARE @RecetaNombre NVARCHAR(200) =
            (
                SELECT TOP 1 r.Nombre
                FROM dbo.TblRecetas r WITH (NOLOCK)
                WHERE r.RecetaId = @RecetaId
            );

            DECLARE @ConsumoDet TABLE
            (
                InventarioId INT NOT NULL,
                Cantidad DECIMAL(18,2) NOT NULL,
                InventarioUnidadId INT NULL,
                InsumoNombre NVARCHAR(200) NULL,
                UnidadNombre NVARCHAR(100) NULL,
                DisponibleAntes DECIMAL(18,2) NULL,
                DisponibleDespues DECIMAL(18,2) NULL
            );

            INSERT INTO @ConsumoDet (InventarioId, Cantidad, InventarioUnidadId, InsumoNombre, UnidadNombre, DisponibleAntes, DisponibleDespues)
            SELECT
                r.InventarioId,
                r.Requiere AS Cantidad,
                i.InventarioUnidadId,
                COALESCE(n.Nombre, CONCAT(N'InventarioId=', r.InventarioId)) AS InsumoNombre,
                u.Nombre AS UnidadNombre,
                CAST(ISNULL(i.Cantidad,0) AS DECIMAL(18,2)) AS DisponibleAntes,
                CAST(ISNULL(i.Cantidad,0) - r.Requiere AS DECIMAL(18,2)) AS DisponibleDespues
            FROM @Req r
            LEFT JOIN dbo.TblInventarios i WITH (UPDLOCK, HOLDLOCK)
                   ON i.InventarioId = r.InventarioId
                  AND i.EstaActivo=1
            LEFT JOIN dbo.TblInventariosNombres n WITH (NOLOCK)
                   ON n.InventarioNombreId = i.InventarioNombreId
            LEFT JOIN dbo.TblInventariosUnidades u WITH (NOLOCK)
                   ON u.InventarioUnidadId = i.InventarioUnidadId;

            /* ============================
               (Tu lógica original) Descontar inventario
               ============================ */
            UPDATE i
               SET i.Cantidad = i.Cantidad - r.Requiere
            FROM dbo.TblInventarios i
            INNER JOIN @Req r ON r.InventarioId = i.InventarioId
            WHERE i.EstaActivo=1;

            /* ============================
               >>> INSERT A LA TABLA LOG (SNAPSHOT) <<<
               ============================ */
            INSERT INTO dbo.TblProduccionInventarioConsumo
            (
                ProduccionItemId,
                RecetaId,
                InventarioId,
                Cantidad,
                InventarioUnidadId,
                UsuarioId,
                Fecha,

                -- extras snapshot (si agregaste columnas)
                PedidoId,
                PedidoItemId,
                ProductoId,
                CantidadItem,
                DesdeEstatusId,
                HaciaEstatusId,
                Notas,
                RecetaNombre,
                InsumoNombre,
                UnidadNombre,
                DisponibleAntes,
                DisponibleDespues
            )
            SELECT
                @ProduccionItemId,
                @RecetaId,
                d.InventarioId,
                d.Cantidad,
                d.InventarioUnidadId,
                @loginId,
                SYSDATETIME(),

                @PedidoId,
                @PedidoItemId,
                @ProductoId,
                @CantidadItem,
                @DesdeId,
                @HaciaEstatusId,
                NULLIF(@Notas,''),
                @RecetaNombre,
                d.InsumoNombre,
                d.UnidadNombre,
                d.DisponibleAntes,
                d.DisponibleDespues
            FROM @ConsumoDet d;

            -- Marca aplicado (candado de receta + idempotencia)
            UPDATE dbo.TblProduccionItems
               SET InventarioAplicado = 1,
                   FechaActualizacion = SYSDATETIME()
            WHERE ProduccionItemId=@ProduccionItemId;
        END

        -- Cambio de estatus + bitácora
        UPDATE dbo.TblProduccionItems
           SET ProduccionEstatusId = @HaciaEstatusId,
               Notas = NULLIF(@Notas,''),
               FechaActualizacion = SYSDATETIME()
        WHERE ProduccionItemId=@ProduccionItemId;

        INSERT INTO dbo.TblProduccionBitacora
            (ProduccionItemId, PedidoId, PedidoItemId, UsuarioId, DesdeEstatusId, HaciaEstatusId, Notas)
        VALUES
            (@ProduccionItemId, @PedidoId, @PedidoItemId, @loginId, @DesdeId, @HaciaEstatusId, NULLIF(@Notas,''));

        COMMIT;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

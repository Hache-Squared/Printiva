CREATE   PROCEDURE dbo.procAlteraComprasV2
    @ElementoAlterarId INT = 0,
    @Descripcion VARCHAR(MAX) = '',
    @CompraTipoId INT = 0,
    @FilamentoTipoId INT = NULL,      -- compat, ya no se usa
    @CompraCategoriaId INT = 0,

    @InventarioId INT = NULL,
    @Cantidad DECIMAL(10,2) = 0,
    @CostoUnitario DECIMAL(18,2) = 0,
    @CostoTotal DECIMAL(18,2) = 0,

    @FechaCreacion DATETIME = NULL,
    @loginId INT = 0,

    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @result  VARCHAR(50) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

    DECLARE @EsInventario BIT = 0;

    DECLARE @PrevInventarioId INT = NULL;
    DECLARE @PrevCantidad DECIMAL(10,2) = 0;
    DECLARE @PrevCostoTotal DECIMAL(18,2) = 0;
    DECLARE @PrevEsInventario BIT = 0;

    DECLARE @TipoMov_COMPRA   INT = (SELECT TOP 1 TipoMovimientoId FROM dbo.TblInventariosMovimientoTipos WHERE Nombre='COMPRA');
    DECLARE @TipoMov_AJUSTE   INT = (SELECT TOP 1 TipoMovimientoId FROM dbo.TblInventariosMovimientoTipos WHERE Nombre='AJUSTE_COMPRA');
    DECLARE @TipoMov_REVERSA  INT = (SELECT TOP 1 TipoMovimientoId FROM dbo.TblInventariosMovimientoTipos WHERE Nombre='REVERSA_COMPRA');

    -- ✅ NUEVO: snapshots
    DECLARE @InvAntes   DECIMAL(18,4) = NULL;
    DECLARE @InvDespues DECIMAL(18,4) = NULL;

    BEGIN TRY
        BEGIN TRAN;

        /* =========
           Usuario
           ========= */
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u WITH (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        /* =========
           Validar tipos de movimiento (si hay inventario)
           ========= */
        IF (@TipoMov_COMPRA IS NULL OR @TipoMov_AJUSTE IS NULL OR @TipoMov_REVERSA IS NULL)
        BEGIN
            SET @message = 'Faltan tipos de movimiento en TblInventariosMovimientoTipos (COMPRA / AJUSTE_COMPRA / REVERSA_COMPRA).';
            RAISERROR(@message, 16, 1);
        END

        /* ============================
           BORRAR (borrado lógico) - PRIMERO
           ============================ */
        IF (ISNULL(@Borrar,0) = 1)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.TblCompras c WITH (NOLOCK) WHERE c.CompraId = @ElementoAlterarId AND c.EstaActivo = 1)
            BEGIN
                SET @message = 'Registro no encontrado o ya está inactivo.';
                RAISERROR(@message, 16, 1);
            END

            /* Trae datos previos reales (NO depende de lo que mande C#) */
            SELECT
                @PrevInventarioId = c.InventarioId,
                @PrevCantidad     = c.Cantidad,
                @PrevCostoTotal   = c.CostoTotal,
                @PrevEsInventario = ct.EsInventario
            FROM dbo.TblCompras c WITH (NOLOCK)
            INNER JOIN dbo.TblComprasTipos ct WITH (NOLOCK) ON c.CompraTipoId = ct.CompraTipoId
            WHERE c.CompraId = @ElementoAlterarId;

            /* Reversa inventario si aplicaba */
            IF (@PrevEsInventario = 1 AND @PrevInventarioId IS NOT NULL)
            BEGIN
                /* Validar no quede negativo */
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblInventarios i WITH (NOLOCK)
                    WHERE i.InventarioId = @PrevInventarioId
                      AND i.EstaActivo = 1
                      AND (i.Cantidad - @PrevCantidad) < 0
                )
                BEGIN
                    SET @message = 'No se puede borrar: la reversa dejaría inventario en negativo.';
                    RAISERROR(@message, 16, 1);
                END

                -- ✅ snapshot ANTES/DESPUÉS con lock
                SELECT @InvAntes = CAST(i.Cantidad AS DECIMAL(18,4))
                FROM dbo.TblInventarios i WITH (UPDLOCK, ROWLOCK)
                WHERE i.InventarioId = @PrevInventarioId;

                SET @InvDespues = @InvAntes - CAST(@PrevCantidad AS DECIMAL(18,4));

                UPDATE dbo.TblInventarios
                    SET Cantidad = Cantidad - @PrevCantidad
                WHERE InventarioId = @PrevInventarioId;

                INSERT INTO dbo.TblInventariosMovimientos
                    (InventarioId, TipoMovimientoId, Cantidad, Costo, FechaCreacion, UsuarioId, CompraId, DisponibleAntes, DisponibleDespues)
                VALUES
                    (@PrevInventarioId, @TipoMov_REVERSA, -@PrevCantidad, -@PrevCostoTotal, GETUTCDATE(), @loginId,
                     @ElementoAlterarId, @InvAntes, @InvDespues);
            END

            UPDATE dbo.TblCompras
                SET EstaActivo = 0,
                    UsuarioId = ISNULL(UsuarioId, @loginId)
            WHERE CompraId = @ElementoAlterarId;

            COMMIT TRAN;

            SET @result = 'success';
            SET @message = 'Compra eliminada (lógica).';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* ============================
           A partir de aquí: CREATE / UPDATE
           ============================ */

        SET @FechaCreacion = ISNULL(@FechaCreacion, GETUTCDATE());

        /* Tipo debe existir y estar activo */
        IF NOT EXISTS (SELECT 1 FROM dbo.TblComprasTipos WITH (NOLOCK) WHERE CompraTipoId = @CompraTipoId AND EstaActivo = 1)
        BEGIN
            SET @message = 'Tipo de compra no existe / inactivo.';
            RAISERROR(@message, 16, 1);
        END

        SELECT
            @EsInventario = EsInventario
        FROM dbo.TblComprasTipos WITH (NOLOCK)
        WHERE CompraTipoId = @CompraTipoId;

        /* Categoria debe existir y estar activa */
        IF NOT EXISTS (SELECT 1 FROM dbo.TblComprasCategorias WITH (NOLOCK) WHERE CompraCategoriaId = @CompraCategoriaId AND EstaActivo = 1)
        BEGIN
            SET @message = 'Categoría de compra no existe / inactiva.';
            RAISERROR(@message, 16, 1);
        END

        /* Validaciones base */
        IF (ISNULL(@Descripcion,'') = '')
        BEGIN
            SET @message = 'Descripción no puede ser vacía.';
            RAISERROR(@message, 16, 1);
        END

        /* Si es inventario: requerimos InventarioId, Cantidad, CostoUnitario */
        IF (@EsInventario = 1)
        BEGIN
            IF (@InventarioId IS NULL OR @InventarioId = 0)
            BEGIN
                SET @message = 'InventarioId es requerido para compras de inventario.';
                RAISERROR(@message, 16, 1);
            END
            IF NOT EXISTS (SELECT 1 FROM dbo.TblInventarios WITH (NOLOCK) WHERE InventarioId = @InventarioId AND EstaActivo = 1)
            BEGIN
                SET @message = 'Inventario no existe / inactivo.';
                RAISERROR(@message, 16, 1);
            END
            IF (@Cantidad <= 0)
            BEGIN
                SET @message = 'Cantidad debe ser mayor a 0.';
                RAISERROR(@message, 16, 1);
            END
            IF (@CostoUnitario <= 0)
            BEGIN
                SET @message = 'CostoUnitario debe ser mayor a 0.';
                RAISERROR(@message, 16, 1);
            END

            SET @CostoTotal = (@Cantidad * @CostoUnitario);
        END
        ELSE
        BEGIN
            SET @InventarioId = NULL;
            SET @Cantidad = 0;
            SET @CostoUnitario = 0;

            IF (@CostoTotal <= 0)
            BEGIN
                SET @message = 'CostoTotal debe ser mayor a 0.';
                RAISERROR(@message, 16, 1);
            END
        END

        /* ============================
           UPDATE
           ============================ */
        IF (ISNULL(@Actualizar,0) = 1)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.TblCompras WITH (NOLOCK) WHERE CompraId = @ElementoAlterarId)
            BEGIN
                SET @message = 'Registro no encontrado para actualizar.';
                RAISERROR(@message, 16, 1);
            END

            SELECT
                @PrevInventarioId = c.InventarioId,
                @PrevCantidad     = c.Cantidad,
                @PrevCostoTotal   = c.CostoTotal,
                @PrevEsInventario = ct.EsInventario
            FROM dbo.TblCompras c WITH (NOLOCK)
            INNER JOIN dbo.TblComprasTipos ct WITH (NOLOCK) ON c.CompraTipoId = ct.CompraTipoId
            WHERE c.CompraId = @ElementoAlterarId;

            /* Reversa previa si era inventario */
            IF (@PrevEsInventario = 1 AND @PrevInventarioId IS NOT NULL)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblInventarios i WITH (NOLOCK)
                    WHERE i.InventarioId = @PrevInventarioId
                      AND i.EstaActivo = 1
                      AND (i.Cantidad - @PrevCantidad) < 0
                )
                BEGIN
                    SET @message = 'No se puede actualizar: la reversa previa dejaría inventario en negativo.';
                    RAISERROR(@message, 16, 1);
                END

                -- ✅ snapshot reversa
                SELECT @InvAntes = CAST(i.Cantidad AS DECIMAL(18,4))
                FROM dbo.TblInventarios i WITH (UPDLOCK, ROWLOCK)
                WHERE i.InventarioId = @PrevInventarioId;

                SET @InvDespues = @InvAntes - CAST(@PrevCantidad AS DECIMAL(18,4));

                UPDATE dbo.TblInventarios
                    SET Cantidad = Cantidad - @PrevCantidad
                WHERE InventarioId = @PrevInventarioId;

                INSERT INTO dbo.TblInventariosMovimientos
                    (InventarioId, TipoMovimientoId, Cantidad, Costo, FechaCreacion, UsuarioId, CompraId, DisponibleAntes, DisponibleDespues)
                VALUES
                    (@PrevInventarioId, @TipoMov_AJUSTE, -@PrevCantidad, -@PrevCostoTotal, GETUTCDATE(), @loginId,
                     @ElementoAlterarId, @InvAntes, @InvDespues);
            END

            /* Aplica nuevo efecto si ahora es inventario */
            IF (@EsInventario = 1 AND @InventarioId IS NOT NULL)
            BEGIN
                -- ✅ snapshot apply
                SELECT @InvAntes = CAST(i.Cantidad AS DECIMAL(18,4))
                FROM dbo.TblInventarios i WITH (UPDLOCK, ROWLOCK)
                WHERE i.InventarioId = @InventarioId;

                SET @InvDespues = @InvAntes + CAST(@Cantidad AS DECIMAL(18,4));

                UPDATE dbo.TblInventarios
                    SET Cantidad = Cantidad + @Cantidad,
                        CostoUnitario = CASE
                            WHEN (Cantidad + @Cantidad) <= 0 THEN @CostoUnitario
                            ELSE (
                                (Cantidad * CostoUnitario) + (@Cantidad * @CostoUnitario)
                            ) / NULLIF((Cantidad + @Cantidad),0)
                        END
                WHERE InventarioId = @InventarioId;

                INSERT INTO dbo.TblInventariosMovimientos
                    (InventarioId, TipoMovimientoId, Cantidad, Costo, FechaCreacion, UsuarioId, CompraId, DisponibleAntes, DisponibleDespues)
                VALUES
                    (@InventarioId, @TipoMov_AJUSTE, @Cantidad, @CostoTotal, GETUTCDATE(), @loginId,
                     @ElementoAlterarId, @InvAntes, @InvDespues);
            END

            UPDATE dbo.TblCompras
                SET Descripcion = @Descripcion,
                    CompraTipoId = @CompraTipoId,
                    FilamentoTipoId = NULL,
                    CompraCategoriaId = @CompraCategoriaId,
                    InventarioId = @InventarioId,
                    Cantidad = @Cantidad,
                    CostoUnitario = @CostoUnitario,
                    CostoTotal = @CostoTotal,
                    FechaCreacion = @FechaCreacion,
                    EstaActivo = 1,
                    UsuarioId = ISNULL(UsuarioId, @loginId)
            WHERE CompraId = @ElementoAlterarId;

            COMMIT TRAN;

            SET @result = 'success';
            SET @message = 'Compra actualizada.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* ============================
           CREATE
           ============================ */
        INSERT INTO dbo.TblCompras(
            Descripcion, CompraTipoId, FilamentoTipoId, CompraCategoriaId,
            InventarioId, Cantidad, CostoUnitario, CostoTotal,
            FechaCreacion, EstaActivo, UsuarioId
        )
        VALUES(
            @Descripcion, @CompraTipoId, NULL, @CompraCategoriaId,
            @InventarioId, @Cantidad, @CostoUnitario, @CostoTotal,
            @FechaCreacion, 1, @loginId
        );

        SET @elementoId = SCOPE_IDENTITY();

        IF (@EsInventario = 1 AND @InventarioId IS NOT NULL)
        BEGIN
            -- ✅ snapshot create
            SELECT @InvAntes = CAST(i.Cantidad AS DECIMAL(18,4))
            FROM dbo.TblInventarios i WITH (UPDLOCK, ROWLOCK)
            WHERE i.InventarioId = @InventarioId;

            SET @InvDespues = @InvAntes + CAST(@Cantidad AS DECIMAL(18,4));

            UPDATE dbo.TblInventarios
                SET Cantidad = Cantidad + @Cantidad,
                    CostoUnitario = CASE
                        WHEN (Cantidad + @Cantidad) <= 0 THEN @CostoUnitario
                        ELSE (
                            (Cantidad * CostoUnitario) + (@Cantidad * @CostoUnitario)
                        ) / NULLIF((Cantidad + @Cantidad),0)
                    END
            WHERE InventarioId = @InventarioId;

            INSERT INTO dbo.TblInventariosMovimientos
                (InventarioId, TipoMovimientoId, Cantidad, Costo, FechaCreacion, UsuarioId, CompraId, DisponibleAntes, DisponibleDespues)
            VALUES
                (@InventarioId, @TipoMov_COMPRA, @Cantidad, @CostoTotal, GETUTCDATE(), @loginId,
                 @elementoId, @InvAntes, @InvDespues);
        END

        COMMIT TRAN;

        SET @result = 'success';
        SET @message = 'Compra creada.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRAN;

        SET @result = 'fail';
        IF (ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;
    END CATCH
END
GO


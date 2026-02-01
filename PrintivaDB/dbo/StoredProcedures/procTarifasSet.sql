

/* =========================================================
   4) SP: UPSERT TARIFA ACTIVA + LOG (SIN VIGENCIAS)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasSet
    @TarifaConceptoCodigo VARCHAR(40),
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @ImpresoraId INT = NULL,
    @InventarioTipoId INT = NULL,
    @InventarioNombreId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @TarifaConceptoId INT;

        SELECT @TarifaConceptoId = TarifaConceptoId
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

        IF @TarifaConceptoId IS NULL
        BEGIN
            SELECT 'error' AS result, 'Concepto de tarifa inválido o inactivo.' AS message;
            RETURN;
        END

        DECLARE @chg TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioTipoId INT NULL,
            InventarioNombreId INT NULL,

            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,

            EstaActivoAntes BIT NULL,
            EstaActivoDespues BIT NULL
        );

        /* Intento UPDATE (si existe el registro “vivo” para ese scope) */
        UPDATE t
        SET
            Monto = @Monto,
            Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN'),
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioTipoId,
            inserted.InventarioNombreId,
            deleted.Monto,
            deleted.Moneda,
            inserted.Monto,
            inserted.Moneda,
            deleted.EstaActivo,
            inserted.EstaActivo
        INTO @chg
        FROM dbo.TblTarifas t
        WHERE
            t.UsuarioId = @loginId
            AND t.TarifaConceptoId = @TarifaConceptoId
            AND t.EstaActivo = 1
            AND ISNULL(t.ImpresoraId, 0) = ISNULL(@ImpresoraId, 0)
            AND ISNULL(t.InventarioTipoId, 0) = ISNULL(@InventarioTipoId, 0)
            AND ISNULL(t.InventarioNombreId, 0) = ISNULL(@InventarioNombreId, 0);

        IF EXISTS (SELECT 1 FROM @chg)
        BEGIN
            INSERT dbo.TblTarifasLog(
                TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
                Accion, MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
            )
            SELECT
                TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
                'UPDATE', MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
            FROM @chg;

            SELECT 'success' AS result, 'Tarifa actualizada.' AS message;
            RETURN;
        END

        /* Si no existe, INSERT (crea el registro vivo) */
        DECLARE @ins TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioTipoId INT NULL,
            InventarioNombreId INT NULL,
            Monto DECIMAL(18,4),
            Moneda CHAR(3),
            EstaActivo BIT
        );

        INSERT dbo.TblTarifas(
            UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioTipoId, InventarioNombreId,
            Monto, Moneda, EstaActivo
        )
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioTipoId,
            inserted.InventarioNombreId,
            inserted.Monto,
            inserted.Moneda,
            inserted.EstaActivo
        INTO @ins
        VALUES(
            @loginId, @TarifaConceptoId,
            @ImpresoraId, @InventarioTipoId, @InventarioNombreId,
            @Monto, ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN'),
            1
        );

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            Accion, MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            'INSERT', NULL, NULL, Monto, Moneda, NULL, EstaActivo
        FROM @ins;

        SELECT 'success' AS result, 'Tarifa actualizada.' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


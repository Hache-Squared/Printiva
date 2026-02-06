CREATE   PROCEDURE dbo.procTarifasSet
    @TarifaConceptoCodigo VARCHAR(40),
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @Nombre NVARCHAR(80) = N'',
    @Orden INT = 100,
    @ImpresoraId INT = NULL,
    @InventarioId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TarifaConceptoId INT;
    DECLARE @TarifaId INT;

    BEGIN TRY
        SET @TarifaConceptoCodigo = UPPER(LTRIM(RTRIM(ISNULL(@TarifaConceptoCodigo,''))));
        SET @Moneda = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN'));
        SET @Nombre = ISNULL(@Nombre, N'');
        SET @Orden  = ISNULL(@Orden, 100);

        IF (@TarifaConceptoCodigo = '')
            RAISERROR('Concepto de tarifa inválido (vacío).',16,1);

        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SELECT @TarifaConceptoId = TarifaConceptoId
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

        IF @TarifaConceptoId IS NULL
            RAISERROR('Concepto de tarifa inválido o inactivo.',16,1);

        IF (@InventarioId IS NOT NULL AND @ImpresoraId IS NOT NULL)
            RAISERROR('Scope inválido: no se permite ImpresoraId e InventarioId a la vez.',16,1);

        IF (@TarifaConceptoCodigo = 'MATERIAL_UNIT' AND @InventarioId IS NULL)
            RAISERROR('MATERIAL_UNIT requiere InventarioId.',16,1);

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL')
        BEGIN
            IF (@InventarioId IS NULL AND @ImpresoraId IS NULL)
                RAISERROR('MATERIAL_GENERAL requiere InventarioId o ImpresoraId (uno).',16,1);
        END

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL_INV_GLOBAL')
        BEGIN
            SET @InventarioId = NULL;
            SET @ImpresoraId = NULL;
        END

        IF (@TarifaConceptoCodigo = 'MATERIAL_GENERAL_PRN_GLOBAL')
        BEGIN
            SET @InventarioId = NULL;
            SET @ImpresoraId = NULL;
        END

        INSERT dbo.TblTarifas(
            UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            InventarioTipoId, InventarioNombreId,
            Nombre, Orden,
            Monto, Moneda,
            EstaActivo
        )
        VALUES(
            @loginId, @TarifaConceptoId,
            @ImpresoraId, @InventarioId,
            NULL, NULL,
            @Nombre, @Orden,
            @Monto, @Moneda,
            1
        );

        SET @TarifaId = SCOPE_IDENTITY();

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            InventarioTipoId, InventarioNombreId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        VALUES(
            @TarifaId, @loginId, @TarifaConceptoId,
            @ImpresoraId, @InventarioId,
            NULL, NULL,
            'INSERT',
            NULL, @Nombre,
            NULL, @Orden,
            NULL, NULL,
            @Monto, @Moneda,
            NULL, 1
        );

        SELECT 'success' AS result, 'Tarifa creada.' AS message, @TarifaId AS TarifaId;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message, NULL AS TarifaId;
    END CATCH
END
GO


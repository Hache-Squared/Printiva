/* =========================================================
   TARIFAS — PAQUETE COMPLETO (SIN VIGENCIAS) (ACTUALIZADO)
   - TblTarifas       = estado actual
   - TblTarifasLog    = histórico de cambios
   - FIX: índice único con NULLs (usa columnas computadas *_Key)
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================================================
   0) CATÁLOGO DE CONCEPTOS
   ========================================================= */
IF OBJECT_ID('dbo.TblTarifaConceptos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TblTarifaConceptos(
        TarifaConceptoId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblTarifaConceptos PRIMARY KEY,
        Codigo               VARCHAR(40)   NOT NULL,
        Nombre               NVARCHAR(120) NOT NULL,
        Unidad               NVARCHAR(30)  NOT NULL,  -- hora, gr, %
        Orden                INT           NOT NULL CONSTRAINT DF_TblTarifaConceptos_Orden DEFAULT(100),
        EstaActivo           BIT           NOT NULL CONSTRAINT DF_TblTarifaConceptos_EstaActivo DEFAULT(1),
        FechaCreacion        DATETIME2(0)  NOT NULL CONSTRAINT DF_TblTarifaConceptos_FechaCreacion DEFAULT(SYSDATETIME()),
        FechaActualizacion   DATETIME2(0)  NULL
    );
END
GO

/* “Auto-migración” si ya existía y le faltan columnas */
IF COL_LENGTH('dbo.TblTarifaConceptos', 'Orden') IS NULL
    ALTER TABLE dbo.TblTarifaConceptos ADD Orden INT NOT NULL CONSTRAINT DF_TblTarifaConceptos_Orden DEFAULT(100);

IF COL_LENGTH('dbo.TblTarifaConceptos', 'EstaActivo') IS NULL
    ALTER TABLE dbo.TblTarifaConceptos ADD EstaActivo BIT NOT NULL CONSTRAINT DF_TblTarifaConceptos_EstaActivo DEFAULT(1);

IF COL_LENGTH('dbo.TblTarifaConceptos', 'FechaCreacion') IS NULL
    ALTER TABLE dbo.TblTarifaConceptos ADD FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TblTarifaConceptos_FechaCreacion DEFAULT(SYSDATETIME());

IF COL_LENGTH('dbo.TblTarifaConceptos', 'FechaActualizacion') IS NULL
    ALTER TABLE dbo.TblTarifaConceptos ADD FechaActualizacion DATETIME2(0) NULL;
GO

/* Índice único por Código (crea si no existe) */
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_TblTarifaConceptos_Codigo'
      AND object_id = OBJECT_ID('dbo.TblTarifaConceptos')
)
BEGIN
    CREATE UNIQUE INDEX UX_TblTarifaConceptos_Codigo
        ON dbo.TblTarifaConceptos(Codigo);
END
GO

/* Seed mínimo (idempotente) */
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'PRINT_HOUR')
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('PRINT_HOUR',  N'Costo por hora de impresión', N'hora', 10);

IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'POST_HOUR')
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('POST_HOUR',   N'Costo por hora de post-proceso', N'hora', 20);

IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'MATERIAL_GR')
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('MATERIAL_GR', N'Costo de material por gramo', N'gr', 30);

IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'MARGIN_PCT')
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('MARGIN_PCT',  N'Margen (%)', N'%', 40);
GO


/* =========================================================
   1) TABLA DE TARIFAS (ESTADO ACTUAL)
   ========================================================= */
IF OBJECT_ID('dbo.TblTarifas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TblTarifas(
        TarifaId            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblTarifas PRIMARY KEY,
        UsuarioId           INT NOT NULL,
        TarifaConceptoId    INT NOT NULL,

        -- Alcance opcional (overrides)
        ImpresoraId         INT NULL,
        InventarioTipoId    INT NULL,
        InventarioNombreId  INT NULL,

        Monto               DECIMAL(18,4) NOT NULL,
        Moneda              CHAR(3) NOT NULL CONSTRAINT DF_TblTarifas_Moneda DEFAULT('MXN'),

        EstaActivo          BIT NOT NULL CONSTRAINT DF_TblTarifas_EstaActivo DEFAULT(1),
        FechaCreacion       DATETIME2(0) NOT NULL CONSTRAINT DF_TblTarifas_FechaCreacion DEFAULT(SYSDATETIME()),
        FechaActualizacion  DATETIME2(0) NULL,

        CONSTRAINT FK_TblTarifas_TarifaConceptos
            FOREIGN KEY (TarifaConceptoId) REFERENCES dbo.TblTarifaConceptos(TarifaConceptoId)
    );
END
GO

/* “Auto-migración” columnas faltantes */
IF COL_LENGTH('dbo.TblTarifas', 'Moneda') IS NULL
    ALTER TABLE dbo.TblTarifas ADD Moneda CHAR(3) NOT NULL CONSTRAINT DF_TblTarifas_Moneda DEFAULT('MXN');

IF COL_LENGTH('dbo.TblTarifas', 'EstaActivo') IS NULL
    ALTER TABLE dbo.TblTarifas ADD EstaActivo BIT NOT NULL CONSTRAINT DF_TblTarifas_EstaActivo DEFAULT(1);

IF COL_LENGTH('dbo.TblTarifas', 'FechaCreacion') IS NULL
    ALTER TABLE dbo.TblTarifas ADD FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_TblTarifas_FechaCreacion DEFAULT(SYSDATETIME());

IF COL_LENGTH('dbo.TblTarifas', 'FechaActualizacion') IS NULL
    ALTER TABLE dbo.TblTarifas ADD FechaActualizacion DATETIME2(0) NULL;
GO

/* FIX IMPORTANTE:
   Para evitar duplicados “globales” (NULLs), creamos llaves computadas. */
IF COL_LENGTH('dbo.TblTarifas', 'ImpresoraIdKey') IS NULL
    ALTER TABLE dbo.TblTarifas ADD ImpresoraIdKey AS ISNULL(ImpresoraId, 0) PERSISTED;

IF COL_LENGTH('dbo.TblTarifas', 'InventarioTipoIdKey') IS NULL
    ALTER TABLE dbo.TblTarifas ADD InventarioTipoIdKey AS ISNULL(InventarioTipoId, 0) PERSISTED;

IF COL_LENGTH('dbo.TblTarifas', 'InventarioNombreIdKey') IS NULL
    ALTER TABLE dbo.TblTarifas ADD InventarioNombreIdKey AS ISNULL(InventarioNombreId, 0) PERSISTED;
GO

/* Re-crear índice único correcto (si existe el viejo, lo tumbamos) */
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_TblTarifas_Activo_Scope'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
BEGIN
    DROP INDEX UX_TblTarifas_Activo_Scope ON dbo.TblTarifas;
END
GO

CREATE UNIQUE INDEX UX_TblTarifas_Activo_Scope
ON dbo.TblTarifas(UsuarioId, TarifaConceptoId, ImpresoraIdKey, InventarioTipoIdKey, InventarioNombreIdKey)
WHERE EstaActivo = 1;
GO

/* (Opcional) índice para lecturas */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_TblTarifas_Usuario_Concepto'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
BEGIN
    CREATE INDEX IX_TblTarifas_Usuario_Concepto
    ON dbo.TblTarifas(UsuarioId, TarifaConceptoId, EstaActivo)
    INCLUDE (Monto, Moneda, ImpresoraId, InventarioTipoId, InventarioNombreId, FechaCreacion, FechaActualizacion);
END
GO


/* =========================================================
   1B) LOG / HISTÓRICO DE TARIFAS
   ========================================================= */
IF OBJECT_ID('dbo.TblTarifasLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TblTarifasLog(
        TarifaLogId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TblTarifasLog PRIMARY KEY,

        TarifaId            INT NOT NULL,
        UsuarioId           INT NOT NULL,
        TarifaConceptoId    INT NOT NULL,
        ImpresoraId         INT NULL,
        InventarioTipoId    INT NULL,
        InventarioNombreId  INT NULL,

        Accion              VARCHAR(20) NOT NULL, -- INSERT | UPDATE | DELETE_LOGICO

        MontoAntes          DECIMAL(18,4) NULL,
        MonedaAntes         CHAR(3) NULL,
        MontoDespues        DECIMAL(18,4) NULL,
        MonedaDespues       CHAR(3) NULL,

        EstaActivoAntes     BIT NULL,
        EstaActivoDespues   BIT NULL,

        FechaAccion         DATETIME2(0) NOT NULL CONSTRAINT DF_TblTarifasLog_FechaAccion DEFAULT(SYSDATETIME())
    );
END
GO

/* Índices del log (crea si faltan) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_TblTarifasLog_TarifaId_Fecha'
      AND object_id = OBJECT_ID('dbo.TblTarifasLog')
)
BEGIN
    CREATE INDEX IX_TblTarifasLog_TarifaId_Fecha
        ON dbo.TblTarifasLog(TarifaId, FechaAccion DESC);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_TblTarifasLog_Usuario_Fecha'
      AND object_id = OBJECT_ID('dbo.TblTarifasLog')
)
BEGIN
    CREATE INDEX IX_TblTarifasLog_Usuario_Fecha
        ON dbo.TblTarifasLog(UsuarioId, FechaAccion DESC);
END
GO


/* =========================================================
   2) SP: LISTAR CONCEPTOS
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerConceptos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TarifaConceptoId, Codigo, Nombre, Unidad, Orden
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE EstaActivo = 1
    ORDER BY Orden ASC, Nombre ASC;
END
GO


/* =========================================================
   3) SP: LISTAR TARIFAS ACTIVAS DEL USUARIO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorUsuario
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,
        t.ImpresoraId,
        t.InventarioTipoId,
        t.InventarioNombreId,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
    ORDER BY c.Orden ASC, c.Nombre ASC, t.TarifaId DESC;
END
GO


/* =========================================================
   4) SP: UPSERT TARIFA ACTIVA + LOG (SIN VIGENCIAS)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasSet
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


/* =========================================================
   5) SP: OBTENER TARIFA (PRIORIDAD POR ESPECIFICIDAD)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtener
    @TarifaConceptoCodigo VARCHAR(40),
    @ImpresoraId INT = NULL,
    @InventarioTipoId INT = NULL,
    @InventarioNombreId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TarifaConceptoId INT;

    SELECT @TarifaConceptoId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

    IF @TarifaConceptoId IS NULL
    BEGIN
        SELECT NULL AS TarifaId, NULL AS Monto, NULL AS Moneda,
               'error' AS result, 'Concepto de tarifa inválido o inactivo.' AS message;
        RETURN;
    END

    SELECT TOP(1)
        t.TarifaId, t.Monto, t.Moneda,
        'success' AS result, 'OK' AS message
    FROM dbo.TblTarifas t WITH (NOLOCK)
    WHERE t.UsuarioId = @loginId
      AND t.TarifaConceptoId = @TarifaConceptoId
      AND t.EstaActivo = 1
      AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
      AND (t.InventarioTipoId IS NULL OR t.InventarioTipoId = @InventarioTipoId)
      AND (t.InventarioNombreId IS NULL OR t.InventarioNombreId = @InventarioNombreId)
    ORDER BY
      CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
      CASE WHEN t.InventarioNombreId = @InventarioNombreId THEN 2 WHEN t.InventarioNombreId IS NULL THEN 1 ELSE 0 END DESC,
      CASE WHEN t.InventarioTipoId = @InventarioTipoId THEN 2 WHEN t.InventarioTipoId IS NULL THEN 1 ELSE 0 END DESC,
      t.TarifaId DESC;
END
GO


/* =========================================================
   6) SP: ELIMINACIÓN LÓGICA + LOG
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasEliminar
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @del TABLE(
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

        UPDATE t
        SET EstaActivo = 0,
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
        INTO @del
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.UsuarioId = @loginId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @del)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa o no pertenece al usuario.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            Accion, MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId, ImpresoraId, InventarioTipoId, InventarioNombreId,
            'DELETE_LOGICO', MontoAntes, MonedaAntes, MontoDespues, MonedaDespues, EstaActivoAntes, EstaActivoDespues
        FROM @del;

        SELECT 'success' AS result, 'Tarifa eliminada (lógica).' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO


/* =========================================================
   7) SP: HISTÓRICO POR TARIFA
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP(100)
        l.TarifaLogId,
        l.Accion,
        l.MontoAntes, l.MonedaAntes,
        l.MontoDespues, l.MonedaDespues,
        l.EstaActivoAntes, l.EstaActivoDespues,
        l.FechaAccion
    FROM dbo.TblTarifasLog l WITH (NOLOCK)
    WHERE l.TarifaId = @TarifaId
      AND l.UsuarioId = @loginId
    ORDER BY l.FechaAccion DESC, l.TarifaLogId DESC;
END
GO


/* =========================================================
   8) SP: DIAGNÓSTICO (SIN VIGENCIAS)
      - Solo devuelve conceptos que NO tienen tarifa global (sin scope)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasDiagnostico
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH conceptos AS (
        SELECT TarifaConceptoId, Codigo, Nombre
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE EstaActivo = 1
    ),
    existentes_global AS (
        SELECT TarifaConceptoId
        FROM dbo.TblTarifas WITH (NOLOCK)
        WHERE UsuarioId = @loginId
          AND EstaActivo = 1
          AND ImpresoraId IS NULL
          AND InventarioTipoId IS NULL
          AND InventarioNombreId IS NULL
    )
    SELECT
        c.Codigo,
        c.Nombre,
        CASE WHEN eg.TarifaConceptoId IS NULL THEN 1 ELSE 0 END AS FaltaTarifaGlobal
    FROM conceptos c
    LEFT JOIN existentes_global eg
        ON eg.TarifaConceptoId = c.TarifaConceptoId
    WHERE eg.TarifaConceptoId IS NULL
    ORDER BY c.Codigo;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'MATERIAL_UNIT')
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('MATERIAL_UNIT', N'Costo de material por unidad', N'unidad', 31);


/* 1) QUITAR EL ÍNDICE ÚNICO (estorba para acumular tarifas) */
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_TblTarifas_Activo_Scope'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
    DROP INDEX UX_TblTarifas_Activo_Scope ON dbo.TblTarifas;
GO

/* 2) columnas para poder tener "varias tarifas" y mostrarlas bonito */
IF COL_LENGTH('dbo.TblTarifas','Nombre') IS NULL
    ALTER TABLE dbo.TblTarifas ADD Nombre NVARCHAR(80) NOT NULL
        CONSTRAINT DF_TblTarifas_Nombre DEFAULT(N'');

IF COL_LENGTH('dbo.TblTarifas','Orden') IS NULL
    ALTER TABLE dbo.TblTarifas ADD Orden INT NOT NULL
        CONSTRAINT DF_TblTarifas_Orden DEFAULT(100);

/* 3) (Opcional pero útil) Scope directo por InventarioId (lo usas en recetas: TblRecetasInventarios usa InventarioId) */
IF COL_LENGTH('dbo.TblTarifas','InventarioId') IS NULL
    ALTER TABLE dbo.TblTarifas ADD InventarioId INT NULL;
GO

/* 4) índice NO-único para lecturas rápidas */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_TblTarifas_Lookup'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
BEGIN
    CREATE INDEX IX_TblTarifas_Lookup
    ON dbo.TblTarifas(UsuarioId, TarifaConceptoId, EstaActivo, ImpresoraId, InventarioId)
    INCLUDE (Monto, Moneda, Nombre, Orden, FechaCreacion, FechaActualizacion);
END
GO


/* =========================================================
   TARIFAS (ACUMULABLES) — POR InventarioId / ImpresoraId
   - Mantiene TblTarifaConceptos
   - TblTarifas: permite múltiples filas por scope
   - TblTarifasLog: guarda histórico
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================================================
   0) ASEGURAR CONCEPTO MATERIAL_UNIT
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo = 'MATERIAL_UNIT')
BEGIN
    INSERT dbo.TblTarifaConceptos(Codigo, Nombre, Unidad, Orden)
    VALUES ('MATERIAL_UNIT', N'Costo de material por unidad', N'unidad', 31);
END
GO

/* =========================================================
   1) MIGRACIÓN MÍNIMA: TblTarifas (InventarioId + Nombre + Orden)
   ========================================================= */
IF COL_LENGTH('dbo.TblTarifas', 'InventarioId') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifas ADD InventarioId INT NULL;
END
GO

IF COL_LENGTH('dbo.TblTarifas', 'Nombre') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifas
    ADD Nombre NVARCHAR(80) NOT NULL
        CONSTRAINT DF_TblTarifas_Nombre DEFAULT(N'');
END
GO

IF COL_LENGTH('dbo.TblTarifas', 'Orden') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifas
    ADD Orden INT NOT NULL
        CONSTRAINT DF_TblTarifas_Orden DEFAULT(100);
END
GO

/* =========================================================
   2) QUITAR ÍNDICE ÚNICO QUE IMPIDE ACUMULAR
   ========================================================= */
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_TblTarifas_Activo_Scope'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
BEGIN
    DROP INDEX UX_TblTarifas_Activo_Scope ON dbo.TblTarifas;
END
GO

/* Índice NO-único para lectura rápida */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_TblTarifas_Lookup'
      AND object_id = OBJECT_ID('dbo.TblTarifas')
)
BEGIN
    CREATE INDEX IX_TblTarifas_Lookup
    ON dbo.TblTarifas(UsuarioId, TarifaConceptoId, EstaActivo, ImpresoraId, InventarioId)
    INCLUDE (Monto, Moneda, Nombre, Orden, FechaCreacion, FechaActualizacion);
END
GO

/* =========================================================
   3) MIGRACIÓN MÍNIMA: TblTarifasLog (InventarioId + Nombre/Orden antes/después)
   ========================================================= */
IF COL_LENGTH('dbo.TblTarifasLog', 'InventarioId') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifasLog ADD InventarioId INT NULL;
END
GO

IF COL_LENGTH('dbo.TblTarifasLog', 'NombreAntes') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifasLog ADD NombreAntes NVARCHAR(80) NULL;
END
GO

IF COL_LENGTH('dbo.TblTarifasLog', 'NombreDespues') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifasLog ADD NombreDespues NVARCHAR(80) NULL;
END
GO

IF COL_LENGTH('dbo.TblTarifasLog', 'OrdenAntes') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifasLog ADD OrdenAntes INT NULL;
END
GO

IF COL_LENGTH('dbo.TblTarifasLog', 'OrdenDespues') IS NULL
BEGIN
    ALTER TABLE dbo.TblTarifasLog ADD OrdenDespues INT NULL;
END
GO

/* =========================================================
   4) SP: LISTAR CONCEPTOS (igual que tenías)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerConceptos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TarifaConceptoId, Codigo, Nombre, Unidad, Orden
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE EstaActivo = 1
    ORDER BY Orden ASC, Nombre ASC;
END
GO

/* =========================================================
   5) SP: LISTAR TARIFAS ACTIVAS DEL USUARIO (ya incluye InventarioId + Nombre + Orden)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorUsuario
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,

        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,

        t.ImpresoraId,
        t.InventarioId,

        /* legacy (por si existen en la tabla; no los usamos para UI nueva) */
        t.InventarioTipoId,
        t.InventarioNombreId,

        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
    ORDER BY
        c.Orden ASC,
        t.ImpresoraId ASC,
        t.InventarioId ASC,
        t.Orden ASC,
        t.TarifaId DESC;
END
GO

/* =========================================================
   6) SP: OBTENER TARIFAS POR INVENTARIO (UI sección Inventario)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorInventario
    @InventarioId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,
        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,
        t.InventarioId,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
      AND t.InventarioId = @InventarioId
    ORDER BY c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO

/* =========================================================
   7) SP: OBTENER TARIFAS POR IMPRESORA (UI sección Impresoras)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerPorImpresora
    @ImpresoraId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,
        c.Codigo AS ConceptoCodigo,
        c.Nombre AS ConceptoNombre,
        c.Unidad,
        t.ImpresoraId,
        t.Monto,
        t.Moneda,
        COALESCE(t.FechaActualizacion, t.FechaCreacion) AS FechaUltimoCambio
    FROM dbo.TblTarifas t WITH (NOLOCK)
    INNER JOIN dbo.TblTarifaConceptos c WITH (NOLOCK)
        ON c.TarifaConceptoId = t.TarifaConceptoId
    WHERE t.UsuarioId = @loginId
      AND t.EstaActivo = 1
      AND t.ImpresoraId = @ImpresoraId
    ORDER BY c.Orden ASC, t.Orden ASC, t.TarifaId DESC;
END
GO

/* =========================================================
   8) SP: CREAR TARIFA (ANTES era UPSERT, ahora ES INSERT SIEMPRE)
   - nombre/orden para listar bonito
   - scope: ImpresoraId o InventarioId o global (ambos NULL)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasSet
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
        SELECT @TarifaConceptoId = TarifaConceptoId
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

        IF @TarifaConceptoId IS NULL
            RAISERROR('Concepto de tarifa inválido o inactivo.',16,1);

        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SET @Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN');
        SET @Nombre = ISNULL(@Nombre, N'');
        SET @Orden  = ISNULL(@Orden, 100);

        INSERT dbo.TblTarifas(
            UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            /* legacy */
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
            /* legacy */
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

/* =========================================================
   9) SP: ACTUALIZAR TARIFA (por TarifaId)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasActualizar
    @TarifaId INT,
    @Monto DECIMAL(18,4),
    @Moneda CHAR(3) = 'MXN',
    @Nombre NVARCHAR(80) = NULL,
    @Orden INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Monto IS NULL OR @Monto < 0
            RAISERROR('Monto inválido (debe ser >= 0).',16,1);

        SET @Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'MXN');

        DECLARE @chg TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            OrdenDespues INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET
            Monto = @Monto,
            Moneda = @Moneda,
            Nombre = COALESCE(@Nombre, t.Nombre),
            Orden  = COALESCE(@Orden, t.Orden),
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            inserted.Nombre,
            deleted.Orden,
            inserted.Orden,
            deleted.Monto,
            deleted.Moneda,
            inserted.Monto,
            inserted.Moneda,
            deleted.EstaActivo,
            inserted.EstaActivo
        INTO @chg
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.UsuarioId = @loginId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @chg)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa o no pertenece al usuario.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            'UPDATE',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @chg;

        SELECT 'success' AS result, 'Tarifa actualizada.' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO

/* =========================================================
   10) SP: ELIMINACIÓN LÓGICA + LOG (corregida para InventarioId + Nombre/Orden)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasEliminar
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @del TABLE(
            TarifaId INT,
            UsuarioId INT,
            TarifaConceptoId INT,
            ImpresoraId INT NULL,
            InventarioId INT NULL,
            NombreAntes NVARCHAR(80) NULL,
            OrdenAntes INT NULL,
            MontoAntes DECIMAL(18,4) NULL,
            MonedaAntes CHAR(3) NULL,
            EstaActivoAntes BIT NULL,
            NombreDespues NVARCHAR(80) NULL,
            OrdenDespues INT NULL,
            MontoDespues DECIMAL(18,4) NULL,
            MonedaDespues CHAR(3) NULL,
            EstaActivoDespues BIT NULL
        );

        UPDATE t
        SET EstaActivo = 0,
            FechaActualizacion = SYSDATETIME()
        OUTPUT
            inserted.TarifaId,
            inserted.UsuarioId,
            inserted.TarifaConceptoId,
            inserted.ImpresoraId,
            inserted.InventarioId,
            deleted.Nombre,
            deleted.Orden,
            deleted.Monto,
            deleted.Moneda,
            deleted.EstaActivo,
            inserted.Nombre,
            inserted.Orden,
            inserted.Monto,
            inserted.Moneda,
            inserted.EstaActivo
        INTO @del
        FROM dbo.TblTarifas t
        WHERE t.TarifaId = @TarifaId
          AND t.UsuarioId = @loginId
          AND t.EstaActivo = 1;

        IF NOT EXISTS (SELECT 1 FROM @del)
        BEGIN
            SELECT 'error' AS result, 'No se encontró la tarifa o no pertenece al usuario.' AS message;
            RETURN;
        END

        INSERT dbo.TblTarifasLog(
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            Accion,
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        )
        SELECT
            TarifaId, UsuarioId, TarifaConceptoId,
            ImpresoraId, InventarioId,
            'DELETE_LOGICO',
            NombreAntes, NombreDespues,
            OrdenAntes, OrdenDespues,
            MontoAntes, MonedaAntes,
            MontoDespues, MonedaDespues,
            EstaActivoAntes, EstaActivoDespues
        FROM @del;

        SELECT 'success' AS result, 'Tarifa eliminada (lógica).' AS message;
    END TRY
    BEGIN CATCH
        SELECT 'error' AS result, CONCAT('Error: ', ERROR_MESSAGE()) AS message;
    END CATCH
END
GO

/* =========================================================
   11) SP: HISTÓRICO POR TARIFA (ya muestra inventario/nombre/orden)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
    @TarifaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP(200)
        l.TarifaLogId,
        l.Accion,

        l.ImpresoraId,
        l.InventarioId,

        l.NombreAntes, l.NombreDespues,
        l.OrdenAntes,  l.OrdenDespues,

        l.MontoAntes, l.MonedaAntes,
        l.MontoDespues, l.MonedaDespues,

        l.EstaActivoAntes, l.EstaActivoDespues,
        l.FechaAccion
    FROM dbo.TblTarifasLog l WITH (NOLOCK)
    WHERE l.TarifaId = @TarifaId
      AND l.UsuarioId = @loginId
    ORDER BY l.FechaAccion DESC, l.TarifaLogId DESC;
END
GO

/* =========================================================
   12) SP: DIAGNÓSTICO (global = sin impresora y sin inventario)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasDiagnostico
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH conceptos AS (
        SELECT TarifaConceptoId, Codigo, Nombre
        FROM dbo.TblTarifaConceptos WITH (NOLOCK)
        WHERE EstaActivo = 1
    ),
    existentes_global AS (
        SELECT TarifaConceptoId
        FROM dbo.TblTarifas WITH (NOLOCK)
        WHERE UsuarioId = @loginId
          AND EstaActivo = 1
          AND ImpresoraId IS NULL
          AND InventarioId IS NULL
    )
    SELECT
        c.Codigo,
        c.Nombre,
        CASE WHEN eg.TarifaConceptoId IS NULL THEN 1 ELSE 0 END AS FaltaTarifaGlobal
    FROM conceptos c
    LEFT JOIN existentes_global eg
        ON eg.TarifaConceptoId = c.TarifaConceptoId
    WHERE eg.TarifaConceptoId IS NULL
    ORDER BY c.Codigo;
END
GO

/* =========================================================
   13) SP: OBTENER TARIFAS APLICABLES (para cálculo + desglose)
   - Regresa TODAS las tarifas activas que aplican al scope pedido
   - Si mandas InventarioId, traerá:
        (InventarioId exacto) + (globales InventarioId NULL)
     Si mandas ImpresoraId, traerá:
        (ImpresoraId exacto) + (globales ImpresoraId NULL)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.procTarifasObtenerAplicables
    @TarifaConceptoCodigo VARCHAR(40),
    @ImpresoraId INT = NULL,
    @InventarioId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TarifaConceptoId INT;

    SELECT @TarifaConceptoId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = @TarifaConceptoCodigo AND EstaActivo = 1;

    IF @TarifaConceptoId IS NULL
    BEGIN
        SELECT 'error' AS result, 'Concepto de tarifa inválido o inactivo.' AS message;
        RETURN;
    END

    SELECT
        'success' AS result,
        'OK' AS message,
        t.TarifaId,
        t.Nombre AS TarifaNombre,
        t.Orden  AS TarifaOrden,
        t.ImpresoraId,
        t.InventarioId,
        t.Monto,
        t.Moneda
    FROM dbo.TblTarifas t WITH (NOLOCK)
    WHERE t.UsuarioId = @loginId
      AND t.TarifaConceptoId = @TarifaConceptoId
      AND t.EstaActivo = 1
      AND (
            /* si viene inventario, aplica inventario específico + global */
            (@InventarioId IS NOT NULL AND (t.InventarioId = @InventarioId OR t.InventarioId IS NULL) AND t.ImpresoraId IS NULL)
            OR
            /* si viene impresora, aplica impresora específica + global */
            (@ImpresoraId IS NOT NULL AND (t.ImpresoraId = @ImpresoraId OR t.ImpresoraId IS NULL) AND t.InventarioId IS NULL)
            OR
            /* si no viene scope, solo global puro */
            (@InventarioId IS NULL AND @ImpresoraId IS NULL AND t.InventarioId IS NULL AND t.ImpresoraId IS NULL)
      )
    ORDER BY
        /* primero específicos, luego globales */
        CASE WHEN @InventarioId IS NOT NULL AND t.InventarioId = @InventarioId THEN 2
             WHEN @ImpresoraId IS NOT NULL AND t.ImpresoraId = @ImpresoraId THEN 2
             ELSE 1 END DESC,
        t.Orden ASC,
        t.TarifaId DESC;
END
GO


BEGIN TRAN;

-- 1) Agrega concepto general (flat)
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo='MATERIAL_GENERAL')
BEGIN
    INSERT INTO dbo.TblTarifaConceptos (Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
    VALUES ('MATERIAL_GENERAL', 'Cargo fijo (general)', 'flat', 32, 1, SYSDATETIME());
END

-- 2) Opcional: renombra el display de MATERIAL_UNIT (código se queda igual)
UPDATE dbo.TblTarifaConceptos
SET Nombre = 'Costo de material por unidad de inventario',
    Unidad = 'unidad inv.',
    FechaActualizacion = SYSDATETIME()
WHERE Codigo='MATERIAL_UNIT';

-- 3) Desactiva MATERIAL_GR para que ya no salga en UI
UPDATE dbo.TblTarifaConceptos
SET EstaActivo = 0,
    FechaActualizacion = SYSDATETIME()
WHERE Codigo='MATERIAL_GR';

COMMIT;





BEGIN TRAN;

-- A) MATERIAL_GENERAL (scoped: inventario o impresora)
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo='MATERIAL_GENERAL')
BEGIN
    INSERT INTO dbo.TblTarifaConceptos (Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
    VALUES ('MATERIAL_GENERAL', N'Cargo fijo (por inventario/impresora)', 'flat', 32, 1, SYSDATETIME());
END
ELSE
BEGIN
    UPDATE dbo.TblTarifaConceptos
    SET Nombre = N'Cargo fijo (por inventario/impresora)',
        Unidad = 'flat',
        Orden = 32,
        EstaActivo = 1,
        FechaActualizacion = SYSDATETIME()
    WHERE Codigo='MATERIAL_GENERAL';
END

-- B) Global solo inventarios
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo='MATERIAL_GENERAL_INV_GLOBAL')
BEGIN
    INSERT INTO dbo.TblTarifaConceptos (Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
    VALUES ('MATERIAL_GENERAL_INV_GLOBAL', N'Cargo fijo global (inventarios)', 'flat', 33, 1, SYSDATETIME());
END

-- C) Global solo impresoras
IF NOT EXISTS (SELECT 1 FROM dbo.TblTarifaConceptos WHERE Codigo='MATERIAL_GENERAL_PRN_GLOBAL')
BEGIN
    INSERT INTO dbo.TblTarifaConceptos (Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
    VALUES ('MATERIAL_GENERAL_PRN_GLOBAL', N'Cargo fijo global (impresoras)', 'flat', 34, 1, SYSDATETIME());
END

-- (Opcional) deja MATERIAL_UNIT como lo traías
UPDATE dbo.TblTarifaConceptos
SET Nombre = N'Costo de material por unidad de inventario',
    Unidad = 'unidad inv.',
    FechaActualizacion = SYSDATETIME()
WHERE Codigo='MATERIAL_UNIT';

-- (Opcional) apaga MATERIAL_GR
UPDATE dbo.TblTarifaConceptos
SET EstaActivo = 0,
    FechaActualizacion = SYSDATETIME()
WHERE Codigo='MATERIAL_GR';

COMMIT;
GO
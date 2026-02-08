/* Auto_catalogs
   Inicializacion de catalogos (insert o update por Id fijo)
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    ------------------------------------------------------------------------------
    -- Catalogo de tabla: dbo.TblComprasCategorias
    -- Columnas: CompraCategoriaId, Nombre, EstaActivo
    ------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.TblComprasCategorias', 'U') IS NOT NULL
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblComprasCategorias'), 'CompraCategoriaId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblComprasCategorias ON;

        MERGE dbo.TblComprasCategorias WITH (HOLDLOCK) AS tgt
        USING (VALUES
            (1, N'Consumible',        CAST(0 AS bit)),
            (2, N'Activo',            CAST(1 AS bit)),
            (3, N'Gasto operativo',   CAST(1 AS bit)),
            (4, N'Pago de servicios', CAST(0 AS bit))
        ) AS src (CompraCategoriaId, Nombre, EstaActivo)
        ON tgt.CompraCategoriaId = src.CompraCategoriaId
        WHEN MATCHED AND (
               ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
            OR ISNULL(tgt.EstaActivo, 0) <> ISNULL(src.EstaActivo, 0)
        )
        THEN UPDATE SET
            Nombre = src.Nombre,
            EstaActivo = src.EstaActivo
        WHEN NOT MATCHED THEN
            INSERT (CompraCategoriaId, Nombre, EstaActivo)
            VALUES (src.CompraCategoriaId, src.Nombre, src.EstaActivo);

        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblComprasCategorias'), 'CompraCategoriaId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblComprasCategorias OFF;
    END;

    ------------------------------------------------------------------------------
    -- Catalogo de tabla: dbo.TblComprasTipos
    -- Columnas: CompraTipoId, Nombre, EstaActivo, EsInventario, RequiereFilamentoTipo
    ------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.TblComprasTipos', 'U') IS NOT NULL
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblComprasTipos'), 'CompraTipoId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblComprasTipos ON;

        MERGE dbo.TblComprasTipos WITH (HOLDLOCK) AS tgt
        USING (VALUES
            (1, N'Filamento',     CAST(1 AS bit), CAST(1 AS bit), CAST(0 AS bit)),
            (2, N'Herramienta',   CAST(0 AS bit), CAST(0 AS bit), CAST(0 AS bit)),
            (3, N'Mantenimiento', CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit)),
            (5, N'Servicios',     CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit)),
            (6, N'Gasto fijo',    CAST(1 AS bit), CAST(0 AS bit), CAST(0 AS bit)),
            (7, N'Inventariado',  CAST(0 AS bit), CAST(1 AS bit), CAST(0 AS bit))
        ) AS src (CompraTipoId, Nombre, EstaActivo, EsInventario, RequiereFilamentoTipo)
        ON tgt.CompraTipoId = src.CompraTipoId
        WHEN MATCHED AND (
               ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
            OR ISNULL(tgt.EstaActivo, 0) <> ISNULL(src.EstaActivo, 0)
            OR ISNULL(tgt.EsInventario, 0) <> ISNULL(src.EsInventario, 0)
            OR ISNULL(tgt.RequiereFilamentoTipo, 0) <> ISNULL(src.RequiereFilamentoTipo, 0)
        )
        THEN UPDATE SET
            Nombre = src.Nombre,
            EstaActivo = src.EstaActivo,
            EsInventario = src.EsInventario,
            RequiereFilamentoTipo = src.RequiereFilamentoTipo
        WHEN NOT MATCHED THEN
            INSERT (CompraTipoId, Nombre, EstaActivo, EsInventario, RequiereFilamentoTipo)
            VALUES (src.CompraTipoId, src.Nombre, src.EstaActivo, src.EsInventario, src.RequiereFilamentoTipo);

        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblComprasTipos'), 'CompraTipoId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblComprasTipos OFF;
    END;

    ------------------------------------------------------------------------------
    -- Catalogo de tabla: dbo.TblCotizacionConceptoTipos
    -- Columnas: ConceptoTipoId, Nombre
    ------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.TblCotizacionConceptoTipos', 'U') IS NOT NULL
    BEGIN
        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblCotizacionConceptoTipos'), 'ConceptoTipoId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblCotizacionConceptoTipos ON;

        MERGE dbo.TblCotizacionConceptoTipos WITH (HOLDLOCK) AS tgt
        USING (VALUES
            (1, N'Modelado'),
            (2, N'Produccion')
        ) AS src (ConceptoTipoId, Nombre)
        ON tgt.ConceptoTipoId = src.ConceptoTipoId
        WHEN MATCHED AND (
            ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
        )
        THEN UPDATE SET
            Nombre = src.Nombre
        WHEN NOT MATCHED THEN
            INSERT (ConceptoTipoId, Nombre)
            VALUES (src.ConceptoTipoId, src.Nombre);

        IF COLUMNPROPERTY(OBJECT_ID('dbo.TblCotizacionConceptoTipos'), 'ConceptoTipoId', 'IsIdentity') = 1
            SET IDENTITY_INSERT dbo.TblCotizacionConceptoTipos OFF;
    END;


	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblCotizacionesEstatus
	-- Columnas: CotizacionEstatusId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblCotizacionesEstatus', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblCotizacionesEstatus'), 'CotizacionEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblCotizacionesEstatus ON;

		MERGE dbo.TblCotizacionesEstatus WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Borrador'),
			(2, N'Enviada'),
			(3, N'Aceptada'),
			(4, N'Rechazada'),
			(5, N'Cancelada')
		) AS src (CotizacionEstatusId, Nombre)
		ON tgt.CotizacionEstatusId = src.CotizacionEstatusId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
		)
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (CotizacionEstatusId, Nombre)
			VALUES (src.CotizacionEstatusId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblCotizacionesEstatus'), 'CotizacionEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblCotizacionesEstatus OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblFilamentosTipos
	-- Columnas: FilamentoTipoId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblFilamentosTipos', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblFilamentosTipos'), 'FilamentoTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblFilamentosTipos ON;

		MERGE dbo.TblFilamentosTipos WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'PLA'),
			(2, N'ABS'),
			(3, N'PETG')
		) AS src (FilamentoTipoId, Nombre)
		ON tgt.FilamentoTipoId = src.FilamentoTipoId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
		)
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (FilamentoTipoId, Nombre)
			VALUES (src.FilamentoTipoId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblFilamentosTipos'), 'FilamentoTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblFilamentosTipos OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblInventariosMovimientoTipos
	-- Columnas: TipoMovimientoId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblInventariosMovimientoTipos', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosMovimientoTipos'), 'TipoMovimientoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosMovimientoTipos ON;

		MERGE dbo.TblInventariosMovimientoTipos WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Compra'),
			(2, N'Venta'),
			(3, N'Consumo'),
			(4, N'AJUSTE_COMPRA'),
			(5, N'REVERSA_COMPRA')
		) AS src (TipoMovimientoId, Nombre)
		ON tgt.TipoMovimientoId = src.TipoMovimientoId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
		)
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (TipoMovimientoId, Nombre)
			VALUES (src.TipoMovimientoId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosMovimientoTipos'), 'TipoMovimientoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosMovimientoTipos OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblInventariosTipos
	-- Columnas: InventarioTipoId, Nombre, EstaActivo
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblInventariosTipos', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosTipos'), 'InventarioTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosTipos ON;

		MERGE dbo.TblInventariosTipos WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1,    N'Rollo de filamento',      CAST(1 AS bit)),
			(2002, N'Conjunto de partes',      CAST(1 AS bit)),
			(2003, N'Cadena para colgantes',   CAST(1 AS bit))
		) AS src (InventarioTipoId, Nombre, EstaActivo)
		ON tgt.InventarioTipoId = src.InventarioTipoId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
			OR ISNULL(tgt.EstaActivo, 0) <> ISNULL(src.EstaActivo, 0)
		)
		THEN UPDATE SET
			Nombre = src.Nombre,
			EstaActivo = src.EstaActivo
		WHEN NOT MATCHED THEN
			INSERT (InventarioTipoId, Nombre, EstaActivo)
			VALUES (src.InventarioTipoId, src.Nombre, src.EstaActivo);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosTipos'), 'InventarioTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosTipos OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblInventariosUnidades
	-- Columnas: InventarioUnidadId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblInventariosUnidades', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosUnidades'), 'InventarioUnidadId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosUnidades ON;

		MERGE dbo.TblInventariosUnidades WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Unidad'),
			(2, N'Gramos')
		) AS src (InventarioUnidadId, Nombre)
		ON tgt.InventarioUnidadId = src.InventarioUnidadId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
		)
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (InventarioUnidadId, Nombre)
			VALUES (src.InventarioUnidadId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblInventariosUnidades'), 'InventarioUnidadId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblInventariosUnidades OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblPagoTipos
	-- Columnas: PagoTipoId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblPagoTipos', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPagoTipos'), 'PagoTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPagoTipos ON;

		MERGE dbo.TblPagoTipos WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Modelado'),
			(2, N'Produccion'),
			(3, N'General')
		) AS src (PagoTipoId, Nombre)
		ON tgt.PagoTipoId = src.PagoTipoId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
		)
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (PagoTipoId, Nombre)
			VALUES (src.PagoTipoId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPagoTipos'), 'PagoTipoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPagoTipos OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblPedidoEstatus
	-- Columnas: PedidoEstatusId, Nombre
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblPedidoEstatus', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPedidoEstatus'), 'PedidoEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPedidoEstatus ON;

		MERGE dbo.TblPedidoEstatus WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Nuevo'),
			(2, N'En modelado'),
			(3, N'Modelado listo'),
			(4, N'Aprobado'),
			(5, N'En produccion'),
			(6, N'Post-proceso'),
			(7, N'Listo para entrega'),
			(8, N'Entregado'),
			(9, N'Cancelado')
		) AS src (PedidoEstatusId, Nombre)
		ON tgt.PedidoEstatusId = src.PedidoEstatusId
		WHEN MATCHED AND (ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N''))
		THEN UPDATE SET
			Nombre = src.Nombre
		WHEN NOT MATCHED THEN
			INSERT (PedidoEstatusId, Nombre)
			VALUES (src.PedidoEstatusId, src.Nombre);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPedidoEstatus'), 'PedidoEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPedidoEstatus OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblPedidosEstatusTransiciones
	-- Columnas: PedidoEstatusTransicionId, DesdeEstatusId, HaciaEstatusId
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblPedidosEstatusTransiciones', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPedidosEstatusTransiciones'), 'PedidoEstatusTransicionId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPedidosEstatusTransiciones ON;

		MERGE dbo.TblPedidosEstatusTransiciones WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1,  1, 2),
			(8,  1, 9),

			(2,  2, 3),
			(9,  2, 9),

			(3,  3, 4),
			(10, 3, 9),

			(4,  4, 5),
			(11, 4, 9),

			(5,  5, 6),
			(12, 5, 9),

			(6,  6, 7),
			(13, 6, 9),

			(7,  7, 8),
			(14, 7, 9)
		) AS src (PedidoEstatusTransicionId, DesdeEstatusId, HaciaEstatusId)
		ON tgt.PedidoEstatusTransicionId = src.PedidoEstatusTransicionId
		WHEN MATCHED AND (
			ISNULL(tgt.DesdeEstatusId, 0) <> ISNULL(src.DesdeEstatusId, 0)
			OR ISNULL(tgt.HaciaEstatusId, 0) <> ISNULL(src.HaciaEstatusId, 0)
		)
		THEN UPDATE SET
			DesdeEstatusId = src.DesdeEstatusId,
			HaciaEstatusId = src.HaciaEstatusId
		WHEN NOT MATCHED THEN
			INSERT (PedidoEstatusTransicionId, DesdeEstatusId, HaciaEstatusId)
			VALUES (src.PedidoEstatusTransicionId, src.DesdeEstatusId, src.HaciaEstatusId);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblPedidosEstatusTransiciones'), 'PedidoEstatusTransicionId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblPedidosEstatusTransiciones OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblProduccionEstatus
	-- Columnas: ProduccionEstatusId, Nombre, Orden, BadgeClass, EstaActivo
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblProduccionEstatus', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblProduccionEstatus'), 'ProduccionEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblProduccionEstatus ON;

		MERGE dbo.TblProduccionEstatus WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'En producción',      1, N'bg-primary',           CAST(1 AS bit)),
			(2, N'Post-proceso',       2, N'bg-warning text-dark', CAST(1 AS bit)),
			(3, N'Listo para entrega', 3, N'bg-info text-dark',    CAST(1 AS bit)),
			(4, N'Entregado',          4, N'bg-success',           CAST(1 AS bit))
		) AS src (ProduccionEstatusId, Nombre, Orden, BadgeClass, EstaActivo)
		ON tgt.ProduccionEstatusId = src.ProduccionEstatusId
		WHEN MATCHED AND (
			ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
			OR ISNULL(tgt.Orden, -1) <> ISNULL(src.Orden, -1)
			OR ISNULL(tgt.BadgeClass, N'') <> ISNULL(src.BadgeClass, N'')
			OR ISNULL(tgt.EstaActivo, 0) <> ISNULL(src.EstaActivo, 0)
		)
		THEN UPDATE SET
			Nombre = src.Nombre,
			Orden = src.Orden,
			BadgeClass = src.BadgeClass,
			EstaActivo = src.EstaActivo
		WHEN NOT MATCHED THEN
			INSERT (ProduccionEstatusId, Nombre, Orden, BadgeClass, EstaActivo)
			VALUES (src.ProduccionEstatusId, src.Nombre, src.Orden, src.BadgeClass, src.EstaActivo);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblProduccionEstatus'), 'ProduccionEstatusId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblProduccionEstatus OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblProduccionEstatusTransiciones
	-- Columnas: DesdeEstatusId, HaciaEstatusId
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblProduccionEstatusTransiciones', 'U') IS NOT NULL
	BEGIN
		MERGE dbo.TblProduccionEstatusTransiciones WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, 2),
			(2, 3),
			(3, 4)
		) AS src (DesdeEstatusId, HaciaEstatusId)
		ON  tgt.DesdeEstatusId = src.DesdeEstatusId
		AND tgt.HaciaEstatusId = src.HaciaEstatusId
		WHEN NOT MATCHED THEN
			INSERT (DesdeEstatusId, HaciaEstatusId)
			VALUES (src.DesdeEstatusId, src.HaciaEstatusId);
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TblTarifaConceptos
	-- Columnas: TarifaConceptoId, Codigo, Nombre, Unidad, Orden, EstaActivo
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TblTarifaConceptos', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblTarifaConceptos'), 'TarifaConceptoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblTarifaConceptos ON;

		MERGE dbo.TblTarifaConceptos WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'PRINT_HOUR',                  N'Costo por hora de impresión',                 N'hora',        10, CAST(0 AS bit),GETDATE()),
			(2, N'POST_HOUR',                   N'Costo por hora de post-proceso',              N'hora',        20, CAST(0 AS bit),GETDATE()),
			(3, N'MATERIAL_GR',                 N'Costo de material por gramo',                 N'gr',          30, CAST(0 AS bit),GETDATE()),
			(4, N'MARGIN_PCT',                  N'Margen (%)',                                  N'%',           40, CAST(0 AS bit),GETDATE()),
			(5, N'MATERIAL_UNIT',               N'Costo de material por unidad de inventario',  N'unidad inv.', 31, CAST(1 AS bit),GETDATE()),
			(6, N'MATERIAL_GENERAL',            N'Cargo fijo (por inventario/impresora)',       N'flat',        32, CAST(1 AS bit),GETDATE()),
			(7, N'MATERIAL_GENERAL_INV_GLOBAL', N'Cargo fijo global (inventarios)',             N'flat',        33, CAST(1 AS bit),GETDATE()),
			(8, N'MATERIAL_GENERAL_PRN_GLOBAL', N'Cargo fijo global (impresoras)',              N'flat',        34, CAST(1 AS bit),GETDATE())
		) AS src (TarifaConceptoId, Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
		ON tgt.TarifaConceptoId = src.TarifaConceptoId
		WHEN MATCHED AND (
			ISNULL(tgt.Codigo, N'') <> ISNULL(src.Codigo, N'')
			OR ISNULL(tgt.Nombre, N'') <> ISNULL(src.Nombre, N'')
			OR ISNULL(tgt.Unidad, N'') <> ISNULL(src.Unidad, N'')
			OR ISNULL(tgt.Orden, -1) <> ISNULL(src.Orden, -1)
			OR ISNULL(tgt.EstaActivo, 0) <> ISNULL(src.EstaActivo, 0)
		)
		THEN UPDATE SET
			Codigo = src.Codigo,
			Nombre = src.Nombre,
			Unidad = src.Unidad,
			Orden = src.Orden,
			EstaActivo = src.EstaActivo,
			FechaCreacion = src.FechaCreacion
		WHEN NOT MATCHED THEN
			INSERT (TarifaConceptoId, Codigo, Nombre, Unidad, Orden, EstaActivo, FechaCreacion)
			VALUES (src.TarifaConceptoId, src.Codigo, src.Nombre, src.Unidad, src.Orden, src.EstaActivo,src.FechaCreacion);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TblTarifaConceptos'), 'TarifaConceptoId', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TblTarifaConceptos OFF;
	END;

	------------------------------------------------------------------------------
	-- Catalogo de tabla: dbo.TiposOperaciones
	-- Columnas: Id, Descripcion
	------------------------------------------------------------------------------
	IF OBJECT_ID('dbo.TiposOperaciones', 'U') IS NOT NULL
	BEGIN
		IF COLUMNPROPERTY(OBJECT_ID('dbo.TiposOperaciones'), 'Id', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TiposOperaciones ON;

		MERGE dbo.TiposOperaciones WITH (HOLDLOCK) AS tgt
		USING (VALUES
			(1, N'Ingreso'),
			(2, N'Gasto')
		) AS src (Id, Descripcion)
		ON tgt.Id = src.Id
		WHEN MATCHED AND (ISNULL(tgt.Descripcion, N'') <> ISNULL(src.Descripcion, N''))
		THEN UPDATE SET
			Descripcion = src.Descripcion
		WHEN NOT MATCHED THEN
			INSERT (Id, Descripcion)
			VALUES (src.Id, src.Descripcion);

		IF COLUMNPROPERTY(OBJECT_ID('dbo.TiposOperaciones'), 'Id', 'IsIdentity') = 1
			SET IDENTITY_INSERT dbo.TiposOperaciones OFF;
	END;


    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
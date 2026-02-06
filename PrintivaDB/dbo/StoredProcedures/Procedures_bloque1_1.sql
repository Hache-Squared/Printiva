-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[CrearDatosUsuarioNuevo]
	@UsuarioId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	DECLARE @Efectivo nvarchar(50) = 'Efectivo';
	DECLARE @CuentasDeBanco nvarchar(50) = 'Cuentas de Banco';
	DECLARE @Tarjetas nvarchar(50) = 'Tarjetas';

END
GO

CREATE OR ALTER PROCEDURE dbo.procActualizarPedido
    @loginId INT,
    @pedidoId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TblPedidos
    SET ClienteId = @clienteId,
        PedidoEstatusId = @pedidoEstatusId,
        FechaEntregaEstimada = @fechaEntregaEstimada,
        Notas = @notas,
        TotalEstimado = @totalEstimado
    WHERE PedidoId = @pedidoId;
END
GO


/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Description: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Description     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE OR ALTER PROCEDURE dbo.procActualizarRegistrosInventarios
@ElementoAlterarId	 INT = 0,
@InventarioMarcaId	 INT = 0,
@InventarioTipoId	 INT = 0,
@InventarioColorId	 INT = 0,
@Cantidad			 DECIMAL(10,2) = 0,
@InventarioUnidadId	 INT = 0,
@InventarioNombreId	 INT = 0,
@loginId			 INT = 0,
@Actualizar			 BIT = 0,
@Borrar				 BIT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoAlterarId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.TblInventarios i (NOLOCK)
			WHERE i.InventarioId = @ElementoAlterarId
		)
		BEGIN
			SET @message = 'Inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		IF(
			ISNULL(@Actualizar, 0) = 1
		)
		BEGIN
			
			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosMarcas im (NOLOCK)
				WHERE im.InventarioMarcaId = @InventarioMarcaId
			)
			BEGIN 
				SET @message = 'Marca no encontrada.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosTipos im (NOLOCK)
				WHERE im.InventarioTipoId = @InventarioTipoId
			)
			BEGIN 
				SET @message = 'Tipo de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosColores ic (NOLOCK)
				WHERE ic.InventarioColorId = @InventarioColorId
			)
			BEGIN 
				SET @message = 'Color de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosUnidades ic (NOLOCK)
				WHERE ic.InventarioUnidadId = @InventarioUnidadId
			)
			BEGIN 
				SET @message = 'Unidad de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF NOT EXISTS (
				SELECT 1
				FROM dbo.TblInventariosNombres ic (NOLOCK)
				WHERE ic.InventarioNombreId = @InventarioNombreId
			)
			BEGIN 
				SET @message = 'Nombre de inventario no encontrado.';
				RAISERROR(@message, 16, 1);
			END

			IF(ISNULL(@Cantidad, 0) = 0)
			BEGIN 
				SET @message = 'Cantidad debe tener un valor.';
				RAISERROR(@message, 16, 1);
			END
	
			IF(ISNUMERIC(@Cantidad) = 0)
			BEGIN 
				SET @message = 'Cantidad no es un numero.';
				RAISERROR(@message, 16, 1);
			END

			IF(@Cantidad < 0)
			BEGIN 
				SET @message = 'Cantidad debe ser positivo.';
				RAISERROR(@message, 16, 1);
			END

			UPDATE tgt
				SET tgt.InventarioMarcaId = @InventarioMarcaId,
					tgt.InventarioTipoId = @InventarioTipoId,
					tgt.InventarioUnidadId = @InventarioUnidadId,
					tgt.InventarioColorId = @InventarioColorId,
					tgt.InventarioNombreId = @InventarioNombreId,
					tgt.Cantidad = @Cantidad
			FROM dbo.TblInventarios tgt
			WHERE tgt.InventarioId = @ElementoAlterarId

			SET @message = 'Elemento Actualizado';
		END

		IF(
			ISNULL(@Borrar, 0) = 1
		)
		BEGIN 
			UPDATE tgt
				SET tgt.EstaActivo = 0
			FROM dbo.TblInventarios tgt
			WHERE tgt.InventarioId = @ElementoAlterarId

			SET @message = 'Elemento Eliminado';
		END

		SET @result = 'success';
		SET @message = IIF(@message = '','Ningun error', @message);


		SELECT @result [result],
			   @message [message],
			   @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN 
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		
		SELECT @result [result],
			   @message [message],
			   @elementoId [elementoId];
	END CATCH
END
GO
/*
===============================================================================
Author: AGHH (adaptado para Clientes)
Date: 17/11/2025
Description: Alteración de clientes (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 17/11/2025 First Version N/A
*/

CREATE OR ALTER PROCEDURE dbo.procAlteraClientes
    @ElementoAlterarId INT = 0,

    @Nombre NVARCHAR(150) = NULL,
    @Telefono NVARCHAR(30) = NULL,
    @Instagram NVARCHAR(80) = NULL,
    @WhatsApp NVARCHAR(30) = NULL,
    @Email NVARCHAR(120) = NULL,
    @Direccion NVARCHAR(250) = NULL,

    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0,
    @Reactivar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'fail';
    DECLARE @message NVARCHAR(MAX) = N'';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId, 0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = N'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        /* -----------------------------
           BORRAR LOGICO
           ----------------------------- */
        IF (ISNULL(@Borrar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
            )
            BEGIN
                SET @message = N'Registro no encontrado para borrar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET EstaActivo = 0,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId;

            SET @result = 'success';
            SET @message = N'Cliente desactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           REACTIVAR
           ----------------------------- */
        IF (ISNULL(@Reactivar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
            )
            BEGIN
                SET @message = N'Registro no encontrado para reactivar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET EstaActivo = 1,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId;

            SET @result = 'success';
            SET @message = N'Cliente reactivado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           VALIDACIONES BASE (create/update)
           ----------------------------- */
        IF (ISNULL(@Nombre, N'') = N'')
        BEGIN
            SET @message = N'Nombre no puede ser vacío.';
            RAISERROR(@message, 16, 1);
        END

        /* -----------------------------
           UPDATE
           ----------------------------- */
        IF (ISNULL(@Actualizar,0) = 1)
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblClientes c (NOLOCK)
                WHERE c.ClienteId = @ElementoAlterarId
            )
            BEGIN
                SET @message = N'Registro no encontrado para actualizar.';
                RAISERROR(@message, 16, 1);
            END

            UPDATE dbo.TblClientes
            SET Nombre = @Nombre,
                Telefono = @Telefono,
                Instagram = @Instagram,
                WhatsApp = @WhatsApp,
                Email = @Email,
                Direccion = @Direccion,
                FechaActualizacion = SYSUTCDATETIME()
            WHERE ClienteId = @ElementoAlterarId;

            SET @result = 'success';
            SET @message = N'Cliente actualizado.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        /* -----------------------------
           CREATE
           ----------------------------- */
        INSERT INTO dbo.TblClientes
        (
            UsuarioId, Nombre, Telefono, Instagram, WhatsApp, Email, Direccion,
            FechaCreacion, EstaActivo, FechaActualizacion
        )
        VALUES
        (
            @loginId, @Nombre, @Telefono, @Instagram, @WhatsApp, @Email, @Direccion,
            SYSUTCDATETIME(), 1, NULL
        );

        SET @elementoId = CAST(SCOPE_IDENTITY() AS INT);

        SET @result = 'success';
        SET @message = N'Cliente creado.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;

    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, N'') = N'')
            SET @message = CONCAT(ERROR_MESSAGE(), N'. Error Line: *', ERROR_LINE(), N'*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
        RETURN;
    END CATCH
END    
GO

CREATE OR ALTER PROCEDURE dbo.procAlteraComprasCategoriasV2
        @ElementoAlterarId INT = 0,
        @Nombre VARCHAR(200) = '',
        @loginId INT = 0,
        @Actualizar BIT = 0,
        @Borrar BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @result VARCHAR(50) = '';
        DECLARE @message VARCHAR(MAX) = '';
        DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

        BEGIN TRY
            IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            BEGIN
                SET @message = 'Usuario no encontrado.';
                RAISERROR(@message, 16, 1);
            END

            IF (ISNULL(@Nombre,'') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END

            IF (ISNULL(@Borrar,0) = 1)
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK) WHERE CompraCategoriaId=@ElementoAlterarId)
                BEGIN
                    SET @message='Categoría no encontrada.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE dbo.TblComprasCategorias
                    SET EstaActivo=0
                WHERE CompraCategoriaId=@ElementoAlterarId;

                SET @result='success'; SET @message='Categoría eliminada (lógica).';
                SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
                RETURN;
            END

            IF (ISNULL(@Actualizar,0) = 1)
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK) WHERE CompraCategoriaId=@ElementoAlterarId)
                BEGIN
                    SET @message='Categoría no encontrada.';
                    RAISERROR(@message, 16, 1);
                END

                IF EXISTS(
                    SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK)
                    WHERE Nombre=@Nombre AND CompraCategoriaId<>@ElementoAlterarId AND EstaActivo=1
                )
                BEGIN
                    SET @message='Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE dbo.TblComprasCategorias
                    SET Nombre=@Nombre,
                        EstaActivo=1
                WHERE CompraCategoriaId=@ElementoAlterarId;

                SET @result='success'; SET @message='Categoría actualizada.';
                SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
                RETURN;
            END

            /* CREATE */
            IF EXISTS(
                SELECT 1 FROM dbo.TblComprasCategorias (NOLOCK)
                WHERE Nombre=@Nombre AND EstaActivo=1
            )
            BEGIN
                SET @message='Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasCategorias(Nombre, EstaActivo)
            VALUES(@Nombre, 1);

            SET @elementoId = SCOPE_IDENTITY();

            SET @result='success'; SET @message='Categoría creada.';
            SELECT @result [result], @message [message], @elementoId [elementoId];

        END TRY
        BEGIN CATCH
            SET @result='fail';
            IF (ISNULL(@message,'') = '')
                SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
            SELECT @result [result], @message [message], @elementoId [elementoId];
        END CATCH
    END
GO


-- ====== SP V2 (sin filamento, borrado lógico) ======
CREATE OR ALTER PROCEDURE dbo.procAlteraComprasTiposV2
    @ElementoAlterarId INT = 0,
    @Nombre VARCHAR(200) = '',
    @EsInventario BIT = 0,
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoAlterarId, 0);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u WITH (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        -- Si es borrado, NO exijas nombre
        IF (ISNULL(@Borrar, 0) = 0)
        BEGIN
            IF (ISNULL(@Nombre, '') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF EXISTS (
            SELECT 1
            FROM dbo.TblComprasTipos ct WITH (NOLOCK)
            WHERE ct.CompraTipoId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblComprasTipos ct WITH (NOLOCK)
                    WHERE ct.Nombre = @Nombre
                      AND ct.CompraTipoId != @ElementoAlterarId
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                SET tgt.Nombre = @Nombre,
                    tgt.EsInventario = @EsInventario
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                -- Borrado lógico
                UPDATE tgt
                SET tgt.EstaActivo = 0
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Desactivado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM dbo.TblComprasTipos ct WITH (NOLOCK)
                WHERE ct.Nombre = @Nombre
            )
            BEGIN
                SET @message = 'Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasTipos (Nombre, EsInventario, EstaActivo)
            VALUES (@Nombre, @EsInventario, 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SET @result = 'success';
        SET @message = IIF(@message = '', 'Ningún error', @message);

        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, '') = '')
        BEGIN
            SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        END
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procAlteraComprasV2
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

    -- NUEVO: snapshots
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

                -- snapshot ANTES/DESPUÉS con lock
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

                -- snapshot reversa
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
                -- snapshot apply
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
            -- snapshot create
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

CREATE OR ALTER PROCEDURE dbo.procAlteraCotizacion
@ElementoAlterarId INT = 0,
@PedidoId INT = 0,
@CotizacionEstatusId INT = 1,
@FechaVigencia DATETIME = NULL,
@Notas VARCHAR(MAX) = NULL,
@loginId INT = 0,
@Actualizar BIT = 0,
@Borrar BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result VARCHAR(20) = 'success';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
		BEGIN
			RAISERROR('Usuario no encontrado.',16,1);
		END

		IF(ISNULL(@Borrar,0) = 1)
		BEGIN
			IF NOT EXISTS(
				SELECT 1
				FROM dbo.TblCotizaciones c (NOLOCK)
				WHERE c.CotizacionId = @elementoId AND ISNULL(c.EstaActivo,1) = 1
			)
			BEGIN
				RAISERROR('Cotizacion no encontrada.',16,1);
			END

			BEGIN TRAN;

			IF OBJECT_ID('dbo.TblCotizacionItems','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionItems','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionItems','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblCotizacionItems
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			IF OBJECT_ID('dbo.TblCotizacionesItems','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionesItems','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblCotizacionesItems','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblCotizacionItems
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			IF OBJECT_ID('dbo.TblPagos','U') IS NOT NULL
			   AND COL_LENGTH('dbo.TblPagos','EstaActivo') IS NOT NULL
			   AND COL_LENGTH('dbo.TblPagos','CotizacionId') IS NOT NULL
			BEGIN
				UPDATE dbo.TblPagos
				SET EstaActivo = 0
				WHERE CotizacionId = @elementoId AND ISNULL(EstaActivo,1) = 1;
			END

			UPDATE dbo.TblCotizaciones
			SET EstaActivo = 0
			WHERE CotizacionId = @elementoId;

			COMMIT;

			SET @message = 'Elemento Eliminado';
			SELECT @result [result], @message [message], @elementoId [elementoId];
			RETURN;
		END

		IF(ISNULL(@PedidoId,0) = 0)
		BEGIN
			RAISERROR('PedidoId no puede ser 0.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId)
		BEGIN
			RAISERROR('Pedido no existe.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizacionesEstatus e (NOLOCK) WHERE e.CotizacionEstatusId = @CotizacionEstatusId)
		BEGIN
			RAISERROR('Estatus de cotizacion no existe.',16,1);
		END

		IF EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @elementoId)
		BEGIN
			IF(ISNULL(@Actualizar,0) = 1)
			BEGIN
				UPDATE dbo.TblCotizaciones
				SET PedidoId = @PedidoId,
					CotizacionEstatusId = @CotizacionEstatusId,
					FechaVigencia = @FechaVigencia,
					Notas = @Notas
				WHERE CotizacionId = @elementoId;

				SET @message = 'Elemento Actualizado';
			END
			ELSE
			BEGIN
				SET @message = 'Sin cambios';
			END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TblCotizaciones(
				PedidoId, CotizacionEstatusId, FechaCreacion, FechaVigencia, Notas, EstaActivo
			)
			VALUES(
				@PedidoId, @CotizacionEstatusId, GETDATE(), @FechaVigencia, @Notas, 1
			);

			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SELECT @result [result], @message [message], @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		IF(XACT_STATE() <> 0) ROLLBACK;
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
	END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procAlteraCotizacionItemsRelacion
@loginId INT = 0,
@CotizacionId INT = 0,
@Json VARCHAR(MAX) = '[]'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result VARCHAR(20) = 'success';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = ISNULL(@CotizacionId,0);

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
		BEGIN
			RAISERROR('Usuario no encontrado.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
		BEGIN
			RAISERROR('Cotizacion no encontrada.',16,1);
		END

		SET @Json = ISNULL(@Json,'[]');

		IF(ISJSON(@Json) = 0)
		BEGIN
			RAISERROR('Json no valido.',16,1);
		END

		CREATE TABLE #Temp(
			CotizacionItemId INT,
			ConceptoTipoId INT,
			ProductoId INT,
			Concepto VARCHAR(200),
			Cantidad DECIMAL(10,2),
			PrecioUnitario DECIMAL(10,2),
			Notas VARCHAR(500)
		);

		INSERT INTO #Temp(
			CotizacionItemId, ConceptoTipoId, ProductoId, Concepto, Cantidad, PrecioUnitario, Notas
		)
		SELECT
			ISNULL(CotizacionItemId,0),
			ConceptoTipoId,
			ProductoId,
			Concepto,
			Cantidad,
			PrecioUnitario,
			Notas
		FROM OPENJSON(@Json) WITH (
			CotizacionItemId INT '$.CotizacionItemId',
			ConceptoTipoId INT '$.ConceptoTipoId',
			ProductoId INT '$.ProductoId',
			Concepto VARCHAR(200) '$.Concepto',
			Cantidad DECIMAL(10,2) '$.Cantidad',
			PrecioUnitario DECIMAL(10,2) '$.PrecioUnitario',
			Notas VARCHAR(500) '$.Notas'
		);

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.Concepto,'') = '')
		BEGIN
			RAISERROR('Algunos conceptos estan vacios.',16,1);
		END

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.Cantidad,0) <= 0)
		BEGIN
			RAISERROR('Algunas cantidades son invalidas.',16,1);
		END

		IF EXISTS(SELECT 1 FROM #Temp t WHERE ISNULL(t.PrecioUnitario,0) < 0)
		BEGIN
			RAISERROR('Algunos precios son invalidos.',16,1);
		END

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			LEFT JOIN dbo.TblCotizacionConceptoTipos ct (NOLOCK)
				ON t.ConceptoTipoId = ct.ConceptoTipoId
			WHERE ct.ConceptoTipoId IS NULL
		)
		BEGIN
			RAISERROR('Algunos tipos de concepto no existen.',16,1);
		END

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE t.ProductoId IS NOT NULL AND t.ProductoId <> 0
			AND NOT EXISTS(SELECT 1 FROM dbo.TblProductos p (NOLOCK) WHERE p.ProductoId = t.ProductoId)
		)
		BEGIN
			RAISERROR('Algunos productos no existen.',16,1);
		END

		MERGE dbo.TblCotizacionItems AS TARGET
		USING (
			SELECT
				@CotizacionId AS CotizacionId,
				t.CotizacionItemId,
				t.ConceptoTipoId,
				NULLIF(t.ProductoId,0) AS ProductoId,
				t.Concepto,
				t.Cantidad,
				t.PrecioUnitario,
				t.Notas
			FROM #Temp t
		) AS SOURCE
		ON (
			TARGET.CotizacionId = SOURCE.CotizacionId
			AND TARGET.CotizacionItemId = SOURCE.CotizacionItemId
			AND SOURCE.CotizacionItemId <> 0
		)
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.ConceptoTipoId = SOURCE.ConceptoTipoId,
				TARGET.ProductoId = SOURCE.ProductoId,
				TARGET.Concepto = SOURCE.Concepto,
				TARGET.Cantidad = SOURCE.Cantidad,
				TARGET.PrecioUnitario = SOURCE.PrecioUnitario,
				TARGET.Notas = SOURCE.Notas,
				TARGET.EstaActivo = 1
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CotizacionId, ConceptoTipoId, ProductoId, Concepto, Cantidad, PrecioUnitario, Notas, EstaActivo)
			VALUES (SOURCE.CotizacionId, SOURCE.ConceptoTipoId, SOURCE.ProductoId, SOURCE.Concepto, SOURCE.Cantidad, SOURCE.PrecioUnitario, SOURCE.Notas, 1)
		WHEN NOT MATCHED BY SOURCE AND TARGET.CotizacionId = @CotizacionId THEN
			UPDATE SET TARGET.EstaActivo = 0;

		SET @message = 'Items Actualizados';

		SELECT @result [result], @message [message], @elementoId [elementoId];

		DROP TABLE IF EXISTS #Temp;
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
		DROP TABLE IF EXISTS #Temp;
	END CATCH
END
GO


/*
===============================================================================
Author: AGHH
Date: 16/11/2025
Description: Alteración de tipos de filamentos (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE OR ALTER PROCEDURE dbo.procAlteraFilamentosTipos
    @ElementoAlterarId INT = 0,
    @Nombre VARCHAR(200) = '',
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoAlterarId, 0);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF (ISNULL(@Nombre, '') = '')
        BEGIN
            SET @message = 'Nombre no puede ser vacío.';
            RAISERROR(@message, 16, 1);
        END

        IF EXISTS (
            SELECT 1
            FROM dbo.TblFilamentosTipos ft (NOLOCK)
            WHERE ft.FilamentoTipoId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblFilamentosTipos ft (NOLOCK)
                    WHERE ft.Nombre = @Nombre
                    AND ft.FilamentoTipoId != @ElementoAlterarId  -- Excluir el propio para permitir actualizar al mismo nombre
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                SET tgt.Nombre = @Nombre
                FROM dbo.TblFilamentosTipos tgt
                WHERE tgt.FilamentoTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblFilamentosTipos tgt
                WHERE tgt.FilamentoTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM dbo.TblFilamentosTipos ft (NOLOCK)
                WHERE ft.Nombre = @Nombre
            )
            BEGIN
                SET @message = 'Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblFilamentosTipos (Nombre)
            VALUES (@Nombre);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SET @result = 'success';
        SET @message = IIF(@message = '', 'Ningún error', @message);

        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message, '') = '')
        BEGIN
            SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        END
        SELECT @result [result],
               @message [message],
               @elementoId [elementoId];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.procAlteraImpresora
    @ElementoAlterarId INT = 0,
    @Nombre NVARCHAR(150) = NULL,
    @Modelo NVARCHAR(150) = NULL,
    @Notas NVARCHAR(500) = NULL,
    @loginId INT = 0,
    @Actualizar BIT = 0,
    @Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId, 0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF @Borrar = 1
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ElementoAlterarId AND i.EstaActivo = 1
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET EstaActivo = 0,
                FechaActualizacion = SYSDATETIME()
            WHERE ImpresoraId = @ElementoAlterarId;

            SET @message = 'Impresora desactivada.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        IF ISNULL(LTRIM(RTRIM(@Nombre)), '') = ''
            RAISERROR('El nombre es requerido.', 16, 1);

        IF @Actualizar = 1
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ElementoAlterarId
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET Nombre = @Nombre,
                Modelo = NULLIF(@Modelo,''),
                Notas = NULLIF(@Notas,''),
                FechaActualizacion = SYSDATETIME(),
                EstaActivo = 1
            WHERE ImpresoraId = @ElementoAlterarId;

            SET @message = 'Impresora actualizada.';
            SELECT @result [result], @message [message], @ElementoAlterarId [elementoId];
            RETURN;
        END

        INSERT INTO dbo.TblImpresoras (UsuarioId, Nombre, Modelo, Notas, EstaActivo)
        VALUES (@loginId, @Nombre, NULLIF(@Modelo,''), NULLIF(@Notas,''), 1);

        SET @elementoId = SCOPE_IDENTITY();
        SET @message = 'Impresora creada.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Description: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Description     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE OR ALTER PROCEDURE dbo.procAlteraInventariosColores
@ElementoAlterarId	 INT = 0,
@Nombre				 VARCHAR(200) = '',
@Abreviatura		 VARCHAR(200) = '',
@loginId			 INT = 0,
@Actualizar			 BIT = 0,
@Borrar				 BIT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoAlterarId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		IF(ISNULL(@Nombre, '') = '')
		BEGIN 
			SET @message = 'Nombre no puede ser vacio.';
			RAISERROR(@message, 16, 1);
		END

		IF(ISNULL(@Abreviatura, '') = '')
		BEGIN 
			SET @message = 'Abreviatura no puede ser vacio.';
			RAISERROR(@message, 16, 1);
		END

		IF EXISTS(
			SELECT 1 
			FROM dbo.TblInventariosColores im (NOLOCK)
			WHERE im.InventarioColorId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblInventariosColores im (NOLOCK)
					WHERE im.Nombre = @Nombre
					AND im.Abreviatura = @Abreviatura
				)
				BEGIN
					SET @message = 'Nombre ya existe actualmente.';
					RAISERROR(@message, 16, 1);
				END

				UPDATE tgt
					SET tgt.Nombre = @Nombre,
						tgt.Abreviatura = @Abreviatura
				FROM dbo.TblInventariosColores tgt
				WHERE tgt.InventarioColorId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 
				
				UPDATE tgt
					SET tgt.EstaActivo = 0
				FROM dbo.TblInventariosColores tgt
				WHERE tgt.InventarioColorId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblInventariosColores im (NOLOCK)
				WHERE im.Nombre = @Nombre
				AND im.Abreviatura = @Abreviatura
			)
			BEGIN
				SET @message = 'Nombre ya existe actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblInventariosColores(Nombre, Abreviatura)
			VALUES (@Nombre, @Abreviatura);
			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SET @result = 'success';
		SET @message = IIF(@message = '','Ningun error', @message);


		SELECT @result [result],
			   @message [message],
			   @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN 
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		
		SELECT @result [result],
			   @message [message],
			   @elementoId [elementoId];
	END CATCH
END
GO


CREATE OR ALTER PROCEDURE dbo.procAlteraReceta
@ElementoAlterarId  INT = 0,
@Nombre             VARCHAR(200) = '',
@TiempoImpresion    VARCHAR(200) = NULL,   -- legacy
@TiempoImpresionMin INT = NULL,            -- nuevo
@TiempoPostMin      INT = NULL,            -- nuevo
@ProductoId         INT = 0,
@loginId            INT = 0,
@Actualizar         BIT = 0,
@Borrar             BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result  VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ElementoAlterarId,0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF (ISNULL(@Borrar,0) = 0)
        BEGIN
            IF (ISNULL(@Nombre,'') = '')
                RAISERROR('Nombre no puede ser vacío.',16,1);

            SET @TiempoImpresionMin = ISNULL(@TiempoImpresionMin, 0);
            SET @TiempoPostMin      = ISNULL(@TiempoPostMin, 0);

            IF (@TiempoImpresionMin < 0) RAISERROR('TiempoImpresionMin debe ser >= 0.',16,1);
            IF (@TiempoPostMin < 0)      RAISERROR('TiempoPostMin debe ser >= 0.',16,1);
        END

        IF EXISTS (SELECT 1 FROM dbo.TblRecetas r (NOLOCK) WHERE r.RecetaId = @elementoId)
        BEGIN
            IF (ISNULL(@Actualizar,0) = 1)
            BEGIN
                UPDATE dbo.TblRecetas
                SET Nombre = @Nombre,
                    ProductoId = @ProductoId,
                    TiempoImpresion = COALESCE(NULLIF(@TiempoImpresion,''), TiempoImpresion),
                    TiempoImpresionMin = @TiempoImpresionMin,
                    TiempoPostMin = @TiempoPostMin,
                    EstaActivo = 1
                WHERE RecetaId = @elementoId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar,0) = 1)
            BEGIN
                UPDATE dbo.TblRecetasInventarios SET EstaActivo = 0 WHERE RecetaId = @elementoId;
                UPDATE dbo.TblRecetas SET EstaActivo = 0 WHERE RecetaId = @elementoId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.TblRecetas r (NOLOCK) WHERE r.Nombre = @Nombre)
                RAISERROR('Nombre ya existe actualmente.',16,1);

            INSERT INTO dbo.TblRecetas (Nombre, ProductoId, TiempoImpresion, TiempoImpresionMin, TiempoPostMin, EstaActivo)
            VALUES (@Nombre, @ProductoId, ISNULL(@TiempoImpresion,''), ISNULL(@TiempoImpresionMin,0), ISNULL(@TiempoPostMin,0), 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SET @result = 'success';
        SET @message = IIF(@message='','Ningun error',@message);

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF (ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO
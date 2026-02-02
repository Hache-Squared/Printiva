-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CrearDatosUsuarioNuevo]
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

	INSERT INTO TiposCuentas(Nombre, UsuarioId, Orden)
	VALUES (@Efectivo, @UsuarioId, 1),
	(@CuentasDeBanco, @UsuarioId, 2),
	(@Tarjetas, @UsuarioId, 3);

	INSERT INTO Cuentas (Nombre, Balance, TipoCuentaId)
	SELECT Nombre, 0, Id
	FROM TiposCuentas
	WHERE UsuarioId = @UsuarioId;

	INSERT INTO Categorias(Nombre, TipoOperacionId, UsuarioId)
	VALUES 
	('Libros', 2, @UsuarioId),
	('Salario', 1, @UsuarioId),
	('Mesada', 1, @UsuarioId),
	('Comida', 2, @UsuarioId)

END
CREATE   PROCEDURE dbo.procActualizarPedido
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
    WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
END
GO

﻿/*
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
CREATE PROCEDURE dbo.procActualizarRegistrosInventarios
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
END﻿/*
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

CREATE PROCEDURE dbo.procAlteraClientes
    @ElementoAlterarId INT = 0,
    @Nombre VARCHAR(200) = '',
    @Telefono VARCHAR(200) = NULL,  -- NULLable, default NULL
    @Correo VARCHAR(200) = NULL,    -- NULLable, default NULL
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
        -- Solo valida inputs si es Actualizar o CREATE (no para Borrar, donde params son defaults)
        IF (ISNULL(@Actualizar, 0) = 1 OR (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0))
        BEGIN
            IF (ISNULL(@Nombre, '') = '')
            BEGIN
                SET @message = 'Nombre no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
        END
        -- Para Borrar, solo valida existencia del registro
        IF (ISNULL(@Borrar, 0) = 1 AND NOT EXISTS (
            SELECT 1
            FROM dbo.TblClientes cl (NOLOCK)
            WHERE cl.ClienteId = @ElementoAlterarId
        ))
        BEGIN
            SET @message = 'Registro no encontrado para borrar.';
            RAISERROR(@message, 16, 1);
        END
        IF EXISTS (
            SELECT 1
            FROM dbo.TblClientes cl (NOLOCK)
            WHERE cl.ClienteId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                -- Valida duplicado de Nombre (excluyendo el propio)
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblClientes cl (NOLOCK)
                    WHERE cl.Nombre = @Nombre
                    AND cl.ClienteId != @ElementoAlterarId
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                UPDATE tgt
                SET tgt.Nombre = @Nombre,
                    tgt.Telefono = @Telefono,  -- Maneja NULL directamente
                    tgt.Correo = @Correo       -- Maneja NULL directamente
                FROM dbo.TblClientes tgt
                WHERE tgt.ClienteId = @ElementoAlterarId;
                SET @message = 'Elemento Actualizado';
            END
            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblClientes tgt
                WHERE tgt.ClienteId = @ElementoAlterarId;
                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            -- Asume CREATE si no Actualizar ni Borrar
            IF (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0)
            BEGIN
                -- Valida duplicado de Nombre para CREATE
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblClientes cl (NOLOCK)
                    WHERE cl.Nombre = @Nombre
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                INSERT INTO dbo.TblClientes (Nombre, Telefono, Correo)
                VALUES (@Nombre, @Telefono, @Correo);  -- Maneja NULL directamente
                SET @elementoId = SCOPE_IDENTITY();
                SET @message = 'Elemento Agregado';
            END
            ELSE
            BEGIN
                SET @message = 'Operación inválida: No es CREATE ni UPDATE ni Borrar.';
                RAISERROR(@message, 16, 1);
            END
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
END﻿/*
===============================================================================
Author: AGHH
Date: 16/11/2025
Description: Alteración de compras (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procAlteraCompras
    @ElementoAlterarId INT = 0,
    @Descripcion VARCHAR(MAX) = '',
    @CompraTipoId INT = 0,
    @FilamentoTipoId INT = NULL,
    @CompraCategoriaId INT = 0,
    @CostoTotal DECIMAL(10,2) = 0,
    @FechaCreacion DATETIME = NULL,
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
        SET @FechaCreacion = ISNULL(@FechaCreacion, GETUTCDATE()); -- Usa parámetro o default
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF (ISNULL(@Actualizar, 0) = 1)
        BEGIN
            IF (ISNULL(@Descripcion, '') = '')
            BEGIN
                SET @message = 'Descripción no puede ser vacío.';
                RAISERROR(@message, 16, 1);
            END
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblComprasTipos ct (NOLOCK)
                WHERE ct.CompraTipoId = @CompraTipoId
            )
            BEGIN
                SET @message = 'Tipo de compra no existe.';
                RAISERROR(@message, 16, 1);
            END
            IF (@FilamentoTipoId IS NOT NULL AND @FilamentoTipoId != 0 AND NOT EXISTS (
                SELECT 1
                FROM dbo.TblFilamentosTipos ft (NOLOCK)
                WHERE ft.FilamentoTipoId = @FilamentoTipoId
            ))
            BEGIN
                SET @message = 'Tipo de filamento no existe.';
                RAISERROR(@message, 16, 1);
            END
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.TblComprasCategorias cc (NOLOCK)
                WHERE cc.CompraCategoriaId = @CompraCategoriaId
            )
            BEGIN
                SET @message = 'Categoría de compra no existe.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF (ISNULL(@Borrar, 0) = 1 AND NOT EXISTS (
            SELECT 1
            FROM dbo.TblCompras c (NOLOCK)
            WHERE c.CompraId = @ElementoAlterarId
        ))
        BEGIN
            SET @message = 'Registro no encontrado para borrar.';
            RAISERROR(@message, 16, 1);
        END
        IF EXISTS (
            SELECT 1
            FROM dbo.TblCompras c (NOLOCK)
            WHERE c.CompraId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblCompras c (NOLOCK)
                    WHERE c.Descripcion = @Descripcion
                    AND c.CompraTipoId = @CompraTipoId
                    AND c.CompraCategoriaId = @CompraCategoriaId
                    AND c.CompraId != @ElementoAlterarId -- Excluir el propio para permitir actualizar al mismo
                )
                BEGIN
                    SET @message = 'Descripción ya existe con esa tipo y categoría actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                UPDATE tgt
                SET tgt.Descripcion = @Descripcion,
                    tgt.CompraTipoId = @CompraTipoId,
                    tgt.FilamentoTipoId = @FilamentoTipoId,
                    tgt.CompraCategoriaId = @CompraCategoriaId,
                    tgt.CostoTotal = @CostoTotal,
                    tgt.FechaCreacion = @FechaCreacion
                FROM dbo.TblCompras tgt
                WHERE tgt.CompraId = @ElementoAlterarId;
                SET @message = 'Elemento Actualizado';
            END
            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblCompras tgt
                WHERE tgt.CompraId = @ElementoAlterarId;
                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 0 AND ISNULL(@Borrar, 0) = 0)  -- Asume CREATE si no Actualizar ni Borrar
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblCompras c (NOLOCK)
                    WHERE c.Descripcion = @Descripcion
                    AND c.CompraTipoId = @CompraTipoId
                    AND c.CompraCategoriaId = @CompraCategoriaId
                )
                BEGIN
                    SET @message = 'Descripción ya existe con esa tipo y categoría actualmente.';
                    RAISERROR(@message, 16, 1);
                END
                INSERT INTO dbo.TblCompras (Descripcion, CompraTipoId, FilamentoTipoId, CompraCategoriaId, CostoTotal, FechaCreacion)
                VALUES (@Descripcion, @CompraTipoId, @FilamentoTipoId, @CompraCategoriaId, @CostoTotal, @FechaCreacion);
                SET @elementoId = SCOPE_IDENTITY();
                SET @message = 'Elemento Agregado';
            END
            ELSE
            BEGIN
                SET @message = 'Operación inválida: No es CREATE ni UPDATE ni Borrar.';
                RAISERROR(@message, 16, 1);
            END
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
END﻿/*
===============================================================================
Author: AGHH
Date: 16/11/2025
Description: Alteración de categorías de compras (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procAlteraComprasCategorias
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
            FROM dbo.TblComprasCategorias cc (NOLOCK)
            WHERE cc.CompraCategoriaId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblComprasCategorias cc (NOLOCK)
                    WHERE cc.Nombre = @Nombre
                    AND cc.CompraCategoriaId != @ElementoAlterarId  -- Excluir el propio para permitir actualizar al mismo nombre
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                SET tgt.Nombre = @Nombre
                FROM dbo.TblComprasCategorias tgt
                WHERE tgt.CompraCategoriaId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblComprasCategorias tgt
                WHERE tgt.CompraCategoriaId = @ElementoAlterarId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM dbo.TblComprasCategorias cc (NOLOCK)
                WHERE cc.Nombre = @Nombre
            )
            BEGIN
                SET @message = 'Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasCategorias (Nombre)
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
END﻿/*
===============================================================================
Author: AGHH
Date: 16/11/2025
Description: Alteración de tipos de compras (Crear/Actualizar/Borrar)
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procAlteraComprasTipos
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
            FROM dbo.TblComprasTipos ct (NOLOCK)
            WHERE ct.CompraTipoId = @ElementoAlterarId
        )
        BEGIN
            IF (ISNULL(@Actualizar, 0) = 1)
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM dbo.TblComprasTipos ct (NOLOCK)
                    WHERE ct.Nombre = @Nombre
                    AND ct.CompraTipoId != @ElementoAlterarId  -- Excluir el propio para permitir actualizar al mismo nombre
                )
                BEGIN
                    SET @message = 'Nombre ya existe actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                SET tgt.Nombre = @Nombre
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF (ISNULL(@Borrar, 0) = 1)
            BEGIN
                DELETE tgt
                FROM dbo.TblComprasTipos tgt
                WHERE tgt.CompraTipoId = @ElementoAlterarId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM dbo.TblComprasTipos ct (NOLOCK)
                WHERE ct.Nombre = @Nombre
            )
            BEGIN
                SET @message = 'Nombre ya existe actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblComprasTipos (Nombre)
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
ENDCREATE   PROCEDURE dbo.procAlteraCotizacion
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
				UPDATE dbo.TblCotizacionesItems
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

CREATE   PROCEDURE dbo.procAlteraCotizacionItemsRelacion
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

﻿/*
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

CREATE PROCEDURE dbo.procAlteraFilamentosTipos
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
ENDCREATE   PROCEDURE dbo.procAlteraImpresora
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
                WHERE i.ImpresoraId = @ElementoAlterarId AND i.UsuarioId = @loginId AND i.EstaActivo = 1
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET EstaActivo = 0,
                FechaActualizacion = SYSDATETIME()
            WHERE ImpresoraId = @ElementoAlterarId AND UsuarioId = @loginId;

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
                WHERE i.ImpresoraId = @ElementoAlterarId AND i.UsuarioId = @loginId
            )
                RAISERROR('Impresora no encontrada.', 16, 1);

            UPDATE dbo.TblImpresoras
            SET Nombre = @Nombre,
                Modelo = NULLIF(@Modelo,''),
                Notas = NULLIF(@Notas,''),
                FechaActualizacion = SYSDATETIME(),
                EstaActivo = 1
            WHERE ImpresoraId = @ElementoAlterarId AND UsuarioId = @loginId;

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

﻿/*
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
CREATE PROCEDURE dbo.procAlteraInventariosColores
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
END﻿/*
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
CREATE PROCEDURE dbo.procAlteraInventariosMarcas
@ElementoAlterarId INT = 0,
@Nombre		VARCHAR(200) = '',
@loginId	INT = 0,
@Actualizar BIT = 0,
@Borrar		BIT = 0
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

		IF EXISTS(
			SELECT 1 
			FROM dbo.TblInventariosMarcas im (NOLOCK)
			WHERE im.InventarioMarcaId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblInventariosMarcas im (NOLOCK)
					WHERE im.Nombre = @Nombre
				)
				BEGIN
					SET @message = 'Nombre ya existe actualmente.';
					RAISERROR(@message, 16, 1);
				END

				UPDATE tgt
					SET tgt.Nombre = @Nombre
				FROM dbo.TblInventariosMarcas tgt
				WHERE tgt.InventarioMarcaId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 
				
				UPDATE tgt
					SET tgt.EstaActivo = 0
				FROM dbo.TblInventariosMarcas tgt
				WHERE tgt.InventarioMarcaId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblInventariosMarcas im (NOLOCK)
				WHERE im.Nombre = @Nombre
			)
			BEGIN
				SET @message = 'Nombre ya existe actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblInventariosMarcas(Nombre)
			VALUES (@Nombre);
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
END﻿/*
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
CREATE PROCEDURE dbo.procAlteraInventariosNombres
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
			FROM dbo.TblInventariosNombres im (NOLOCK)
			WHERE im.InventarioNombreId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblInventariosNombres im (NOLOCK)
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
				FROM dbo.TblInventariosNombres tgt
				WHERE tgt.InventarioNombreId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 

				UPDATE tgt
					SET tgt.EstaActivo = 0
				FROM dbo.TblInventariosNombres tgt
				WHERE tgt.InventarioNombreId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblInventariosNombres im (NOLOCK)
				WHERE im.Nombre = @Nombre
				AND im.Abreviatura = @Abreviatura
			)
			BEGIN
				SET @message = 'Nombre ya existe actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblInventariosNombres(Nombre, Abreviatura)
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
END﻿/*
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
CREATE PROCEDURE dbo.procAlteraInventariosTipos
@ElementoAlterarId INT = 0,
@Nombre		VARCHAR(200) = '',
@loginId	INT = 0,
@Actualizar BIT = 0,
@Borrar		BIT = 0
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

		IF EXISTS(
			SELECT 1 
			FROM dbo.TblInventariosTipos im (NOLOCK)
			WHERE im.InventarioTipoId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblInventariosTipos im (NOLOCK)
					WHERE im.Nombre = @Nombre
				)
				BEGIN
					SET @message = 'Nombre ya existe actualmente.';
					RAISERROR(@message, 16, 1);
				END

				UPDATE tgt
					SET tgt.Nombre = @Nombre
				FROM dbo.TblInventariosTipos tgt
				WHERE tgt.InventarioTipoId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 
				
				UPDATE tgt
					SET tgt.EstaActivo = 0
				FROM dbo.TblInventariosTipos tgt
				WHERE tgt.InventarioTipoId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblInventariosTipos im (NOLOCK)
				WHERE im.Nombre = @Nombre
			)
			BEGIN
				SET @message = 'Nombre ya existe actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblInventariosTipos(Nombre)
			VALUES (@Nombre);
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
ENDCREATE   PROCEDURE dbo.procAlteraPago
@ElementoAlterarId INT = 0,
@CotizacionId INT = 0,
@PagoTipoId INT = 0,
@Monto DECIMAL(10,2) = 0,
@FechaPago DATETIME = NULL,
@Metodo VARCHAR(100) = NULL,
@Referencia VARCHAR(200) = NULL,
@Notas VARCHAR(500) = NULL,
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

		IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
		BEGIN
			RAISERROR('Cotizacion no encontrada.',16,1);
		END

		IF NOT EXISTS(SELECT 1 FROM dbo.TblPagoTipos pt (NOLOCK) WHERE pt.PagoTipoId = @PagoTipoId)
		BEGIN
			RAISERROR('Tipo de pago no existe.',16,1);
		END

		IF(ISNULL(@Monto,0) <= 0)
		BEGIN
			RAISERROR('Monto invalido.',16,1);
		END

		IF(@FechaPago IS NULL)
		BEGIN
			RAISERROR('FechaPago requerida.',16,1);
		END

		IF EXISTS(SELECT 1 FROM dbo.TblPagos p (NOLOCK) WHERE p.PagoId = @elementoId)
		BEGIN
			IF(ISNULL(@Borrar,0) = 1)
			BEGIN
				UPDATE dbo.TblPagos
				SET EstaActivo = 0
				WHERE PagoId = @elementoId;

				SET @message = 'Elemento Eliminado';
			END
			ELSE IF(ISNULL(@Actualizar,0) = 1)
			BEGIN
				UPDATE dbo.TblPagos
				SET PagoTipoId = @PagoTipoId,
					Monto = @Monto,
					FechaPago = @FechaPago,
					Metodo = @Metodo,
					Referencia = @Referencia,
					Notas = @Notas
				WHERE PagoId = @elementoId;

				SET @message = 'Elemento Actualizado';
			END
			ELSE
			BEGIN
				SET @message = 'Sin cambios';
			END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.TblPagos(
				CotizacionId, PagoTipoId, Monto, FechaPago, Metodo, Referencia, Notas, EstaActivo
			)
			VALUES(
				@CotizacionId, @PagoTipoId, @Monto, @FechaPago, @Metodo, @Referencia, @Notas, 1
			);

			SET @elementoId = SCOPE_IDENTITY();
			SET @message = 'Elemento Agregado';
		END

		SELECT @result [result], @message [message], @elementoId [elementoId];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		SELECT @result [result], @message [message], @elementoId [elementoId];
	END CATCH
END
GO

CREATE   PROCEDURE dbo.procAlteraProductos
@ElementoAlterarId INT = 0,
@Nombre VARCHAR(200) = '',
@ProductoCategoriaId INT = 0,
@SKU VARCHAR(200) = '',
@PrecioSugerido DECIMAL(18,2) = NULL,
@loginId INT = 0,
@Actualizar BIT = 0,
@Borrar BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

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

        IF(ISNULL(@Nombre,'') = '' AND ISNULL(@Borrar,0) = 0)
        BEGIN
            SET @message = 'Nombre no puede ser vacio.';
            RAISERROR(@message, 16, 1);
        END

        IF(ISNULL(@Borrar,0) = 0)
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblProductosCategorias pc (NOLOCK)
                WHERE pc.ProductoCategoriaId = @ProductoCategoriaId
            )
            BEGIN
                SET @message = 'Categoria de producto no existe.';
                RAISERROR(@message, 16, 1);
            END
        END

        IF EXISTS(
            SELECT 1
            FROM dbo.TblProductos p (NOLOCK)
            WHERE p.ProductoId = @ElementoAlterarId
        )
        BEGIN
            IF(ISNULL(@Actualizar,0) = 1)
            BEGIN
                IF EXISTS(
                    SELECT 1
                    FROM dbo.TblProductos p (NOLOCK)
                    WHERE p.Nombre = @Nombre
                      AND p.ProductoCategoriaId = @ProductoCategoriaId
                      AND p.ProductoId <> @ElementoAlterarId
                      AND p.EstaActivo = 1
                )
                BEGIN
                    SET @message = 'Nombre ya existe con esa categoria actualmente.';
                    RAISERROR(@message, 16, 1);
                END

                UPDATE tgt
                    SET tgt.Nombre = @Nombre,
                        tgt.ProductoCategoriaId = @ProductoCategoriaId,
                        tgt.SKU = @SKU,
                        tgt.PrecioSugerido = @PrecioSugerido
                FROM dbo.TblProductos tgt
                WHERE tgt.ProductoId = @ElementoAlterarId;

                SET @message = 'Elemento Actualizado';
            END

            IF(ISNULL(@Borrar,0) = 1)
            BEGIN
                UPDATE dbo.TblProductos
                    SET EstaActivo = 0
                WHERE ProductoId = @ElementoAlterarId;

                SET @message = 'Elemento Eliminado';
            END
        END
        ELSE
        BEGIN
            IF EXISTS(
                SELECT 1
                FROM dbo.TblProductos p (NOLOCK)
                WHERE p.Nombre = @Nombre
                  AND p.ProductoCategoriaId = @ProductoCategoriaId
                  AND p.EstaActivo = 1
            )
            BEGIN
                SET @message = 'Nombre ya existe con esa categoria actualmente.';
                RAISERROR(@message, 16, 1);
            END

            INSERT INTO dbo.TblProductos(Nombre, ProductoCategoriaId, SKU, PrecioSugerido, EstaActivo)
            VALUES (@Nombre, @ProductoCategoriaId, @SKU, @PrecioSugerido, 1);

            SET @elementoId = SCOPE_IDENTITY();
            SET @message = 'Elemento Agregado';
        END

        SELECT
            'success' [result],
            @message [message],
            @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SELECT
            'fail' [result],
            CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.') [message],
            @elementoId [elementoId];
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
CREATE   PROCEDURE dbo.procAlteraProductosCategorias
@ElementoAlterarId INT = 0,
@Nombre		VARCHAR(200) = '',
@loginId	INT = 0,
@Actualizar BIT = 0,
@Borrar		BIT = 0
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

		IF EXISTS(
			SELECT 1 
			FROM dbo.TblProductosCategorias im (NOLOCK)
			WHERE im.ProductoCategoriaId = @ElementoAlterarId
		)
		BEGIN 
			IF(
				ISNULL(@Actualizar, 0) = 1
			)
			BEGIN
				IF EXISTS(
					SELECT 1
					FROM dbo.TblProductosCategorias im (NOLOCK)
					WHERE im.Nombre = @Nombre
				)
				BEGIN
					SET @message = 'Nombre ya existe actualmente.';
					RAISERROR(@message, 16, 1);
				END

				UPDATE tgt
					SET tgt.Nombre = @Nombre
				FROM dbo.TblProductosCategorias tgt
				WHERE tgt.ProductoCategoriaId = @ElementoAlterarId

				SET @message = 'Elemento Actualizado';
			END

			IF(
				ISNULL(@Borrar, 0) = 1
			)
			BEGIN 
				UPDATE tgt
					SET EstaActivo = 0
				FROM dbo.TblProductosCategorias tgt
				WHERE tgt.ProductoCategoriaId = @ElementoAlterarId

				SET @message = 'Elemento Eliminado';
			END
			
		END
		ELSE 
		BEGIN 
			IF EXISTS(
				SELECT 1
				FROM dbo.TblProductosCategorias im (NOLOCK)
				WHERE im.Nombre = @Nombre
			)
			BEGIN
				SET @message = 'Nombre ya existe actualmente.';
				RAISERROR(@message, 16, 1);
			END
			
			INSERT INTO dbo.TblProductosCategorias(Nombre)
			VALUES (@Nombre);
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
CREATE   PROCEDURE dbo.procAlteraReceta
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

﻿/*
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
CREATE PROCEDURE dbo.procAlteraRecetaRelacion
@loginId			INT = 0,
@ElementoAlterarId  INT = 0,
@Json				VARCHAR(MAX) = '[]'
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
			FROM dbo.TblRecetas r (NOLOCK)
			WHERE r.RecetaId = @elementoId
		)
		BEGIN
			SET @message = 'Receta no encontrada.';
			RAISERROR(@message, 16, 1);
		END

		SET @Json = ISNULL(@Json, '[]')
		
		IF(ISJSON(@Json) = 0)
		BEGIN 
			SET @message = 'Json no valido.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #Temp(
			Id INT PRIMARY KEY IDENTITY(1,1),
			InventarioId INT,
			Cantidad DECIMAL(10,2)
		)

		INSERT INTO #Temp(InventarioId, Cantidad)
		SELECT 
			InventarioId,
			Cantidad
		FROM OPENJSON(@Json) WITH (
			InventarioId INT '$.InventarioId',
			Cantidad	 DECIMAL(10,2) '$.Cantidad'
		);

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE ISNULL(t.Cantidad,0) = 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades no tienen valor.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE ISNumeric(t.Cantidad) = 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades no son un numero.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			WHERE t.Cantidad < 0
		)
		BEGIN 
			SET @message = 'Algunas cantidades son negativas.';
			RAISERROR(@message, 16, 1);
		END;

		IF EXISTS(
			SELECT 1
			FROM #Temp t
			LEFT JOIN dbo.TblInventarios i (NOLOCK)
				ON t.InventarioId = i.InventarioId
			WHERE i.InventarioId IS NULL
		)
		BEGIN 
			SET @message = 'Algunos elementos de inventario no existen.';
			RAISERROR(@message, 16, 1);
		END;

		MERGE dbo.TblRecetasInventarios AS TARGET
		USING (
			SELECT 
				@elementoId [RecetaId],
				t.InventarioId [InventarioId],
				t.Cantidad [Cantidad]
			FROM #Temp t
		) AS SOURCE  
			ON (
				TARGET.RecetaId = SOURCE.RecetaId AND
				TARGET.InventarioId = SOURCE.InventarioId
			)
		WHEN MATCHED THEN 
			UPDATE SET TARGET.Cantidad = SOURCE.Cantidad
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (
				RecetaId,
				InventarioId,
				Cantidad
			)
			VALUES(
				SOURCE.RecetaId,
				SOURCE.InventarioId,
				SOURCE.Cantidad
			)
		WHEN NOT MATCHED BY SOURCE 
		AND TARGET.RecetaId = @elementoId THEN  -- Esto filtra correctamente el DELETE
			DELETE;

			

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
	DROP TABLE IF EXISTS #Temp;
END﻿/*
===============================================================================
Author: AGHH
Date: 27/07/2025
Desrciption: Creacion de inventarios 
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version     Author     Date         Desrciption     Ticket
-------------------------------------------------------------------------------
1.0         AGHH     27/07/2025     First Version   N/A
*/
CREATE PROCEDURE dbo.procAlteraInventarios
@loginId			INT = 0,
@InventarioMarcaId  INT = 0,
@InventarioTipoId   INT = 0,
@InventarioColorId	INT = 0,
@InventarioNombreId	INT = 0,
@Cantidad			DECIMAL(10,2) = 0,
@TipoMovimiento		VARCHAR(200) = '',
@InventarioUnidad   VARCHAR(200) = ''
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';

	BEGIN TRY

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

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
			FROM dbo.TblInventariosNombres ic (NOLOCK)
			WHERE ic.InventarioNombreId = @InventarioNombreId
		)
		BEGIN 
			SET @message = 'Nombre de inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		DECLARE @TipoMovimientoId INT = (
			SELECT TOP 1 mt.TipoMovimientoId
			FROM dbo.TblInventariosMovimientoTipos mt (NOLOCK)
			WHERE mt.Nombre = @TipoMovimiento
			ORDER BY mt.TipoMovimientoId DESC
		);

		IF(ISNULL(@TipoMovimientoId, 0) = 0)
		BEGIN 
			SET @message = 'Tipo de movimiento para inventario no encontrado.';
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

		DECLARE @InventarioUnidadId INT = (
			SELECT TOP 1 mt.InventarioUnidadId
			FROM dbo.TblInventariosUnidades mt (NOLOCK)
			WHERE mt.Nombre = @InventarioUnidad
			ORDER BY mt.InventarioUnidadId DESC
		);

		IF(ISNULL(@InventarioUnidadId, 0) = 0)
		BEGIN 
			SET @message = 'Tipo de unidad para inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		MERGE dbo.TblInventarios AS tgt
		USING (
			SELECT 
				@Cantidad			[Cantidad],
				@InventarioMarcaId  [InventarioMarcaId],
				@InventarioTipoId   [InventarioTipoId],
				@InventarioColorId	[InventarioColorId],
				@TipoMovimiento		[TipoMovimiento],
				@TipoMovimientoId   [TipoMovimientoId],
				@InventarioUnidadId [InventarioUnidadId],
				@InventarioNombreId [InventarioNombreId]
		) AS src 
			ON  (
				tgt.InventarioMarcaId = src.InventarioMarcaId AND 
				tgt.InventarioTipoId = src.InventarioTipoId AND 
				tgt.InventarioColorId = src.InventarioColorId AND
				tgt.InventarioNombreId = src.InventarioNombreId AND
				tgt.InventarioUnidadId = src.InventarioUnidadId 
			)
		WHEN MATCHED THEN
			UPDATE SET tgt.Cantidad = (
				SELECT 
					CASE 
						WHEN UPPER(src.TipoMovimiento) = 'COMPRA' THEN
							tgt.Cantidad + src.Cantidad
						WHEN UPPER(src.TipoMovimiento) = 'VENTA' THEN
							tgt.Cantidad - src.Cantidad
						ELSE 0
					END Cantidad
			)
		WHEN NOT MATCHED THEN
			INSERT (
				InventarioMarcaId,
				InventarioTipoId,
				InventarioColorId,
				InventarioNombreId,
				Cantidad,
				InventarioUnidadId
			)
			VALUES(
				src.InventarioMarcaId,
				src.InventarioTipoId,
				src.InventarioColorId,
				src.InventarioNombreId,
				src.Cantidad,
				src.InventarioUnidadId
			);

		SET @result = 'success';
		SET @message = 'Alteración a inventario correcta.';


		SELECT @result [result],
			   @message [message];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN 
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		
		SELECT @result [result],
			   @message [message];
	END CATCH
ENDCREATE   PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        UPDATE dbo.TblPedidoItems
            SET EstaActivo = 0 
        WHERE PedidoId = @pedidoId;

        UPDATE dbo.TblPedidos 
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId AND UsuarioId = @loginId;
    END
END
GO

CREATE   PROCEDURE dbo.procCrearPedido
    @loginId INT,
    @clienteId INT,
    @pedidoEstatusId INT,
    @fechaEntregaEstimada DATETIME2 = NULL,
    @notas NVARCHAR(500) = NULL,
    @totalEstimado DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TblPedidos (UsuarioId, ClienteId, PedidoEstatusId, FechaEntregaEstimada, Notas, TotalEstimado)
    VALUES (@loginId, @clienteId, @pedidoEstatusId, @fechaEntregaEstimada, @notas, @totalEstimado);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS PedidoId;
END
GO

﻿/*
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
CREATE PROCEDURE dbo.procInsertarMovimientoInventario
@InventarioId	INT = 0,
@TipoMovimiento VARCHAR(200) = '',
@Cantidad		INT = 0,
@Costo			INT = 0,
@loginId		INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';

	BEGIN TRY


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
			WHERE i.InventarioId = @InventarioId
		)
		BEGIN
			SET @message = 'Inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		DECLARE @TipoMovimientoId INT = (
			SELECT TOP 1 mt.TipoMovimientoId
			FROM dbo.TblInventariosMovimientoTipos mt (NOLOCK)
			WHERE mt.Nombre = @TipoMovimiento
			ORDER BY mt.TipoMovimientoId DESC
		);

		IF(ISNULL(@TipoMovimientoId, 0) = 0)
		BEGIN 
			SET @message = 'Tipo de movimiento para inventario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		INSERT INTO dbo.TblInventariosMovimientos(
			InventarioId,
			TipoMovimientoId,
			Cantidad,
			Costo,
			UsuarioId
		)
		VALUES(
			@InventarioId,
			@TipoMovimientoId,
			@Cantidad,
			@Costo,
			@loginId
		);
		

		SET @result = 'success';
		SET @message = 'Movimiento Registrado';


		SELECT @result [result],
			   @message [message];
	END TRY
	BEGIN CATCH
		SET @result = 'fail';
		IF(ISNULL(@message,'') = '')
		BEGIN 
			SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
		END
		
		SELECT @result [result],
			   @message [message];
	END CATCH
ENDCREATE   PROCEDURE dbo.procObtenerClientes
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ClienteId,
        UsuarioId,
        Nombre,
        Telefono,
        Instagram,
        WhatsApp,
        Email,
        Direccion,
        FechaCreacion
    FROM dbo.TblClientes
    WHERE UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR ClienteId = @elementoObtenerId)
    ORDER BY Nombre;
END
GO

﻿/*
===============================================================================
Author: AGHH (adaptado para Compras)
Date: 16/11/2025
Description: Obtención de compras con JOINs a tipos y categorías
Ticket: 0000
Customer: N/A
Version: 1.0
==============================================================================
History:
Version Author Date Description Ticket
-------------------------------------------------------------------------------
1.0 AGHH 16/11/2025 First Version N/A
*/

CREATE PROCEDURE dbo.procObtenerCompras
    @ElementoObtenerId INT = 0,
    @loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(100) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoObtenerId, 0);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        -- Temp table con campos que coincidan con la entidad Compra
        CREATE TABLE #TempData (
            CompraId INT,
            Descripcion VARCHAR(500),  -- Ajusta el tamaño según tu esquema
            CompraTipoId INT,
            FilamentoTipoId INT,
            CompraCategoriaId INT,
            CostoTotal DECIMAL(18,2),
            FechaCreacion DATETIME,
            CompraTipo VARCHAR(200),
            FilamentoTipo VARCHAR(200),
            CompraCategoria VARCHAR(200)
        );

        INSERT INTO #TempData (
            CompraId,
            Descripcion,
            CompraTipoId,
            FilamentoTipoId,
            CompraCategoriaId,
            CostoTotal,
            FechaCreacion,
            CompraTipo,
            FilamentoTipo,
            CompraCategoria
        )
        SELECT
            c.CompraId,
            c.Descripcion,
            c.CompraTipoId,
            c.FilamentoTipoId,
            c.CompraCategoriaId,
            c.CostoTotal,
            c.FechaCreacion,
            ct.Nombre AS CompraTipo,  -- Asume que TblComprasTipos tiene campo 'Nombre'
            ft.Nombre AS FilamentoTipo,  -- Asume que TblFilamentoTipos tiene 'Nombre'
            cc.Nombre AS CompraCategoria  -- Asume que TblComprasCategorias tiene 'Nombre'
        FROM dbo.TblCompras c (NOLOCK)
        INNER JOIN dbo.TblComprasTipos ct (NOLOCK) ON c.CompraTipoId = ct.CompraTipoId
        LEFT JOIN dbo.TblFilamentosTipos ft (NOLOCK) ON c.FilamentoTipoId = ft.FilamentoTipoId
        INNER JOIN dbo.TblComprasCategorias cc (NOLOCK) ON c.CompraCategoriaId = cc.CompraCategoriaId;

        IF (ISNULL(@elementoId, 0) = 0)
        BEGIN
            -- Retorna todos
            SELECT
                CompraId,
                Descripcion,
                CompraTipoId,
                FilamentoTipoId,
                CompraCategoriaId,
                CostoTotal,
                FechaCreacion,
                CompraTipo,
                FilamentoTipo,
                CompraCategoria
            FROM #TempData;
        END
        ELSE
        BEGIN
            -- Retorna por ID
            SELECT
                CompraId,
                Descripcion,
                CompraTipoId,
                FilamentoTipoId,
                CompraCategoriaId,
                CostoTotal,
                FechaCreacion,
                CompraTipo,
                FilamentoTipo,
                CompraCategoria
            FROM #TempData t
            WHERE t.CompraId = @elementoId;
        END
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

    DROP TABLE IF EXISTS #TempData;
ENDCREATE   PROCEDURE dbo.procObtenerCotizacionItems
@CotizacionId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
	BEGIN
		RAISERROR('Cotizacion no encontrada.',16,1);
	END

	SELECT
		i.CotizacionItemId,
		i.CotizacionId,
		i.ConceptoTipoId,
		ct.Nombre AS ConceptoTipo,
		i.ProductoId,
		p.Nombre AS ProductoNombre,
		i.Concepto,
		i.Cantidad,
		i.PrecioUnitario,
		i.Notas
	FROM dbo.TblCotizacionItems i (NOLOCK)
	INNER JOIN dbo.TblCotizacionConceptoTipos ct (NOLOCK)
		ON i.ConceptoTipoId = ct.ConceptoTipoId
	LEFT JOIN dbo.TblProductos p (NOLOCK)
		ON i.ProductoId = p.ProductoId
	WHERE i.CotizacionId = @CotizacionId
	AND i.EstaActivo = 1
	ORDER BY i.CotizacionItemId ASC;
END
GO

CREATE   PROCEDURE dbo.procObtenerCotizaciones
@ElementoObtenerId INT = 0,
@PedidoId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @elementoId INT = ISNULL(@ElementoObtenerId,0);

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	CREATE TABLE #TempData(
		CotizacionId INT,
		PedidoId INT,
		CotizacionEstatusId INT,
		CotizacionEstatus VARCHAR(100),
		FechaCreacion DATETIME,
		FechaVigencia DATETIME,
		Notas VARCHAR(MAX),
		TotalModelado DECIMAL(10,2),
		TotalProduccion DECIMAL(10,2),
		TotalCotizado DECIMAL(10,2),
		TotalPagado DECIMAL(10,2),
		Saldo DECIMAL(10,2)
	);

	INSERT INTO #TempData(
		CotizacionId, PedidoId, CotizacionEstatusId, CotizacionEstatus,
		FechaCreacion, FechaVigencia, Notas,
		TotalModelado, TotalProduccion, TotalCotizado, TotalPagado, Saldo
	)
	SELECT
		c.CotizacionId,
		c.PedidoId,
		c.CotizacionEstatusId,
		ce.Nombre,
		c.FechaCreacion,
		c.FechaVigencia,
		c.Notas,
		ISNULL(sums.TotalModelado,0),
		ISNULL(sums.TotalProduccion,0),
		ISNULL(sums.TotalCotizado,0),
		ISNULL(pagos.TotalPagado,0),
		ISNULL(sums.TotalCotizado,0) - ISNULL(pagos.TotalPagado,0)
	FROM dbo.TblCotizaciones c (NOLOCK)
	INNER JOIN dbo.TblCotizacionesEstatus ce (NOLOCK)
		ON c.CotizacionEstatusId = ce.CotizacionEstatusId
	OUTER APPLY (
		SELECT
			SUM(CASE WHEN i.ConceptoTipoId = 1 THEN i.Cantidad * i.PrecioUnitario ELSE 0 END) AS TotalModelado,
			SUM(CASE WHEN i.ConceptoTipoId = 2 THEN i.Cantidad * i.PrecioUnitario ELSE 0 END) AS TotalProduccion,
			SUM(i.Cantidad * i.PrecioUnitario) AS TotalCotizado
		FROM dbo.TblCotizacionItems i (NOLOCK)
		WHERE i.CotizacionId = c.CotizacionId
		AND i.EstaActivo = 1
	) sums
	OUTER APPLY (
		SELECT SUM(p.Monto) AS TotalPagado
		FROM dbo.TblPagos p (NOLOCK)
		WHERE p.CotizacionId = c.CotizacionId
		AND p.EstaActivo = 1
	) pagos
	WHERE c.EstaActivo = 1
	AND (@PedidoId = 0 OR c.PedidoId = @PedidoId);

	IF(@elementoId = 0)
	BEGIN
		SELECT * FROM #TempData ORDER BY CotizacionId DESC;
	END
	ELSE
	BEGIN
		SELECT * FROM #TempData WHERE CotizacionId = @elementoId;
	END

	DROP TABLE IF EXISTS #TempData;
END
GO

CREATE   PROCEDURE dbo.procObtenerImpresoras
    @loginId INT,
    @ElementoObtenerId INT = NULL,
    @SoloActivas BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
    BEGIN
        RAISERROR('Usuario no encontrado.', 16, 1);
        RETURN;
    END

    SELECT
        i.ImpresoraId,
        i.UsuarioId,
        i.Nombre,
        i.Modelo,
        i.Notas,
        i.EstaActivo,
        i.FechaCreacion,
        i.FechaActualizacion
    FROM dbo.TblImpresoras i (NOLOCK)
    WHERE i.UsuarioId = @loginId
      AND (@ElementoObtenerId IS NULL OR i.ImpresoraId = @ElementoObtenerId)
      AND (@SoloActivas = 0 OR i.EstaActivo = 1)
    ORDER BY i.EstaActivo DESC, i.Nombre ASC, i.ImpresoraId DESC;
END
GO

﻿/*
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
CREATE PROCEDURE dbo.procObtenerInventarios
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoObtenerId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #TempData(
			InventarioId INT,
			InventarioMarcaId INT,
			InventarioTipoId INT,
			InventarioNombreId INT,
			InventarioColorId INT,
			InventarioUnidadId INT,
			Cantidad DECIMAL(10,2),
			FechaCreacion DATETIME,
			InventarioMarca VARCHAR(200),
			InventarioTipo VARCHAR(200),
			InventarioNombre VARCHAR(200),
			InventarioNombreAbreviatura VARCHAR(200),
			InventarioColor VARCHAR(200),
			InventarioColorAbreviatura VARCHAR(200),
			InventarioUnidad VARCHAR(200)
		)


		INSERT INTO #TempData(
			InventarioId,
			InventarioMarcaId,
			InventarioTipoId,
			InventarioNombreId,
			InventarioColorId,
			InventarioUnidadId,
			Cantidad,
			FechaCreacion,
			InventarioMarca,
			InventarioTipo,
			InventarioNombre,
			InventarioNombreAbreviatura,
			InventarioColor,
			InventarioColorAbreviatura,
			InventarioUnidad
		)
		SELECT 
			i.InventarioId,
			i.InventarioMarcaId,
			i.InventarioTipoId,
			i.InventarioNombreId,
			i.InventarioColorId,
			i.InventarioUnidadId,
			i.Cantidad,
			i.FechaCreacion,
			im.Nombre,
			it.Nombre,
			ins.Nombre,
			ins.Abreviatura,
			ic.Nombre,
			ic.Abreviatura,
			iu.Nombre
		FROM dbo.TblInventarios i (NOLOCK)
		INNER JOIN dbo.TblInventariosColores ic (NOLOCK)
			ON i.InventarioColorId = ic.InventarioColorId
		INNER JOIN dbo.TblInventariosMarcas im (NOLOCK)
			ON i.InventarioMarcaId = im.InventarioMarcaId
		INNER JOIN dbo.TblInventariosNombres ins (NOLOCK)
			ON i.InventarioNombreId = ins.InventarioNombreId
		INNER JOIN dbo.TblInventariosTipos it (NOLOCK)
			ON i.InventarioTipoId = it.InventarioTipoId
		INNER JOIN dbo.TblInventariosUnidades iu (NOLOCK)
			ON i.InventarioUnidadId = iu.InventarioUnidadId
		WHERE i.EstaActivo = 1

		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				Cantidad,
				FechaCreacion,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				Cantidad,
				FechaCreacion,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad
			FROM #TempData t
			WHERE t.InventarioId = @elementoId
		END
	
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
	DROP TABLE IF EXISTS #TempData;
END﻿/*
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
CREATE PROCEDURE dbo.procObtenerMovimientosInventarios
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoObtenerId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #TempData(
			InventarioId INT,
			InventarioMarcaId INT,
			InventarioTipoId INT,
			InventarioNombreId INT,
			InventarioColorId INT,
			InventarioUnidadId INT,
			Cantidad DECIMAL(10,2),
			FechaCreacion DATETIME,
			InventarioMarca VARCHAR(200),
			InventarioTipo VARCHAR(200),
			InventarioNombre VARCHAR(200),
			InventarioNombreAbreviatura VARCHAR(200),
			InventarioColor VARCHAR(200),
			InventarioColorAbreviatura VARCHAR(200),
			InventarioUnidad VARCHAR(200),
			TipoMovimientoId INT,
			TipoMovimiento VARCHAR(200),
			CantidadTomada DECIMAL(10,2),
			Costo DECIMAL(10,2),
			FechaMovimiento DATETIME,
			UsuarioId INT
		)


		INSERT INTO #TempData(
			InventarioId,
			InventarioMarcaId,
			InventarioTipoId,
			InventarioNombreId,
			InventarioColorId,
			InventarioUnidadId,
			Cantidad,
			FechaCreacion,
			InventarioMarca,
			InventarioTipo,
			InventarioNombre,
			InventarioNombreAbreviatura,
			InventarioColor,
			InventarioColorAbreviatura,
			InventarioUnidad,
			TipoMovimientoId,
			TipoMovimiento,
			CantidadTomada,
			Costo,
			FechaMovimiento,
			UsuarioId
		)
		SELECT 
			i.InventarioId,
			i.InventarioMarcaId,
			i.InventarioTipoId,
			i.InventarioNombreId,
			i.InventarioColorId,
			i.InventarioUnidadId,
			i.Cantidad,
			i.FechaCreacion,
			im.Nombre,
			it.Nombre,
			ins.Nombre,
			ins.Abreviatura,
			ic.Nombre,
			ic.Abreviatura,
			iu.Nombre,
			imts.TipoMovimientoId,
			imtstps.Nombre,
			imts.Cantidad,
			imts.Costo,
			imts.FechaCreacion,
			imts.UsuarioId
		FROM dbo.TblInventariosMovimientos imts (NOLOCK)
		INNER JOIN dbo.TblInventariosMovimientoTipos imtstps (NOLOCK)
			ON imts.InventarioMovimientoId =  imtstps.TipoMovimientoId
		INNER JOIN dbo.TblInventarios i (NOLOCK)
			ON i.InventarioId = imts.InventarioId
		INNER JOIN dbo.TblInventariosColores ic (NOLOCK)
			ON i.InventarioColorId = ic.InventarioColorId
		INNER JOIN dbo.TblInventariosMarcas im (NOLOCK)
			ON i.InventarioMarcaId = im.InventarioMarcaId
		INNER JOIN dbo.TblInventariosNombres ins (NOLOCK)
			ON i.InventarioNombreId = ins.InventarioNombreId
		INNER JOIN dbo.TblInventariosTipos it (NOLOCK)
			ON i.InventarioTipoId = it.InventarioTipoId
		INNER JOIN dbo.TblInventariosUnidades iu (NOLOCK)
			ON i.InventarioUnidadId = iu.InventarioUnidadId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				Cantidad,
				FechaCreacion,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad,
				TipoMovimientoId,
				TipoMovimiento,
				CantidadTomada,
				Costo,
				FechaMovimiento,
				UsuarioId
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				Cantidad,
				FechaCreacion,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad,
				TipoMovimientoId,
				TipoMovimiento,
				CantidadTomada,
				Costo,
				FechaMovimiento,
				UsuarioId
			FROM #TempData t
			WHERE t.InventarioId = @elementoId
		END
	
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
	DROP TABLE IF EXISTS #TempData;
ENDCREATE   PROCEDURE dbo.procObtenerPagoTipos
AS
BEGIN
	SET NOCOUNT ON;
	SELECT PagoTipoId, Nombre FROM dbo.TblPagoTipos (NOLOCK) ORDER BY PagoTipoId ASC;
END
GO

CREATE   PROCEDURE dbo.procObtenerPagos
@CotizacionId INT = 0,
@ElementoObtenerId INT = 0,
@loginId INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @elementoId INT = ISNULL(@ElementoObtenerId,0);

	IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
	BEGIN
		RAISERROR('Usuario no encontrado.',16,1);
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.TblCotizaciones c (NOLOCK) WHERE c.CotizacionId = @CotizacionId AND c.EstaActivo = 1)
	BEGIN
		RAISERROR('Cotizacion no encontrada.',16,1);
	END

	IF(@elementoId = 0)
	BEGIN
		SELECT
			p.PagoId,
			p.CotizacionId,
			p.PagoTipoId,
			pt.Nombre AS PagoTipo,
			p.Monto,
			p.FechaPago,
			p.Metodo,
			p.Referencia,
			p.Notas
		FROM dbo.TblPagos p (NOLOCK)
		INNER JOIN dbo.TblPagoTipos pt (NOLOCK)
			ON p.PagoTipoId = pt.PagoTipoId
		WHERE p.CotizacionId = @CotizacionId
		AND p.EstaActivo = 1
		ORDER BY p.FechaPago DESC, p.PagoId DESC;
	END
	ELSE
	BEGIN
		SELECT
			p.PagoId,
			p.CotizacionId,
			p.PagoTipoId,
			pt.Nombre AS PagoTipo,
			p.Monto,
			p.FechaPago,
			p.Metodo,
			p.Referencia,
			p.Notas
		FROM dbo.TblPagos p (NOLOCK)
		INNER JOIN dbo.TblPagoTipos pt (NOLOCK)
			ON p.PagoTipoId = pt.PagoTipoId
		WHERE p.PagoId = @elementoId
		AND p.CotizacionId = @CotizacionId
		AND p.EstaActivo = 1;
	END
END
GO

CREATE   PROCEDURE dbo.procObtenerPedidoEstatus
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PedidoEstatusId, Nombre
    FROM dbo.TblPedidoEstatus
    ORDER BY PedidoEstatusId;
END
GO

CREATE   PROCEDURE dbo.procObtenerPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
    BEGIN
        SELECT TOP 0
            null as PedidoItemId,
            null as PedidoId,
            null as ProductoId,
            CAST(NULL AS NVARCHAR(200)) AS ProductoNombre,
            null as Cantidad,
            null as PrecioUnitarioEstimado,
            null as Notas;
        RETURN;
    END

    SELECT
        i.PedidoItemId,
        i.PedidoId,
        i.ProductoId,
        p.Nombre AS ProductoNombre,
        i.Cantidad,
        i.PrecioUnitarioEstimado,
        i.Notas
    FROM dbo.TblPedidoItems i
    INNER JOIN dbo.TblProductos p ON p.ProductoId = i.ProductoId
    WHERE i.PedidoId = @pedidoId
    AND i.EstaActivo = 1 
    ORDER BY i.PedidoItemId;
END
GO

CREATE   PROCEDURE dbo.procObtenerPedidos
    @loginId INT,
    @elementoObtenerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PedidoId,
        p.UsuarioId,
        p.ClienteId,
        c.Nombre AS ClienteNombre,
        p.PedidoEstatusId,
        e.Nombre AS EstatusNombre,
        p.FechaCreacion,
        p.FechaEntregaEstimada,
        p.Notas,
        p.TotalEstimado
    FROM dbo.TblPedidos p
    INNER JOIN dbo.TblClientes c ON c.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus e ON e.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.UsuarioId = @loginId
      AND (@elementoObtenerId IS NULL OR p.PedidoId = @elementoObtenerId)
      AND p.EstaActivo = 1 
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO

CREATE   PROCEDURE dbo.procObtenerPedidosKanban
    @loginId INT,
    @ClienteId INT = 0,
    @q VARCHAR(200) = '',
    @SoloPendientes BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AceptadaId INT = (
        SELECT TOP 1 CotizacionEstatusId
        FROM dbo.TblCotizacionesEstatus WITH (NOLOCK)
        WHERE Nombre = 'Aceptada'
    );

    ;WITH Cot AS (
        SELECT
            c.PedidoId,
            c.CotizacionId,
            c.CotizacionEstatusId,
            ce.Nombre AS CotizacionEstatusNombre,
            ROW_NUMBER() OVER (PARTITION BY c.PedidoId ORDER BY c.CotizacionId DESC) AS rn
        FROM dbo.TblCotizaciones c WITH (NOLOCK)
        INNER JOIN dbo.TblCotizacionesEstatus ce WITH (NOLOCK)
            ON ce.CotizacionEstatusId = c.CotizacionEstatusId
        WHERE ISNULL(c.EstaActivo, 1) = 1
    ),
    Cot1 AS (
        SELECT * FROM Cot WHERE rn = 1
    ),
    TotCot AS (
        SELECT
            ci.CotizacionId,
            SUM(ISNULL(ci.Cantidad,0) * ISNULL(ci.PrecioUnitario,0)) AS TotalCotizado
        FROM dbo.TblCotizacionItems ci WITH (NOLOCK)
        WHERE ISNULL(ci.EstaActivo, 1) = 1
        GROUP BY ci.CotizacionId
    ),
    TotPago AS (
        SELECT
            p.CotizacionId,
            SUM(ISNULL(p.Monto,0)) AS TotalPagado
        FROM dbo.TblPagos p WITH (NOLOCK)
        WHERE ISNULL(p.EstaActivo, 1) = 1
        GROUP BY p.CotizacionId
    )
    SELECT
        p.PedidoId,
        p.UsuarioId,
        p.ClienteId,
        c.Nombre AS ClienteNombre,
        p.PedidoEstatusId,
        e.Nombre AS EstatusNombre,
        p.FechaCreacion,
        p.FechaEntregaEstimada,
        p.Notas,
        p.TotalEstimado,

        ISNULL(c1.CotizacionId, 0) AS CotizacionId,
        ISNULL(c1.CotizacionEstatusNombre, '') AS CotizacionEstatusNombre,
        CASE WHEN c1.CotizacionId IS NULL THEN 0 ELSE 1 END AS TieneCotizacion,
        CASE WHEN c1.CotizacionEstatusId = @AceptadaId THEN 1 ELSE 0 END AS CotizacionAceptada,

        ISNULL(tc.TotalCotizado, 0) AS TotalCotizado,
        ISNULL(tp.TotalPagado, 0) AS TotalPagado,
        ISNULL(tc.TotalCotizado, 0) - ISNULL(tp.TotalPagado, 0) AS Saldo
    FROM dbo.TblPedidos p WITH (NOLOCK)
    INNER JOIN dbo.TblClientes c WITH (NOLOCK) ON c.ClienteId = p.ClienteId
    INNER JOIN dbo.TblPedidoEstatus e WITH (NOLOCK) ON e.PedidoEstatusId = p.PedidoEstatusId
    LEFT JOIN Cot1 c1 ON c1.PedidoId = p.PedidoId
    LEFT JOIN TotCot tc ON tc.CotizacionId = c1.CotizacionId
    LEFT JOIN TotPago tp ON tp.CotizacionId = c1.CotizacionId
    WHERE p.UsuarioId = @loginId
      AND (@ClienteId = 0 OR p.ClienteId = @ClienteId)
      AND (
            ISNULL(@q,'') = ''
            OR c.Nombre LIKE '%' + @q + '%'
            OR p.Notas LIKE '%' + @q + '%'
            OR CAST(p.PedidoId AS VARCHAR(20)) = @q
      )
      AND (
            @SoloPendientes = 0
            OR (ISNULL(tc.TotalCotizado,0) - ISNULL(tp.TotalPagado,0)) > 0
      )
      AND p.EstaActivo = 1 
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO

﻿/*
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
CREATE PROCEDURE dbo.procObtenerProductoRecetas
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoObtenerId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #TempData(
			ProductoId INT,
			RecetaId INT,
			NombreReceta VARCHAR(200),
			TiempoImpresion VARCHAR(200)
		)


		INSERT INTO #TempData(
			ProductoId,
			RecetaId,
			NombreReceta,
			TiempoImpresion
		)
		SELECT 
			p.ProductoId,
			r.RecetaId,
			r.Nombre,
			r.TiempoImpresion
		FROM dbo.TblProductos p (NOLOCK)
		INNER JOIN dbo.TblRecetas r(NOLOCK)
			ON p.ProductoId = r.ProductoId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				ProductoId,
				RecetaId,
				NombreReceta,
				TiempoImpresion
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				ProductoId,
				RecetaId,
				NombreReceta,
				TiempoImpresion
			FROM #TempData t
			WHERE t.ProductoId = @elementoId
		END
	
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
	DROP TABLE IF EXISTS #TempData;
ENDCREATE   PROCEDURE dbo.procObtenerProductos
@ElementoObtenerId INT = 0,
@loginId INT = 0,
@SoloActivos BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        SET @elementoId = ISNULL(@ElementoObtenerId,0);

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.Usuarios u (NOLOCK)
            WHERE u.Id = @loginId
        )
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        CREATE TABLE #TempData(
            ProductoId INT,
            Nombre VARCHAR(200),
            ProductoCategoriaId INT,
            ProductoCategoria VARCHAR(200),
            SKU VARCHAR(200),
            PrecioSugerido DECIMAL(18,2),
            EstaActivo BIT
        );

        INSERT INTO #TempData(
            ProductoId,
            Nombre,
            ProductoCategoriaId,
            ProductoCategoria,
            SKU,
            PrecioSugerido,
            EstaActivo
        )
        SELECT
            p.ProductoId,
            p.Nombre,
            p.ProductoCategoriaId,
            pc.Nombre,
            p.SKU,
            p.PrecioSugerido,
            p.EstaActivo
        FROM dbo.TblProductos p (NOLOCK)
        INNER JOIN dbo.TblProductosCategorias pc (NOLOCK)
            ON p.ProductoCategoriaId = pc.ProductoCategoriaId
        WHERE (@SoloActivos = 0 OR p.EstaActivo = 1);

        IF(ISNULL(@elementoId,0) = 0)
        BEGIN
            SELECT
                ProductoId,
                Nombre,
                ProductoCategoriaId,
                ProductoCategoria,
                SKU,
                PrecioSugerido,
                EstaActivo
            FROM #TempData
            ORDER BY Nombre;
        END
        ELSE
        BEGIN
            SELECT
                ProductoId,
                Nombre,
                ProductoCategoriaId,
                ProductoCategoria,
                SKU,
                PrecioSugerido,
                EstaActivo
            FROM #TempData t
            WHERE t.ProductoId = @elementoId;
        END
    END TRY
    BEGIN CATCH
        SELECT
            'fail' [result],
            CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.') [message],
            @elementoId [elementoId];
    END CATCH

    DROP TABLE IF EXISTS #TempData;
END
GO

﻿/*
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
CREATE PROCEDURE dbo.procObtenerRecetaInventario
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoObtenerId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #TempData(
			RecetaId INT,
			InventarioId INT,
			InventarioMarcaId INT,
			InventarioTipoId INT,
			InventarioNombreId INT,
			InventarioColorId INT,
			InventarioUnidadId INT,
			CantidadAsignada DECIMAL(10,2),
			InventarioMarca VARCHAR(200),
			InventarioTipo VARCHAR(200),
			InventarioNombre VARCHAR(200),
			InventarioNombreAbreviatura VARCHAR(200),
			InventarioColor VARCHAR(200),
			InventarioColorAbreviatura VARCHAR(200),
			InventarioUnidad VARCHAR(200)
		)


		INSERT INTO #TempData(
			RecetaId,
			InventarioId,
			InventarioMarcaId,
			InventarioTipoId,
			InventarioNombreId,
			InventarioColorId,
			InventarioUnidadId,
			CantidadAsignada,
			InventarioMarca,
			InventarioTipo,
			InventarioNombre,
			InventarioNombreAbreviatura,
			InventarioColor,
			InventarioColorAbreviatura,
			InventarioUnidad
		)
		SELECT 
			r.RecetaId,
			i.InventarioId,
			i.InventarioMarcaId,
			i.InventarioTipoId,
			i.InventarioNombreId,
			i.InventarioColorId,
			i.InventarioUnidadId,
			ri.Cantidad,
			im.Nombre,
			it.Nombre,
			ins.Nombre,
			ins.Abreviatura,
			ic.Nombre,
			ic.Abreviatura,
			iu.Nombre
		FROM dbo.TblRecetas r (NOLOCK)
		INNER JOIN dbo.TblRecetasInventarios ri (NOLOCK)
			ON ri.RecetaId = r.RecetaId
		INNER JOIN dbo.TblInventarios i (NOLOCK)
			ON ri.InventarioId = i.InventarioId
		INNER JOIN dbo.TblInventariosColores ic (NOLOCK)
			ON i.InventarioColorId = ic.InventarioColorId
		INNER JOIN dbo.TblInventariosMarcas im (NOLOCK)
			ON i.InventarioMarcaId = im.InventarioMarcaId
		INNER JOIN dbo.TblInventariosNombres ins (NOLOCK)
			ON i.InventarioNombreId = ins.InventarioNombreId
		INNER JOIN dbo.TblInventariosTipos it (NOLOCK)
			ON i.InventarioTipoId = it.InventarioTipoId
		INNER JOIN dbo.TblInventariosUnidades iu (NOLOCK)
			ON i.InventarioUnidadId = iu.InventarioUnidadId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				RecetaId,
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				CantidadAsignada,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				RecetaId,
				InventarioId,
				InventarioMarcaId,
				InventarioTipoId,
				InventarioNombreId,
				InventarioColorId,
				InventarioUnidadId,
				CantidadAsignada,
				InventarioMarca,
				InventarioTipo,
				InventarioNombre,
				InventarioNombreAbreviatura,
				InventarioColor,
				InventarioColorAbreviatura,
				InventarioUnidad
			FROM #TempData t
			WHERE t.RecetaId = @elementoId
		END
	
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
	DROP TABLE IF EXISTS #TempData;
END﻿/*
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
CREATE PROCEDURE dbo.procObtenerRecetas
@ElementoObtenerId INT = 0,
@loginId	INT = 0
AS
BEGIN 
	--
	SET NOCOUNT ON;
	--
	DECLARE @result VARCHAR(100) = '';
	DECLARE @message VARCHAR(MAX) = '';
	DECLARE @elementoId INT = 0;


	BEGIN TRY

		SET @elementoId = ISNULL(@ElementoObtenerId,0);

		IF NOT EXISTS(
			SELECT 1 
			FROM dbo.Usuarios u (NOLOCK)
			WHERE u.Id = @loginId
		)
		BEGIN
			SET @message = 'Usuario no encontrado.';
			RAISERROR(@message, 16, 1);
		END

		CREATE TABLE #TempData(
			RecetaId INT,
			Nombre VARCHAR(200),
			ProductoId INT,
			TiempoImpresion VARCHAR(200),
			ProductoNombre VARCHAR(200),
			ProductoCategoriaId INT,
			ProductoCategoria VARCHAR(200),
			ProductoSKU VARCHAR(200)
		)


		INSERT INTO #TempData(
			RecetaId,
			Nombre,
			ProductoId,
			TiempoImpresion,
			ProductoNombre,
			ProductoCategoriaId,
			ProductoCategoria,
			ProductoSKU
		)
		SELECT 
			r.RecetaId,
			r.Nombre,
			r.ProductoId,
			r.TiempoImpresion,
			p.Nombre,
			p.ProductoCategoriaId,
			pc.Nombre,
			p.SKU
		FROM dbo.TblRecetas r (NOLOCK)
		LEFT JOIN dbo.TblProductos p (NOLOCK)
			ON r.ProductoId = p.ProductoId
		LEFT JOIN dbo.TblProductosCategorias pc (NOLOCK)
			ON p.ProductoCategoriaId = pc.ProductoCategoriaId


		IF(ISNULL(@elementoId,0) = 0)
		BEGIN 
			SELECT 
				RecetaId,
				Nombre,
				ProductoId,
				TiempoImpresion,
				ProductoNombre,
				ProductoCategoriaId,
				ProductoCategoria,
				ProductoSKU
			FROM #TempData
		
		END
		ELSE 
		BEGIN 
			SELECT 
				RecetaId,
				Nombre,
				ProductoId,
				TiempoImpresion,
				ProductoNombre,
				ProductoCategoriaId,
				ProductoCategoria,
				ProductoSKU
			FROM #TempData t
			WHERE t.RecetaId = @elementoId
		END
	
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
	DROP TABLE IF EXISTS #TempData;
END
CREATE   PROCEDURE dbo.procPedidoAccionesDisponibles
@PedidoId INT = 0,
@loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId)
        BEGIN
            SET @message = 'Pedido no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        DECLARE @DesdeEstatusId INT = (SELECT p.PedidoEstatusId FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId);

        DECLARE @AprobadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Aprobado');
        DECLARE @CanceladoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Cancelado');
        DECLARE @EntregadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Entregado');

        DECLARE @CotizacionAceptadaId INT = (SELECT TOP 1 CotizacionEstatusId FROM dbo.TblCotizacionesEstatus (NOLOCK) WHERE Nombre='Aceptada');

        DECLARE @TieneCotizacionAceptada BIT = 0;

        IF(@CotizacionAceptadaId IS NOT NULL)
        BEGIN
            IF EXISTS(
                SELECT 1
                FROM dbo.TblCotizaciones c (NOLOCK)
                WHERE c.PedidoId = @PedidoId
                AND c.CotizacionEstatusId = @CotizacionAceptadaId
                AND ISNULL(c.EstaActivo,1) = 1
            )
            SET @TieneCotizacionAceptada = 1;
        END

        DECLARE @OrdPost INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Post-proceso' AND EstaActivo=1);
        DECLARE @OrdListo INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Listo para entrega' AND EstaActivo=1);
        DECLARE @OrdEnt INT = (SELECT TOP 1 Orden FROM dbo.TblProduccionEstatus (NOLOCK) WHERE Nombre=N'Entregado' AND EstaActivo=1);

        DECLARE @MinOrd INT =
        (
            SELECT MIN(pe.Orden)
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK) ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
            WHERE pr.PedidoId=@PedidoId AND pr.EstaActivo=1
        );

        /* Si no hay items de producción, bloqueamos avanzar a etapas finales */
        DECLARE @PuedePost BIT = IIF(@MinOrd IS NOT NULL AND @OrdPost IS NOT NULL AND @MinOrd >= @OrdPost, 1, 0);
        DECLARE @PuedeListo BIT = IIF(@MinOrd IS NOT NULL AND @OrdListo IS NOT NULL AND @MinOrd >= @OrdListo, 1, 0);
        DECLARE @PuedeEnt BIT = IIF(@MinOrd IS NOT NULL AND @OrdEnt IS NOT NULL AND @MinOrd >= @OrdEnt, 1, 0);
        DECLARE @PostProcesoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'Post-proceso');
        DECLARE @ListoEntregaId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'Listo para entrega');
        -- opcional, por si luego lo usas
        DECLARE @EnProduccionId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre = N'En producción');

        SELECT
            'mover' AS AccionCodigo,
            CONCAT('Mover a: ', eh.Nombre) AS AccionTexto,
            t.HaciaEstatusId,
            CAST(CASE WHEN t.HaciaEstatusId IN (@CanceladoId, @EntregadoId) THEN 1 ELSE 0 END AS BIT) AS RequiereConfirmacion,
            CAST(
                CASE
                    WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 1
                    WHEN @PostProcesoId IS NOT NULL AND t.HaciaEstatusId = @PostProcesoId AND @PuedePost = 0 THEN 1
                    WHEN @ListoEntregaId IS NOT NULL AND t.HaciaEstatusId = @ListoEntregaId AND @PuedeListo = 0 THEN 1
                    WHEN t.HaciaEstatusId = @EntregadoId AND @PuedeEnt = 0 THEN 1
                    ELSE 0
                END
            AS BIT) AS Bloqueada,
            CASE
                WHEN t.HaciaEstatusId = @AprobadoId AND @TieneCotizacionAceptada = 0 THEN 'Requiere una cotización en estatus Aceptada.'
                WHEN @PostProcesoId IS NOT NULL AND t.HaciaEstatusId = @PostProcesoId AND @PuedePost = 0 THEN 'Aún hay items que no están en Post-proceso (Producción).'
                WHEN @ListoEntregaId IS NOT NULL AND t.HaciaEstatusId = @ListoEntregaId AND @PuedeListo = 0 THEN 'Aún hay items que no están Listos para entrega (Producción).'
                WHEN t.HaciaEstatusId = @EntregadoId AND @PuedeEnt = 0 THEN 'Aún hay items que no están Entregados (Producción).'
                ELSE ''
            END AS Motivo
        FROM dbo.TblPedidosEstatusTransiciones t (NOLOCK)
        INNER JOIN dbo.TblPedidoEstatus eh (NOLOCK)
            ON t.HaciaEstatusId = eh.PedidoEstatusId
        WHERE t.DesdeEstatusId = @DesdeEstatusId
        ORDER BY eh.PedidoEstatusId ASC;


    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF(ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


CREATE   PROCEDURE dbo.procPedidoCambiarEstatus
@PedidoId INT = 0,
@HaciaEstatusId INT = 0,
@Notas VARCHAR(500) = '',
@loginId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = '';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = 0;

    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        BEGIN
            SET @message = 'Usuario no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId)
        BEGIN
            SET @message = 'Pedido no encontrado.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidoEstatus e (NOLOCK) WHERE e.PedidoEstatusId = @HaciaEstatusId)
        BEGIN
            SET @message = 'Estatus destino no existe.';
            RAISERROR(@message, 16, 1);
        END

        DECLARE @DesdeEstatusId INT = (SELECT p.PedidoEstatusId FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId = @PedidoId);

        IF(@DesdeEstatusId = @HaciaEstatusId)
        BEGIN
            SET @message = 'El pedido ya se encuentra en ese estatus.';
            RAISERROR(@message, 16, 1);
        END

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblPedidosEstatusTransiciones t (NOLOCK)
            WHERE t.DesdeEstatusId = @DesdeEstatusId
            AND t.HaciaEstatusId = @HaciaEstatusId
        )
        BEGIN
            SET @message = 'Transición no permitida.';
            RAISERROR(@message, 16, 1);
        END

        DECLARE @AprobadoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre='Aprobado');

        IF(@HaciaEstatusId = @AprobadoId)
        BEGIN
            DECLARE @CotizacionAceptadaId INT = (SELECT TOP 1 CotizacionEstatusId FROM dbo.TblCotizacionesEstatus (NOLOCK) WHERE Nombre='Aceptada');

            IF(@CotizacionAceptadaId IS NULL)
            BEGIN
                SET @message = 'No existe el estatus Aceptada en cotizaciones.';
                RAISERROR(@message, 16, 1);
            END

            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblCotizaciones c (NOLOCK)
                WHERE c.PedidoId = @PedidoId
                AND c.CotizacionEstatusId = @CotizacionAceptadaId
                AND ISNULL(c.EstaActivo,1) = 1
            )
            BEGIN
                SET @message = 'Para aprobar se requiere una cotización en estatus Aceptada.';
                RAISERROR(@message, 16, 1);
            END
        END

        DECLARE @EnProduccionPedidoId INT = (SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus (NOLOCK) WHERE Nombre=N'En producción');

        IF @EnProduccionPedidoId IS NOT NULL AND @HaciaEstatusId = @EnProduccionPedidoId
        BEGIN
            EXEC dbo.procProduccionInitPorPedido @PedidoId=@PedidoId, @loginId=@loginId;
        END

        UPDATE p
            SET p.PedidoEstatusId = @HaciaEstatusId
        FROM dbo.TblPedidos p
        WHERE p.PedidoId = @PedidoId;

        INSERT INTO dbo.TblPedidosBitacora(PedidoId, UsuarioId, DesdeEstatusId, HaciaEstatusId, Notas)
        VALUES(@PedidoId, @loginId, @DesdeEstatusId, @HaciaEstatusId, NULLIF(@Notas,''));

        SET @result = 'success';
        SET @message = 'Estatus actualizado';
        SET @elementoId = @PedidoId;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        IF(ISNULL(@message,'') = '')
            SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

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
          AND pr.UsuarioId=@loginId
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

CREATE   PROCEDURE dbo.procProduccionActualizarItemDatos
    @ProduccionItemId INT,
    @ImpresoraId INT = NULL,
    @NotasOperativas NVARCHAR(500) = NULL,
    @PesoEstimadoGr DECIMAL(10,2) = NULL,
    @PesoRealGr DECIMAL(10,2) = NULL,
    @FechaInicio DATETIME2(0) = NULL,
    @FechaFin DATETIME2(0) = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@ProduccionItemId, 0);

    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        -- El item debe pertenecer a un pedido del usuario
        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblPedidos ped (NOLOCK) ON ped.PedidoId = pr.PedidoId
            WHERE pr.ProduccionItemId = @ProduccionItemId
              AND ped.UsuarioId = @loginId
              AND ISNULL(pr.EstaActivo,1)=1
        )
            RAISERROR('Item de producción no encontrado.', 16, 1);

        -- Si mandan impresora, valida que exista, sea del usuario y esté activa
        IF @ImpresoraId IS NOT NULL
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ImpresoraId
                  AND i.UsuarioId = @loginId
                  AND i.EstaActivo = 1
            )
                RAISERROR('Impresora inválida o inactiva.', 16, 1);
        END

        UPDATE dbo.TblProduccionItems
           SET ImpresoraId     = @ImpresoraId,
               NotasOperativas = NULLIF(@NotasOperativas,''),
               PesoEstimadoGr  = @PesoEstimadoGr,
               PesoRealGr      = @PesoRealGr,
               FechaInicio     = @FechaInicio,
               FechaFin        = @FechaFin,
               FechaActualizacion = SYSDATETIME()
        WHERE ProduccionItemId = @ProduccionItemId;

        SET @message = 'Datos de producción guardados.';
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

CREATE   PROCEDURE dbo.procProduccionAsignarRecetaItem
    @ProduccionItemId INT,
    @RecetaId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20)='success';
    DECLARE @message VARCHAR(MAX)='Receta asignada.';
    DECLARE @elementoId INT = ISNULL(@ProduccionItemId,0);

    BEGIN TRY
        DECLARE @ProductoId INT;
        DECLARE @InvAplicado BIT;

        SELECT
            @ProductoId = pr.ProductoId,
            @InvAplicado = pr.InventarioAplicado
        FROM dbo.TblProduccionItems pr WITH (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.UsuarioId=@loginId
          AND pr.EstaActivo=1;

        IF @ProductoId IS NULL
            THROW 50000, 'Item de producción no encontrado.', 1;

        IF ISNULL(@InvAplicado,0)=1
            THROW 50000, 'No puedes cambiar receta: inventario ya aplicado (Post-procesado).', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblRecetas r WITH (NOLOCK)
            WHERE r.RecetaId=@RecetaId
              AND r.ProductoId=@ProductoId
              AND r.EstaActivo=1
        )
            THROW 50000, 'Receta inválida o no activa para este producto.', 1;

        UPDATE dbo.TblProduccionItems
           SET RecetaId = @RecetaId,
               FechaActualizacion = SYSDATETIME()
        WHERE ProduccionItemId=@ProduccionItemId;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result='fail';
        SET @message=CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

CREATE   PROCEDURE dbo.procProduccionCambiarEstatusItem
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


        /* =========================================================
        AUTO-AVANCE DEL ESTATUS DEL PEDIDO
        - Solo si el pedido ya está en el tramo de producción (5-8)
        - Avanza cuando TODOS los items alcanzaron el siguiente paso
        ========================================================= */

        DECLARE @MinOrdenProd INT;
        DECLARE @NombreEstatusProd NVARCHAR(100);
        DECLARE @NuevoPedidoEstatusId INT;

        -- 1) El “más atrasado” manda (si uno se queda atrás, el pedido no avanza)
        SELECT
            @MinOrdenProd = MIN(es.Orden)
        FROM dbo.TblProduccionItems pi WITH (NOLOCK)
        INNER JOIN dbo.TblProduccionEstatus es WITH (NOLOCK)
            ON es.ProduccionEstatusId = pi.ProduccionEstatusId
        AND es.EstaActivo = 1
        WHERE pi.PedidoId = @PedidoId
        AND pi.EstaActivo = 1;

        -- 2) Nombre del estatus de producción según ese orden
        SELECT TOP 1
            @NombreEstatusProd = es.Nombre
        FROM dbo.TblProduccionEstatus es WITH (NOLOCK)
        WHERE es.EstaActivo = 1
        AND es.Orden = @MinOrdenProd;

        -- 3) Buscar el PedidoEstatusId por el mismo nombre (tus nombres coinciden)
        SELECT TOP 1
            @NuevoPedidoEstatusId = pe.PedidoEstatusId
        FROM dbo.TblPedidoEstatus pe WITH (NOLOCK)
        WHERE pe.Nombre = @NombreEstatusProd;

        -- 4) Avanzar pedido SOLO si ya está en producción (5-8) y solo hacia adelante
        IF (@NuevoPedidoEstatusId IS NOT NULL)
        BEGIN
            UPDATE p
            SET p.PedidoEstatusId = @NuevoPedidoEstatusId
            FROM dbo.TblPedidos p WITH (UPDLOCK, HOLDLOCK)
            WHERE p.PedidoId = @PedidoId
            AND p.UsuarioId = @loginId
            AND p.PedidoEstatusId IN (5,6,7,8)      -- tramo producción
            AND p.PedidoEstatusId <> 9              -- no tocar cancelado
            AND p.PedidoEstatusId < @NuevoPedidoEstatusId;  -- solo avanza
        END


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

CREATE   PROCEDURE dbo.procProduccionInitPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result VARCHAR(20) = 'success';
    DECLARE @message VARCHAR(MAX) = 'Producción inicializada.';
    DECLARE @elementoId INT = @PedidoId;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            THROW 50000, 'Usuario no encontrado.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND p.UsuarioId=@loginId)
            THROW 50000, 'Pedido no encontrado.', 1;

        DECLARE @EnProdId INT =
            (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus (NOLOCK)
             WHERE EstaActivo=1 AND Nombre=N'En producción'
             ORDER BY Orden ASC);

        IF @EnProdId IS NULL
            SET @EnProdId = (SELECT TOP 1 ProduccionEstatusId FROM dbo.TblProduccionEstatus (NOLOCK) WHERE EstaActivo=1 ORDER BY Orden ASC);

        /* Inserta solo los faltantes */
        INSERT INTO dbo.TblProduccionItems (PedidoId, PedidoItemId, UsuarioId, ProductoId, Cantidad, ProduccionEstatusId)
        SELECT
            pi.PedidoId,
            pi.PedidoItemId,
            p.UsuarioId,
            pi.ProductoId,
            pi.Cantidad,
            @EnProdId
        FROM dbo.TblPedidoItems pi (NOLOCK)
        INNER JOIN dbo.TblPedidos p (NOLOCK) ON p.PedidoId = pi.PedidoId
        LEFT JOIN dbo.TblProduccionItems pr (NOLOCK) ON pr.PedidoItemId = pi.PedidoItemId
        WHERE pi.PedidoId = @PedidoId
          AND pr.ProduccionItemId IS NULL;

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO

CREATE   PROCEDURE dbo.procProduccionObtenerPorPedido
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
        RAISERROR('Usuario no encontrado.', 16, 1);

    IF NOT EXISTS(SELECT 1 FROM dbo.TblPedidos p (NOLOCK) WHERE p.PedidoId=@PedidoId AND p.UsuarioId=@loginId)
        RAISERROR('Pedido no encontrado.', 16, 1);

    SELECT
        pr.ProduccionItemId,
        pr.PedidoId,
        pr.PedidoItemId,
        pr.ProductoId,
        p.Nombre AS ProductoNombre,
        pi.Cantidad,

        pr.ProduccionEstatusId,
        pe.Nombre AS EstatusNombre,
        pe.BadgeClass,

        pr.Notas,
        pr.FechaCreacion,
        pr.FechaActualizacion,

        pr.ImpresoraId,
        imp.Nombre AS ImpresoraNombre,
        pr.NotasOperativas,
        pr.PesoEstimadoGr,
        pr.PesoRealGr,
        pr.FechaInicio,
        pr.FechaFin,
        pr.InventarioAplicado
    FROM dbo.TblProduccionItems pr (NOLOCK)
    INNER JOIN dbo.TblPedidoItems pi (NOLOCK)
        ON pi.PedidoItemId = pr.PedidoItemId
    INNER JOIN dbo.TblProductos p (NOLOCK)
        ON p.ProductoId = pr.ProductoId
    INNER JOIN dbo.TblProduccionEstatus pe (NOLOCK)
        ON pe.ProduccionEstatusId = pr.ProduccionEstatusId
    LEFT JOIN dbo.TblImpresoras imp (NOLOCK)
        ON imp.ImpresoraId = pr.ImpresoraId
       AND imp.UsuarioId = @loginId  -- seguridad
    WHERE pr.PedidoId = @PedidoId
      AND ISNULL(pr.EstaActivo,1) = 1
    ORDER BY pe.Orden ASC, pr.ProduccionItemId ASC;
END
GO

CREATE   PROCEDURE dbo.procProduccionRecetasDisponiblesPorItem
    @ProduccionItemId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.TblProduccionItems pr (NOLOCK)
        WHERE pr.ProduccionItemId=@ProduccionItemId
          AND pr.UsuarioId=@loginId
          AND pr.EstaActivo=1
    )
    BEGIN
        SELECT TOP 0
            0 AS RecetaId,
            '' AS Nombre,
            '' AS TiempoImpresion,
            CAST(0 AS BIT) AS IsSelected;
        RETURN;
    END

    DECLARE @ProductoId INT = (SELECT ProductoId FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);
    DECLARE @SelectedId INT = (SELECT RecetaId  FROM dbo.TblProduccionItems (NOLOCK) WHERE ProduccionItemId=@ProduccionItemId);

    SELECT
        r.RecetaId,
        r.Nombre,
        r.TiempoImpresion,
        CAST(CASE WHEN r.RecetaId = @SelectedId THEN 1 ELSE 0 END AS BIT) AS IsSelected
    FROM dbo.TblRecetas r (NOLOCK)
    WHERE r.ProductoId = @ProductoId
      AND r.EstaActivo = 1
    ORDER BY r.RecetaId DESC;
END
GO

/* =========================================================
   FASE 1: Motor de costos estimado por Receta (corregido)
   - MATERIAL_GR  (scope por InventarioTipoId / InventarioNombreId)
   - PRINT_HOUR   (scope por ImpresoraId o global)
   - POST_HOUR    (global)
   - MARGIN_PCT   (global)
   ========================================================= */
CREATE   PROCEDURE dbo.procRecetasCalcularCostoEstimado
    @RecetaId INT,
    @ImpresoraId INT = NULL,
    @loginId INT,
    @SoloResumen BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Validaciones */
    IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u WITH (NOLOCK) WHERE u.Id = @loginId)
    BEGIN
        SELECT 'error' AS result, 'Usuario no encontrado.' AS message;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.TblRecetas r WITH (NOLOCK) WHERE r.RecetaId = @RecetaId AND r.EstaActivo = 1)
    BEGIN
        SELECT 'error' AS result, 'Receta no encontrada o inactiva.' AS message;
        RETURN;
    END

    /* 2) Conceptos */
    DECLARE
        @ConceptoMaterialId INT,
        @ConceptoPrintId INT,
        @ConceptoPostId INT,
        @ConceptoMarginId INT;

    SELECT @ConceptoMaterialId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'MATERIAL_GR' AND EstaActivo = 1;

    SELECT @ConceptoPrintId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'PRINT_HOUR' AND EstaActivo = 1;

    SELECT @ConceptoPostId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'POST_HOUR' AND EstaActivo = 1;

    SELECT @ConceptoMarginId = TarifaConceptoId
    FROM dbo.TblTarifaConceptos WITH (NOLOCK)
    WHERE Codigo = 'MARGIN_PCT' AND EstaActivo = 1;

    IF @ConceptoMaterialId IS NULL
    BEGIN
        SELECT 'error' AS result, 'No existe el concepto MATERIAL_GR.' AS message;
        RETURN;
    END

    /* 3) Tiempos receta */
    DECLARE @TiempoImpresionMin INT = 0, @TiempoPostMin INT = 0;

    SELECT
        @TiempoImpresionMin = ISNULL(r.TiempoImpresionMin, 0),
        @TiempoPostMin      = ISNULL(r.TiempoPostMin, 0)
    FROM dbo.TblRecetas r WITH (NOLOCK)
    WHERE r.RecetaId = @RecetaId;

    /* 4) Material detalle (a temp table para reutilizar) */
    IF OBJECT_ID('tempdb..#MaterialDetalle') IS NOT NULL DROP TABLE #MaterialDetalle;

    SELECT
        ri.RecetaId,
        ri.InventarioId,
        CAST(ri.Cantidad AS DECIMAL(18,4)) AS Gramos,

        i.InventarioTipoId,
        it.Nombre AS InventarioTipoNombre,

        i.InventarioNombreId,
        inn.Nombre AS InventarioNombre,

        i.InventarioMarcaId,
        im.Nombre AS InventarioMarcaNombre,

        i.InventarioColorId,
        ic.Nombre AS InventarioColorNombre,

        i.InventarioUnidadId,
        iu.Nombre AS InventarioUnidadNombre,

        tar.Monto  AS CostoPorGramo,
        tar.Moneda AS Moneda,
        CAST(CASE WHEN tar.Monto IS NULL THEN 0 ELSE (ri.Cantidad * tar.Monto) END AS DECIMAL(18,4)) AS CostoLinea,
        CASE WHEN tar.Monto IS NULL THEN 1 ELSE 0 END AS FaltaTarifa
    INTO #MaterialDetalle
    FROM dbo.TblRecetasInventarios ri WITH (NOLOCK)
    INNER JOIN dbo.TblInventarios i WITH (NOLOCK)
        ON i.InventarioId = ri.InventarioId
    LEFT JOIN dbo.TblInventariosTipos it WITH (NOLOCK)
        ON it.InventarioTipoId = i.InventarioTipoId
    LEFT JOIN dbo.TblInventariosNombres inn WITH (NOLOCK)
        ON inn.InventarioNombreId = i.InventarioNombreId
    LEFT JOIN dbo.TblInventariosMarcas im WITH (NOLOCK)
        ON im.InventarioMarcaId = i.InventarioMarcaId
    LEFT JOIN dbo.TblInventariosColores ic WITH (NOLOCK)
        ON ic.InventarioColorId = i.InventarioColorId
    LEFT JOIN dbo.TblInventariosUnidades iu WITH (NOLOCK)
        ON iu.InventarioUnidadId = i.InventarioUnidadId
    OUTER APPLY (
        SELECT TOP(1) t.Monto, t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.UsuarioId = @loginId
          AND t.TarifaConceptoId = @ConceptoMaterialId
          AND t.EstaActivo = 1
          AND (t.InventarioTipoId IS NULL OR t.InventarioTipoId = i.InventarioTipoId)
          AND (t.InventarioNombreId IS NULL OR t.InventarioNombreId = i.InventarioNombreId)
        ORDER BY
          CASE WHEN t.InventarioNombreId = i.InventarioNombreId THEN 2 WHEN t.InventarioNombreId IS NULL THEN 1 ELSE 0 END DESC,
          CASE WHEN t.InventarioTipoId = i.InventarioTipoId THEN 2 WHEN t.InventarioTipoId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC
    ) tar
    WHERE ri.RecetaId = @RecetaId
      AND ri.EstaActivo = 1;

    DECLARE
        @TotalMaterial DECIMAL(18,4) = 0,
        @ItemsSinTarifa INT = 0,
        @MonedasDistintas INT = 0;

    SELECT
        @TotalMaterial = ISNULL(SUM(CostoLinea), 0),
        @ItemsSinTarifa = ISNULL(SUM(FaltaTarifa), 0),
        @MonedasDistintas = COUNT(DISTINCT ISNULL(Moneda,''))
    FROM #MaterialDetalle;

    /* 5) Tarifas de impresión/post/margen */
    DECLARE
        @PrintRate DECIMAL(18,4) = NULL, @PrintMoneda CHAR(3) = NULL,
        @PostRate  DECIMAL(18,4) = NULL, @PostMoneda  CHAR(3) = NULL,
        @MarginPct DECIMAL(18,4) = NULL;

    -- PRINT_HOUR (por impresora o global)
    IF @ConceptoPrintId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @PrintRate = t.Monto,
            @PrintMoneda = t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.UsuarioId = @loginId
          AND t.TarifaConceptoId = @ConceptoPrintId
          AND t.EstaActivo = 1
          AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY
          CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC;
    END

    -- POST_HOUR (global; si luego quieres override por impresora, ya tienes el campo)
    IF @ConceptoPostId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @PostRate = t.Monto,
            @PostMoneda = t.Moneda
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.UsuarioId = @loginId
          AND t.TarifaConceptoId = @ConceptoPostId
          AND t.EstaActivo = 1
          AND (t.ImpresoraId IS NULL OR t.ImpresoraId = @ImpresoraId)
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY
          CASE WHEN t.ImpresoraId = @ImpresoraId THEN 2 WHEN t.ImpresoraId IS NULL THEN 1 ELSE 0 END DESC,
          t.TarifaId DESC;
    END

    -- MARGIN_PCT (global)
    IF @ConceptoMarginId IS NOT NULL
    BEGIN
        SELECT TOP(1)
            @MarginPct = t.Monto
        FROM dbo.TblTarifas t WITH (NOLOCK)
        WHERE t.UsuarioId = @loginId
          AND t.TarifaConceptoId = @ConceptoMarginId
          AND t.EstaActivo = 1
          AND t.ImpresoraId IS NULL
          AND t.InventarioTipoId IS NULL
          AND t.InventarioNombreId IS NULL
        ORDER BY t.TarifaId DESC;
    END

    /* 6) Cálculos */
    DECLARE @CostoImpresion DECIMAL(18,4) =
        CASE WHEN @PrintRate IS NULL THEN 0
             ELSE CAST((@TiempoImpresionMin / 60.0) * @PrintRate AS DECIMAL(18,4)) END;

    DECLARE @CostoPost DECIMAL(18,4) =
        CASE WHEN @PostRate IS NULL THEN 0
             ELSE CAST((@TiempoPostMin / 60.0) * @PostRate AS DECIMAL(18,4)) END;

    DECLARE @CostoExtra DECIMAL(18,4) = 0;
    DECLARE @CostoTotal DECIMAL(18,4) = CAST(@TotalMaterial + @CostoImpresion + @CostoPost + @CostoExtra AS DECIMAL(18,4));

    DECLARE @MargenUsado DECIMAL(18,4) = ISNULL(@MarginPct, 0);

    DECLARE @PrecioSugerido DECIMAL(18,4) =
        CASE
          WHEN @MargenUsado >= 100 OR @MargenUsado < 0 THEN NULL
          ELSE CAST(@CostoTotal / (1 - (@MargenUsado / 100.0)) AS DECIMAL(18,4))
        END;

    DECLARE @MonedaFinal CHAR(3) = COALESCE(@PrintMoneda, @PostMoneda, (SELECT TOP 1 Moneda FROM #MaterialDetalle WHERE Moneda IS NOT NULL), 'MXN');

    DECLARE @Warnings NVARCHAR(500) = N'';
    IF @ItemsSinTarifa > 0 SET @Warnings += N'Faltan tarifas MATERIAL_GR para algunos insumos. ';
    IF @PrintRate IS NULL SET @Warnings += N'Falta tarifa PRINT_HOUR (global o por impresora). ';
    IF @PostRate IS NULL  SET @Warnings += N'Falta tarifa POST_HOUR. ';
    IF @MarginPct IS NULL SET @Warnings += N'Falta tarifa MARGIN_PCT (se usó 0%). ';
    IF @MonedasDistintas > 1 SET @Warnings += N'Hay más de una moneda en material. ';

    /* 7) Output */
    IF @SoloResumen = 0
    BEGIN
        SELECT *
        FROM #MaterialDetalle
        ORDER BY FaltaTarifa DESC, InventarioTipoId, InventarioId;
    END

    SELECT
        'success' AS result,
        'OK' AS message,
        @RecetaId AS RecetaId,
        @ImpresoraId AS ImpresoraId,
        @TiempoImpresionMin AS TiempoImpresionMin,
        @TiempoPostMin AS TiempoPostMin,
        @TotalMaterial AS CostoMaterial,
        @CostoImpresion AS CostoImpresion,
        @CostoPost AS CostoPost,
        @CostoExtra AS CostoExtra,
        @CostoTotal AS CostoTotal,
        @MargenUsado AS MargenPctUsado,
        @PrecioSugerido AS PrecioSugerido,
        @MonedaFinal AS Moneda,
        @ItemsSinTarifa AS ItemsSinTarifaMaterial,
        @Warnings AS Warnings;
END
GO

CREATE   PROCEDURE dbo.procReemplazarPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId AND UsuarioId = @loginId)
        RETURN;

    DELETE FROM dbo.TblPedidoItems WHERE PedidoId = @pedidoId;
END
GO

CREATE   PROCEDURE dbo.procReportesConsumoInventarioDetalle
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @InventarioId INT = NULL,
    @UsuarioId INT = NULL,
    @ProductoId INT = NULL,
    @RecetaId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- defaults: últimos 7 días
    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2)); -- inclusive día completo

    SELECT
        c.Fecha,
        c.PedidoId,
        c.PedidoItemId,
        c.ProduccionItemId,
        c.UsuarioId,

        c.ProductoId,
        c.CantidadItem,

        c.RecetaId,
        c.RecetaNombre,

        c.InventarioId,
        c.InsumoNombre,
        c.UnidadNombre,

        c.Cantidad,
        c.DisponibleAntes,
        c.DisponibleDespues,

        c.DesdeEstatusId,
        de.Nombre AS DesdeEstatusNombre,
        c.HaciaEstatusId,
        he.Nombre AS HaciaEstatusNombre,

        c.Notas
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionEstatus de WITH (NOLOCK) ON de.ProduccionEstatusId = c.DesdeEstatusId
    LEFT JOIN dbo.TblProduccionEstatus he WITH (NOLOCK) ON he.ProduccionEstatusId = c.HaciaEstatusId
    WHERE c.Fecha >= @DesdeDT
      AND c.Fecha <  @HastaDT
      AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
      AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
      AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
      AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
      AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    ORDER BY c.Fecha DESC, c.ProduccionInventarioConsumoId DESC;
END
GO

CREATE   PROCEDURE dbo.procReportesConsumoInventarioResumen
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @InventarioId INT = NULL,
    @UsuarioId INT = NULL,
    @ProductoId INT = NULL,
    @RecetaId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -7, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT
        COUNT(*) AS Movimientos,
        COUNT(DISTINCT PedidoId) AS Pedidos,
        COUNT(DISTINCT InventarioId) AS Insumos,
        SUM(Cantidad) AS TotalConsumido
    FROM Base;

    ;WITH Base AS
    (
        SELECT *
        FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        WHERE c.Fecha >= @DesdeDT
          AND c.Fecha <  @HastaDT
          AND (@PedidoId     IS NULL OR c.PedidoId     = @PedidoId)
          AND (@InventarioId IS NULL OR c.InventarioId = @InventarioId)
          AND (@UsuarioId    IS NULL OR c.UsuarioId    = @UsuarioId)
          AND (@ProductoId   IS NULL OR c.ProductoId   = @ProductoId)
          AND (@RecetaId     IS NULL OR c.RecetaId     = @RecetaId)
    )
    SELECT TOP 10
        InventarioId,
        MAX(InsumoNombre) AS InsumoNombre,
        MAX(UnidadNombre) AS UnidadNombre,
        SUM(Cantidad) AS Consumido,
        COUNT(*) AS Movimientos
    FROM Base
    GROUP BY InventarioId
    ORDER BY SUM(Cantidad) DESC;
END
GO

CREATE   PROCEDURE dbo.procReportesCosteoPedidoDetalle
    @PedidoId INT,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WITH (NOLOCK) WHERE PedidoId=@PedidoId AND UsuarioId=@loginId)
    BEGIN
        SELECT TOP 0 0 AS InventarioId, '' AS InsumoNombre, '' AS UnidadNombre, 0 AS Cantidad, 0 AS CostoUnitario, 0 AS CostoTotal;
        RETURN;
    END

    SELECT
        c.InventarioId,
        MAX(c.InsumoNombre) AS InsumoNombre,
        MAX(c.UnidadNombre) AS UnidadNombre,
        SUM(c.Cantidad) AS Cantidad,

        MAX(ISNULL(inv.CostoUnitario,0)) AS CostoUnitario,
        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoTotal
    FROM dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    WHERE c.PedidoId = @PedidoId
    GROUP BY c.InventarioId
    ORDER BY SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) DESC;
END
GO

CREATE   PROCEDURE dbo.procReportesCosteoPedidos
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @PedidoId INT = NULL,
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @FechaHasta IS NULL SET @FechaHasta = CONVERT(date, GETDATE());
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(day, -30, @FechaHasta);

    DECLARE @DesdeDT DATETIME2 = CAST(@FechaDesde AS DATETIME2);
    DECLARE @HastaDT DATETIME2 = DATEADD(day, 1, CAST(@FechaHasta AS DATETIME2));

    SELECT
        p.PedidoId,
        cli.Nombre ClienteNombre,
        p.TotalEstimado,

        SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0)) AS CostoReal,
        (ISNULL(p.TotalEstimado,0) - SUM(c.Cantidad * ISNULL(inv.CostoUnitario,0))) AS Diferencia,

        MIN(c.Fecha) AS PrimerConsumo,
        MAX(c.Fecha) AS UltimoConsumo
    FROM dbo.TblPedidos p WITH (NOLOCK)
    LEFT JOIN dbo.TblProduccionInventarioConsumo c WITH (NOLOCK)
        ON c.PedidoId = p.PedidoId
       AND c.Fecha >= @DesdeDT
       AND c.Fecha <  @HastaDT
    LEFT JOIN dbo.TblInventarios inv WITH (NOLOCK)
        ON inv.InventarioId = c.InventarioId
    LEFT JOIN dbo.TblClientes cli 
        ON cli.ClienteId = p.ClienteId
    WHERE p.UsuarioId = @loginId
      AND ISNULL(p.EstaActivo,1)=1
      AND (@PedidoId IS NULL OR p.PedidoId=@PedidoId)
    GROUP BY p.PedidoId, cli.Nombre, p.TotalEstimado
    ORDER BY p.PedidoId DESC;
END
GO

CREATE   PROCEDURE dbo.procReportesProduccionDashboard
    @loginId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Items por estatus de producción (del usuario dueño)
    SELECT
        e.ProduccionEstatusId,
        e.Nombre,
        e.Orden,
        COUNT(*) AS Items
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    INNER JOIN dbo.TblProduccionEstatus e WITH (NOLOCK)
        ON e.ProduccionEstatusId = i.ProduccionEstatusId
    WHERE i.UsuarioId = @loginId
      AND i.EstaActivo = 1
    GROUP BY e.ProduccionEstatusId, e.Nombre, e.Orden
    ORDER BY e.Orden;

    -- Pedidos por estatus (del usuario dueño)
    SELECT
        pe.PedidoEstatusId,
        pe.Nombre,
        COUNT(*) AS Pedidos
    FROM dbo.TblPedidos p WITH (NOLOCK)
    INNER JOIN dbo.TblPedidoEstatus pe WITH (NOLOCK)
        ON pe.PedidoEstatusId = p.PedidoEstatusId
    WHERE p.UsuarioId = @loginId
      AND ISNULL(p.EstaActivo,1)=1
    GROUP BY pe.PedidoEstatusId, pe.Nombre
    ORDER BY pe.PedidoEstatusId;

    -- WIP: items no entregados (toma el id de “Entregado” en producción)
    DECLARE @EntregadoProdId INT =
    (
        SELECT TOP 1 ProduccionEstatusId
        FROM dbo.TblProduccionEstatus WITH (NOLOCK)
        WHERE EstaActivo=1 AND Nombre LIKE N'Entreg%'
        ORDER BY Orden DESC
    );

    SELECT
        COUNT(*) AS ItemsTotales,
        SUM(CASE WHEN @EntregadoProdId IS NOT NULL AND i.ProduccionEstatusId <> @EntregadoProdId THEN 1 ELSE 0 END) AS ItemsWIP
    FROM dbo.TblProduccionItems i WITH (NOLOCK)
    WHERE i.UsuarioId=@loginId AND i.EstaActivo=1;
END
GO



/* =========================================================
   8) SP: DIAGNÓSTICO (SIN VIGENCIAS)
      - Solo devuelve conceptos que NO tienen tarifa global (sin scope)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasDiagnostico
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



/* =========================================================
   6) SP: ELIMINACIÓN LÓGICA + LOG
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasEliminar
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
   5) SP: OBTENER TARIFA (PRIORIDAD POR ESPECIFICIDAD)
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtener
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
   2) SP: LISTAR CONCEPTOS
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerConceptos
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
   7) SP: HISTÓRICO POR TARIFA
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerHistoricoPorTarifaId
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
   3) SP: LISTAR TARIFAS ACTIVAS DEL USUARIO
   ========================================================= */
CREATE   PROCEDURE dbo.procTarifasObtenerPorUsuario
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


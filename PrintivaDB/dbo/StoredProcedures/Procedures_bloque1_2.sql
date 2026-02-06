
/* =========================
   procBorrarPedido (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procBorrarPedido
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId)
    BEGIN
        UPDATE dbo.TblPedidoItems
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId;

        UPDATE dbo.TblPedidos
            SET EstaActivo = 0
        WHERE PedidoId = @pedidoId;
    END
END
GO


/* =========================
   procObtenerClientes (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerClientes
  @loginId INT,
  @elementoObtenerId INT = NULL,
  @SoloActivos BIT = 1
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
    FechaCreacion,
    EstaActivo,
    FechaActualizacion
  FROM dbo.TblClientes WITH (NOLOCK)
  WHERE (@elementoObtenerId IS NULL OR ClienteId = @elementoObtenerId)
    AND (@SoloActivos = 0 OR EstaActivo = 1)
  ORDER BY Nombre;
END
GO


/* =========================
   procObtenerImpresoras (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerImpresoras
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
    WHERE (@ElementoObtenerId IS NULL OR i.ImpresoraId = @ElementoObtenerId)
      AND (@SoloActivas = 0 OR i.EstaActivo = 1)
    ORDER BY i.EstaActivo DESC, i.Nombre ASC, i.ImpresoraId DESC;
END
GO


/* =========================
   procObtenerPedidoItems (SIN validación por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerPedidoItems
    @loginId INT,
    @pedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TblPedidos WHERE PedidoId = @pedidoId)
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


/* =========================
   procObtenerPedidos (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerPedidos
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
    WHERE (@elementoObtenerId IS NULL OR p.PedidoId = @elementoObtenerId)
      AND p.EstaActivo = 1
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO


/* =========================
   procObtenerPedidosKanban (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerPedidosKanban
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
    WHERE (@ClienteId = 0 OR p.ClienteId = @ClienteId)
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
      AND ISNULL(p.MostrarEnKanban, 1) = 1
    ORDER BY p.FechaCreacion DESC, p.PedidoId DESC;
END
GO


/* =========================
   procPedidoOcultarEnKanban (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procPedidoOcultarEnKanban
    @loginId  INT = 0,
    @PedidoId INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @result     VARCHAR(100) = '';
    DECLARE @message    VARCHAR(MAX) = '';
    DECLARE @elementoId INT = ISNULL(@PedidoId,0);

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios u (NOLOCK) WHERE u.Id = @loginId)
            RAISERROR('Usuario no encontrado.', 16, 1);

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblPedidos p (NOLOCK)
            WHERE p.PedidoId = @elementoId
              AND p.EstaActivo = 1
        )
            RAISERROR('Pedido no encontrado.', 16, 1);

        DECLARE @EntregadoId INT = (
            SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus WITH (NOLOCK) WHERE Nombre = 'Entregado'
        );
        DECLARE @CanceladoId INT = (
            SELECT TOP 1 PedidoEstatusId FROM dbo.TblPedidoEstatus WITH (NOLOCK) WHERE Nombre = 'Cancelado'
        );

        IF EXISTS (
            SELECT 1
            FROM dbo.TblPedidos p (NOLOCK)
            WHERE p.PedidoId = @elementoId
              AND p.PedidoEstatusId NOT IN (ISNULL(@EntregadoId,-1), ISNULL(@CanceladoId,-1))
        )
            RAISERROR('Solo puedes ocultar pedidos Entregados o Cancelados.', 16, 1);

        UPDATE dbo.TblPedidos
        SET MostrarEnKanban = 0
        WHERE PedidoId = @elementoId;

        SET @result = 'success';
        SET @message = 'Pedido ocultado del kanban';

        SELECT @result [result], @message [message], @elementoId [elementoId];
    END TRY
    BEGIN CATCH
        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(),'. Error Line: *', ERROR_LINE(), '*.');
        SELECT @result [result], @message [message], @elementoId [elementoId];
    END CATCH
END
GO


/* =========================
   procObtenerRecetaInventario (solo limpieza de emojis en comentarios)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procObtenerRecetaInventario
@ElementoObtenerId INT = 0,
@loginId INT = 0
AS
BEGIN 
    SET NOCOUNT ON;

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
        );

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
           AND ri.EstaActivo = 1  -- SOLO ACTIVOS
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
            ON i.InventarioUnidadId = iu.InventarioUnidadId;

        IF (ISNULL(@elementoId,0) = 0)
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
            FROM #TempData;
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
            WHERE t.RecetaId = @elementoId;
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
GO


/* =========================
   procProduccionAccionesDisponibles (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procProduccionAccionesDisponibles
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


/* =========================
   procProduccionActualizarItemDatos (SIN filtro por UsuarioId y sin emojis)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procProduccionActualizarItemDatos
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

        IF NOT EXISTS(
            SELECT 1
            FROM dbo.TblProduccionItems pr (NOLOCK)
            INNER JOIN dbo.TblPedidos ped (NOLOCK) ON ped.PedidoId = pr.PedidoId
            WHERE pr.ProduccionItemId = @ProduccionItemId
              AND ISNULL(pr.EstaActivo,1)=1
        )
            RAISERROR('Item de producción no encontrado.', 16, 1);

        IF @ImpresoraId IS NOT NULL
        BEGIN
            IF NOT EXISTS(
                SELECT 1
                FROM dbo.TblImpresoras i (NOLOCK)
                WHERE i.ImpresoraId = @ImpresoraId
                  AND i.EstaActivo = 1
            )
                RAISERROR('Impresora inválida o inactiva.', 16, 1);
        END

        DECLARE @Now DATETIME2(0) = CAST(SYSDATETIME() AS DATETIME2(0));

        DECLARE @EnProdId INT =
        (
            SELECT TOP 1 ProduccionEstatusId
            FROM dbo.TblProduccionEstatus (NOLOCK)
            WHERE EstaActivo=1 AND Nombre=N'En producción'
            ORDER BY Orden ASC
        );

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

        UPDATE pi
           SET ImpresoraId     = @ImpresoraId,
               NotasOperativas = NULLIF(@NotasOperativas,''),
               PesoEstimadoGr  = @PesoEstimadoGr,
               PesoRealGr      = @PesoRealGr,

               -- FECHAS: NO borres si vienen NULL
               -- y si está En producción y aún no hay inicio, arráncalo
               FechaInicio = CASE
                                WHEN @FechaInicio IS NOT NULL THEN @FechaInicio
                                WHEN pi.FechaInicio IS NULL AND @EnProdId IS NOT NULL AND pi.ProduccionEstatusId = @EnProdId THEN @Now
                                ELSE pi.FechaInicio
                            END,

               -- FECHA FIN: solo se setea si la mandan; o si está Post y no hay fin (fallback)
               FechaFin = CASE
                            WHEN @FechaFin IS NOT NULL THEN @FechaFin
                            WHEN pi.FechaFin IS NULL AND @PostId IS NOT NULL AND pi.ProduccionEstatusId = @PostId THEN @Now
                            ELSE pi.FechaFin
                         END,

               FechaActualizacion = SYSDATETIME()
        FROM dbo.TblProduccionItems pi
        WHERE pi.ProduccionItemId = @ProduccionItemId
          AND pi.EstaActivo = 1;

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


/* =========================
   procProduccionAsignarRecetaItem (SIN filtro por UsuarioId)
   ========================= */
CREATE OR ALTER PROCEDURE dbo.procProduccionAsignarRecetaItem
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


/* =========================
   procProduccionCambiarEstatusItem (SIN filtro por UsuarioId y sin emojis)
   ========================= */
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

    DECLARE @InventarioAplicadoAhora BIT = 0;

    BEGIN TRY
        IF (@HaciaEstatusId IS NULL OR @HaciaEstatusId <= 0)
            THROW 50000, 'Acción inválida: HaciaEstatusId vacío/0 (UI).', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TblProduccionItems pr WITH (NOLOCK)
            WHERE pr.ProduccionItemId=@ProduccionItemId
              AND pr.EstaActivo=1
        )
            THROW 50000, 'Item de producción no encontrado.', 1;

        BEGIN TRAN;

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

        DECLARE @Now DATETIME2(0) = CAST(SYSDATETIME() AS DATETIME2(0));

        -- IDs por proceso (tu tabla real)
        DECLARE @EnProdId INT =
        (
            SELECT TOP 1 ProduccionEstatusId
            FROM dbo.TblProduccionEstatus WITH (NOLOCK)
            WHERE EstaActivo=1 AND Nombre=N'En producción'
            ORDER BY Orden ASC
        );

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

            UPDATE i
               SET i.Cantidad = i.Cantidad - r.Requiere
            FROM dbo.TblInventarios i
            INNER JOIN @Req r ON r.InventarioId = i.InventarioId
            WHERE i.EstaActivo=1;

            INSERT INTO dbo.TblProduccionInventarioConsumo
            (
                ProduccionItemId,
                RecetaId,
                InventarioId,
                Cantidad,
                InventarioUnidadId,
                UsuarioId,
                Fecha,
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

            UPDATE dbo.TblProduccionItems
               SET InventarioAplicado = 1,
                   FechaActualizacion = SYSDATETIME()
            WHERE ProduccionItemId=@ProduccionItemId;

            SET @InventarioAplicadoAhora = 1;
        END

        UPDATE dbo.TblProduccionItems
           SET ProduccionEstatusId = @HaciaEstatusId,
               Notas = NULLIF(@Notas,''),
               FechaActualizacion = SYSDATETIME(),

               -- si entra a En producción y no hay inicio → arranca
               FechaInicio = CASE
                                WHEN @EnProdId IS NOT NULL
                                     AND @HaciaEstatusId = @EnProdId
                                     AND FechaInicio IS NULL
                                THEN @Now
                                ELSE FechaInicio
                            END,

               -- si sale de En producción hacia Post (fin de impresión) y no hay fin → cierra
               FechaFin = CASE
                            WHEN @EnProdId IS NOT NULL AND @PostId IS NOT NULL
                                 AND @DesdeId = @EnProdId
                                 AND @HaciaEstatusId = @PostId
                                 AND FechaFin IS NULL
                            THEN @Now
                            ELSE FechaFin
                         END
        WHERE ProduccionItemId=@ProduccionItemId;

        INSERT INTO dbo.TblProduccionBitacora
            (ProduccionItemId, PedidoId, PedidoItemId, UsuarioId, DesdeEstatusId, HaciaEstatusId, Notas)
        VALUES
            (@ProduccionItemId, @PedidoId, @PedidoItemId, @loginId, @DesdeId, @HaciaEstatusId, NULLIF(@Notas,''));

        DECLARE @MinOrdenProd INT;
        DECLARE @NombreEstatusProd NVARCHAR(100);
        DECLARE @NuevoPedidoEstatusId INT;

        SELECT @MinOrdenProd = MIN(es.Orden)
        FROM dbo.TblProduccionItems pi WITH (NOLOCK)
        INNER JOIN dbo.TblProduccionEstatus es WITH (NOLOCK)
            ON es.ProduccionEstatusId = pi.ProduccionEstatusId
        AND es.EstaActivo = 1
        WHERE pi.PedidoId = @PedidoId
          AND pi.EstaActivo = 1;

        SELECT TOP 1 @NombreEstatusProd = es.Nombre
        FROM dbo.TblProduccionEstatus es WITH (NOLOCK)
        WHERE es.EstaActivo = 1
          AND es.Orden = @MinOrdenProd;

        SELECT TOP 1 @NuevoPedidoEstatusId = pe.PedidoEstatusId
        FROM dbo.TblPedidoEstatus pe WITH (NOLOCK)
        WHERE pe.Nombre = @NombreEstatusProd;

        IF (@NuevoPedidoEstatusId IS NOT NULL)
        BEGIN
            UPDATE p
            SET p.PedidoEstatusId = @NuevoPedidoEstatusId
            FROM dbo.TblPedidos p WITH (UPDLOCK, HOLDLOCK)
            WHERE p.PedidoId = @PedidoId
              AND p.PedidoEstatusId IN (5,6,7,8)
              AND p.PedidoEstatusId <> 9
              AND p.PedidoEstatusId < @NuevoPedidoEstatusId;
        END

        COMMIT;

        SELECT
            @result [result],
            @message [message],
            @elementoId [elementoId],
            @DesdeId [desdeEstatusId],
            @HaciaEstatusId [haciaEstatusId],
            @InventarioAplicadoAhora [inventarioAplicadoAhora];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @result = 'fail';
        SET @message = CONCAT(ERROR_MESSAGE(), '. Error Line: *', ERROR_LINE(), '*.');

        SELECT
            @result [result],
            @message [message],
            @elementoId [elementoId],
            NULL [desdeEstatusId],
            @HaciaEstatusId [haciaEstatusId],
            0 [inventarioAplicadoAhora];
    END CATCH
END
GO
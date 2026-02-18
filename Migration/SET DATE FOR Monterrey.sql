/* =========================================================
   PARCHE: Normalizar DEFAULTs de fechas a UTC
   - No cambia tipos
   - No cambia valores existentes
   - Solo re-crea DEFAULT constraints en columnas auditables
   ========================================================= */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    DECLARE @Targets TABLE(
        SchemaName sysname NOT NULL,
        TableName  sysname NOT NULL,
        ColumnName sysname NOT NULL,
        DefaultSql nvarchar(4000) NOT NULL,
        NewConstraintName sysname NOT NULL
    );

    /* ==== Ajusta aquí si agregas más columnas auditables ==== */
    INSERT INTO @Targets(SchemaName, TableName, ColumnName, DefaultSql, NewConstraintName)
    VALUES
      -- datetime2 -> SYSUTCDATETIME()
      ('dbo','TblClientes','FechaCreacion','SYSUTCDATETIME()','DF_TblClientes_FechaCreacion_UTC'),
      ('dbo','TblImpresoras','FechaCreacion','SYSUTCDATETIME()','DF_TblImpresoras_FechaCreacion_UTC'),
      ('dbo','TblPedidos','FechaCreacion','SYSUTCDATETIME()','DF_TblPedidos_FechaCreacion_UTC'),
      ('dbo','TblProduccionCosteos','Fecha','SYSUTCDATETIME()','DF_TblProduccionCosteos_Fecha_UTC'),
      ('dbo','TblProduccionCosteosDetalle','Fecha','SYSUTCDATETIME()','DF_TblProduccionCosteosDetalle_Fecha_UTC'),
      ('dbo','TblProduccionInventarioConsumo','Fecha','SYSUTCDATETIME()','DF_TblProduccionInvConsumo_Fecha_UTC'),
      ('dbo','TblTarifaConceptos','FechaCreacion','SYSUTCDATETIME()','DF_TblTarifaConceptos_FechaCreacion_UTC'),
      ('dbo','TblTarifas','FechaCreacion','SYSUTCDATETIME()','DF_TblTarifas_FechaCreacion_UTC'),
      ('dbo','TblTarifasLog','FechaAccion','SYSUTCDATETIME()','DF_TblTarifasLog_FechaAccion_UTC'),
      ('dbo','TblTransaccionesCompras','FechaLog','SYSUTCDATETIME()','DF_TblTransaccionesCompras_FechaLog_UTC'),

      -- datetime -> GETUTCDATE()
      ('dbo','TblPagos','FechaCreacion','GETUTCDATE()','DF_TblPagos_FechaCreacion_UTC'),
      ('dbo','TblPedidosBitacora','FechaMovimiento','GETUTCDATE()','DF_TblPedidosBitacora_FechaMovimiento_UTC'),
      ('dbo','TblProduccionBitacora','Fecha','GETUTCDATE()','DF_TblProduccionBitacora_Fecha_UTC'),
      ('dbo','TblProduccionItems','FechaCreacion','GETUTCDATE()','DF_TblProduccionItems_FechaCreacion_UTC');

    DECLARE
        @SchemaName sysname,
        @TableName sysname,
        @ColumnName sysname,
        @DefaultSql nvarchar(4000),
        @NewConstraintName sysname,
        @ExistingConstraintName sysname,
        @Sql nvarchar(max);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT SchemaName, TableName, ColumnName, DefaultSql, NewConstraintName
        FROM @Targets;

    OPEN cur;
    FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ColumnName, @DefaultSql, @NewConstraintName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verifica que exista tabla y columna
        IF EXISTS (
            SELECT 1
            FROM sys.tables t
            JOIN sys.schemas s ON s.schema_id = t.schema_id
            JOIN sys.columns c ON c.object_id = t.object_id
            WHERE s.name = @SchemaName
              AND t.name = @TableName
              AND c.name = @ColumnName
        )
        BEGIN
            -- Busca el default constraint actual (si existe)
            SELECT @ExistingConstraintName = dc.name
            FROM sys.default_constraints dc
            JOIN sys.tables t ON t.object_id = dc.parent_object_id
            JOIN sys.schemas s ON s.schema_id = t.schema_id
            JOIN sys.columns c ON c.object_id = t.object_id AND c.column_id = dc.parent_column_id
            WHERE s.name = @SchemaName
              AND t.name = @TableName
              AND c.name = @ColumnName;

            -- Drop del constraint actual (si existe)
            IF @ExistingConstraintName IS NOT NULL
            BEGIN
                SET @Sql = N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) +
                           N' DROP CONSTRAINT ' + QUOTENAME(@ExistingConstraintName) + N';';
                EXEC sp_executesql @Sql;
            END

            -- Si por alguna razón ya existe el nombre nuevo, lo dropeamos para recrear limpio
            IF EXISTS (
                SELECT 1
                FROM sys.default_constraints dc
                JOIN sys.tables t ON t.object_id = dc.parent_object_id
                JOIN sys.schemas s ON s.schema_id = t.schema_id
                WHERE s.name = @SchemaName
                  AND t.name = @TableName
                  AND dc.name = @NewConstraintName
            )
            BEGIN
                SET @Sql = N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) +
                           N' DROP CONSTRAINT ' + QUOTENAME(@NewConstraintName) + N';';
                EXEC sp_executesql @Sql;
            END

            -- Crea el nuevo default UTC
            SET @Sql = N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) +
                       N' ADD CONSTRAINT ' + QUOTENAME(@NewConstraintName) +
                       N' DEFAULT (' + @DefaultSql + N') FOR ' + QUOTENAME(@ColumnName) + N';';

            EXEC sp_executesql @Sql;
        END
        -- else: si no existe, no hace nada (parche seguro)

        FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ColumnName, @DefaultSql, @NewConstraintName;
    END

    CLOSE cur;
    DEALLOCATE cur;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
END CATCH;
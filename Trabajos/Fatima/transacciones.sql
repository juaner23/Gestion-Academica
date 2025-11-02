USE GestionAcademicaNueva;
GO

-- Generar intereses por mora para cuotas vencidas
CREATE OR ALTER PROCEDURE creacion.sp_GenerarInteresesPorMora
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_estudiante INT;
    DECLARE @id_factura INT;
    DECLARE @fecha_vencimiento DATE;
    DECLARE @dias_vencido INT;
    DECLARE @monto_factura DECIMAL(10,2);
    DECLARE @porcentaje_interes DECIMAL(5,2);
    DECLARE @monto_interes DECIMAL(10,2);
    DECLARE @anio_carrera INT;
    DECLARE @descripcion NVARCHAR(200);
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE facturas_cursor CURSOR FOR
        SELECT f.id_factura, f.id_estudiante, f.total, f.fecha
        FROM creacion.factura f
        WHERE DATEDIFF(DAY, f.fecha, GETDATE()) > 30
        AND f.total > 0;
        
        OPEN facturas_cursor;
        FETCH NEXT FROM facturas_cursor INTO @id_factura, @id_estudiante, @monto_factura, @fecha_vencimiento;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @dias_vencido = DATEDIFF(DAY, @fecha_vencimiento, GETDATE());
            
            IF @dias_vencido > 30
            BEGIN
                SELECT TOP 1 @anio_carrera = c.anio
                FROM creacion.inscripcion i
                INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
                INNER JOIN creacion.curso c ON m.id_curso = c.id_curso
                WHERE i.id_estudiante = @id_estudiante
                ORDER BY c.anio DESC;
                
                SET @porcentaje_interes = ISNULL(@anio_carrera * 2.0, 5.0);
                SET @monto_interes = (@monto_factura * @porcentaje_interes / 100.0) * (@dias_vencido / 30.0);
                SET @descripcion = 'Interés por mora - ' + CAST(@dias_vencido AS NVARCHAR) + ' días vencidos';
                
                INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto)
                VALUES (@id_estudiante, GETDATE(), @descripcion, @monto_interes);
                
                UPDATE creacion.factura
                SET total = total + @monto_interes
                WHERE id_factura = @id_factura;
            END
            
            FETCH NEXT FROM facturas_cursor INTO @id_factura, @id_estudiante, @monto_factura, @fecha_vencimiento;
        END
        
        CLOSE facturas_cursor;
        DEALLOCATE facturas_cursor;
        
        COMMIT TRANSACTION;
        PRINT 'Intereses por mora generados correctamente.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF CURSOR_STATUS('global', 'facturas_cursor') >= 0
        BEGIN
            CLOSE facturas_cursor;
            DEALLOCATE facturas_cursor;
        END
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error al generar intereses por mora: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

-- Emitir factura agrupando cuotas impagas del mes
CREATE OR ALTER PROCEDURE creacion.sp_EmitirFacturaCuotasImpagas
    @id_estudiante INT,
    @mes INT = NULL,
    @anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @monto_total DECIMAL(10,2) = 0;
    DECLARE @id_factura INT;
    DECLARE @descripcion NVARCHAR(200);
    
    IF @mes IS NULL
        SET @mes = MONTH(GETDATE());
    
    IF @anio IS NULL
        SET @anio = YEAR(GETDATE());
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50020, 'Error: El estudiante no existe.', 1;
        END
        
        SELECT @monto_total = ISNULL(SUM(total), 0)
        FROM creacion.factura
        WHERE id_estudiante = @id_estudiante
        AND MONTH(fecha) = @mes
        AND YEAR(fecha) = @anio
        AND total > 0;
        
        IF @monto_total > 0
        BEGIN
            SET @descripcion = 'Factura cuotas impagas - Mes ' + CAST(@mes AS NVARCHAR) + '/' + CAST(@anio AS NVARCHAR);
            
            INSERT INTO creacion.factura (id_estudiante, fecha, total)
            VALUES (@id_estudiante, GETDATE(), @monto_total);
            
            SET @id_factura = SCOPE_IDENTITY();
            
            INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto)
            VALUES (@id_estudiante, GETDATE(), @descripcion, @monto_total);
            
            COMMIT TRANSACTION;
            PRINT 'Factura emitida correctamente. Monto total: ' + CAST(@monto_total AS NVARCHAR);
        END
        ELSE
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'No hay cuotas impagas para el período especificado.';
        END
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error al emitir factura: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

-- Reinscribir estudiante dado de baja y actualizar estado
CREATE OR ALTER PROCEDURE creacion.sp_ReinscribirEstudiante
    @id_estudiante INT,
    @id_materia INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @mensaje NVARCHAR(500);
    DECLARE @id_curso INT;
    DECLARE @sql NVARCHAR(500);
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante no existe.';
            THROW 50030, @mensaje, 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM creacion.materia WHERE id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: La materia no existe.';
            THROW 50031, @mensaje, 1;
        END
        
        IF EXISTS (SELECT 1 FROM sys.columns 
                   WHERE object_id = OBJECT_ID('creacion.estudiante') 
                   AND name = 'estado_baja')
        BEGIN
            SET @sql = 'UPDATE creacion.estudiante SET estado_baja = 0 WHERE id_estudiante = ' + CAST(@id_estudiante AS NVARCHAR(10));
            EXEC sp_executesql @sql;
        END
        
        SELECT @id_curso = id_curso FROM creacion.materia WHERE id_materia = @id_materia;
        
        IF EXISTS (SELECT 1 FROM creacion.curso 
                   WHERE id_curso = @id_curso 
                   AND cupo_ocupado >= cupo_maximo)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: No hay cupo disponible en el curso.';
            THROW 50032, @mensaje, 1;
        END
        
        IF EXISTS (SELECT 1 FROM creacion.inscripcion 
                   WHERE id_estudiante = @id_estudiante 
                   AND id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante ya está inscripto en esta materia.';
            THROW 50033, @mensaje, 1;
        END
        
        INSERT INTO creacion.inscripcion (id_estudiante, id_materia, fecha_inscripcion)
        VALUES (@id_estudiante, @id_materia, GETDATE());
        
        UPDATE creacion.curso
        SET cupo_ocupado = cupo_ocupado + 1
        WHERE id_curso = @id_curso;
        
        COMMIT TRANSACTION;
        
        SET @mensaje = 'Estudiante reinscrito exitosamente.';
        PRINT @mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

PRINT 'Transacciones desde procedimientos almacenados creadas correctamente.';
GO


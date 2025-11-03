USE GestionAcademicaNueva;
GO
DROP PROCEDURE IF EXISTS creacion.sp_GenerarInteresesMora;
DROP PROCEDURE IF EXISTS creacion.sp_EmitirFacturaAgrupada;
DROP PROCEDURE IF EXISTS creacion.sp_ReinscribirEstudiante;
GO
-- Generar intereses por mora para cuotas vencidas y actualizar cuenta corriente.
CREATE PROCEDURE creacion.sp_GenerarInteresesMora
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @porcentaje DECIMAL(5,2) = (SELECT TOP 1 porcentaje_interes FROM creacion.interes_por_mora);
        UPDATE creacion.cuota
        SET monto = monto * (1 + @porcentaje / 100)
        WHERE fecha_vencimiento < GETDATE() AND estado_pago = 'Pendiente';
        INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
        SELECT id_estudiante, GETDATE(), 'Interés por mora', -(monto * @porcentaje / 100), 'Interés', 'Pendiente'
        FROM creacion.cuota
        WHERE fecha_vencimiento < GETDATE() AND estado_pago = 'Pendiente';
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Emitir factura agrupando todas las cuotas impagas del mes.
CREATE PROCEDURE creacion.sp_EmitirFacturaAgrupada
    @id_estudiante INT,
    @mes INT,
    @anio INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        
        DECLARE @monto_total DECIMAL(10,2) = (SELECT SUM(monto) FROM creacion.cuota WHERE id_estudiante = @id_estudiante AND mes = @mes AND estado_pago = 'Pendiente');
        INSERT INTO creacion.factura (id_estudiante, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
        VALUES (@id_estudiante, @mes, @anio, GETDATE(), DATEADD(DAY, 30, GETDATE()), @monto_total, 'Pendiente');
        DECLARE @id_factura INT = SCOPE_IDENTITY();
        
        UPDATE creacion.cuota SET id_factura = @id_factura WHERE id_estudiante = @id_estudiante AND mes = @mes AND estado_pago = 'Pendiente';
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Reinscribir a un estudiante dado de baja y actualizar su estado
CREATE PROCEDURE creacion.sp_ReinscribirEstudiante
    @id_estudiante INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante AND estado_baja = 1)
            RAISERROR('El estudiante no está dado de baja.', 16, 1);
        UPDATE creacion.estudiante SET estado_baja = 0 WHERE id_estudiante = @id_estudiante;
        INSERT INTO creacion.matriculacion (id_estudiante, anio, fecha_pago, monto, estado_pago)
        VALUES (@id_estudiante, YEAR(GETDATE()), GETDATE(), 0, 'Pagada');
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
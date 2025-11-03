USE GestionAcademicaNueva;
GO

-- ===============================
-- PROCEDIMIENTO: Registrar inscripción y item de factura
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_RegistrarInscripcionYItemFactura;
GO

CREATE PROCEDURE creacion.sp_RegistrarInscripcionYItemFactura
@id_estudiante INT,
@id_curso INT,
@id_factura INT
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
INSERT INTO creacion.inscripcion (id_estudiante, id_curso, fecha_inscripcion)
VALUES (@id_estudiante, @id_curso, GETDATE());

    INSERT INTO creacion.itemfactura (id_factura, id_curso)
    VALUES (@id_factura, @id_curso);

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    THROW;
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Generar cuotas y facturas mensuales
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_GenerarCuotasYFacturasMensuales;
GO

CREATE PROCEDURE creacion.sp_GenerarCuotasYFacturasMensuales
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
DECLARE @id_estudiante INT;

    DECLARE cursorEstudiantes CURSOR FOR
        SELECT id_estudiante FROM creacion.estudiante;

    OPEN cursorEstudiantes;
    FETCH NEXT FROM cursorEstudiantes INTO @id_estudiante;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insertar cuota mensual (ejemplo 1000)
        INSERT INTO creacion.CuentaCorriente (id_estudiante, monto, fecha, descripcion, concepto, estado)
        VALUES (@id_estudiante, 1000, GETDATE(), 'Cuota mensual', 'Mensualidad', 'Pendiente');

        -- Crear factura
        INSERT INTO creacion.factura (id_estudiante, fecha_emision, total, estado_pago)
        VALUES (@id_estudiante, GETDATE(), 1000, 'Pendiente');

        PRINT 'Cuota y factura registradas para estudiante ID ' + CAST(@id_estudiante AS VARCHAR);

        FETCH NEXT FROM cursorEstudiantes INTO @id_estudiante;
    END

    CLOSE cursorEstudiantes;
    DEALLOCATE cursorEstudiantes;

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Dar de baja estudiante si saldo es cero
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_BajaEstudianteSiSaldoCero;
GO

CREATE PROCEDURE creacion.sp_BajaEstudianteSiSaldoCero
@id_estudiante INT
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
DECLARE @saldo DECIMAL(10,2);

    SELECT @saldo = ISNULL(SUM(monto),0)
    FROM creacion.CuentaCorriente
    WHERE id_estudiante = @id_estudiante;

    IF @saldo = 0
    BEGIN
        -- No existe columna estado_baja, se deja ejemplo comentado
        -- UPDATE creacion.estudiante SET estado_baja = 1 WHERE id_estudiante = @id_estudiante;
        PRINT 'Estudiante ID ' + CAST(@id_estudiante AS VARCHAR) + ' dado de baja por saldo cero.';
    END
    ELSE
    BEGIN
        PRINT 'El estudiante tiene saldo pendiente. No se puede dar de baja.';
    END

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Registrar nota y actualizar nota final
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_RegistrarNotaYActualizarFinal;
GO

CREATE PROCEDURE creacion.sp_RegistrarNotaYActualizarFinal
@id_estudiante INT,
@id_materia INT,
@nota_teorica_1 DECIMAL(4,2),
@nota_teorica_2 DECIMAL(4,2),
@nota_practica DECIMAL(4,2)
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
-- Actualizar notas parciales
UPDATE creacion.inscripcion
SET nota_teorica_1 = @nota_teorica_1,
nota_teorica_2 = @nota_teorica_2,
nota_practica = @nota_practica
WHERE id_estudiante = @id_estudiante
AND id_materia = @id_materia;

    -- Calcular promedio final
    DECLARE @promedio DECIMAL(4,2);
    SET @promedio = (@nota_teorica_1 + @nota_teorica_2 + @nota_practica)/3.0;

    -- Actualizar nota final
    UPDATE creacion.inscripcion
    SET nota_final = @promedio
    WHERE id_estudiante = @id_estudiante
      AND id_materia = @id_materia;

    PRINT 'Nota final actualizada para estudiante ID ' + CAST(@id_estudiante AS VARCHAR);

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Generar intereses por mora
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_GenerarInteresesMora;
GO

CREATE PROCEDURE creacion.sp_GenerarInteresesMora
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
DECLARE @porcentaje DECIMAL(5,2) = (SELECT TOP 1 porcentaje_interes FROM creacion.interes_por_mora);

    UPDATE creacion.cuota
    SET monto = monto * (1 + @porcentaje / 100)
    WHERE fecha_vencimiento < GETDATE()
      AND estado_pago = 'Pendiente';

    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    SELECT id_estudiante, GETDATE(), 'Interés por mora', -(monto * @porcentaje / 100), 'Interés', 'Pendiente'
    FROM creacion.cuota
    WHERE fecha_vencimiento < GETDATE()
      AND estado_pago = 'Pendiente';

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    THROW;
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Emitir factura agrupada
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_EmitirFacturaAgrupada;
GO

CREATE PROCEDURE creacion.sp_EmitirFacturaAgrupada
@id_estudiante INT,
@mes INT,
@anio INT
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
DECLARE @monto_total DECIMAL(10,2);

    SELECT @monto_total = SUM(monto)
    FROM creacion.cuota
    WHERE id_estudiante = @id_estudiante
      AND mes = @mes
      AND estado_pago = 'Pendiente';

    INSERT INTO creacion.factura (id_estudiante, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
    VALUES (@id_estudiante, @mes, @anio, GETDATE(), DATEADD(DAY, 30, GETDATE()), @monto_total, 'Pendiente');

    DECLARE @id_factura INT = SCOPE_IDENTITY();

    UPDATE creacion.cuota
    SET id_factura = @id_factura
    WHERE id_estudiante = @id_estudiante
      AND mes = @mes
      AND estado_pago = 'Pendiente';

    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    THROW;
END CATCH

END;
GO

-- ===============================
-- PROCEDIMIENTO: Reinscribir estudiante
-- ===============================
DROP PROCEDURE IF EXISTS creacion.sp_ReinscribirEstudiante;
GO

CREATE PROCEDURE creacion.sp_ReinscribirEstudiante
@id_estudiante INT
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
-- Eliminada referencia a estado_baja
IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
RAISERROR('El estudiante no está dado de baja.', 16, 1);

    -- INSERT para reinscripción
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
-- PROCEDIMIENTO: Registrar matrícula
CREATE OR ALTER PROCEDURE creacion.sp_RegistrarMatriculaTransaccion
@id_estudiante INT,
@anio INT,
@monto DECIMAL(10,2)
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
-- Validaciones...
COMMIT;
END TRY
BEGIN CATCH
ROLLBACK;
DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
RAISERROR(@msg, 16, 1);
END CATCH
END;
GO
-- PROCEDIMIENTO: Inscribir estudiante a curso
CREATE OR ALTER PROCEDURE creacion.sp_InscribirEstudianteCursoTransaccion
@id_estudiante INT,
@id_materia INT,
@id_curso INT
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
-- Validaciones e inserciones...
COMMIT;
END TRY
BEGIN CATCH
ROLLBACK;
DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
RAISERROR(@msg, 16, 1);
END CATCH
END;
GO

-- PROCEDIMIENTO: Registrar pago de cuota
CREATE OR ALTER PROCEDURE creacion.sp_RegistrarPagoCuotaTransaccion
@id_cuota INT,
@monto_pago DECIMAL(10,2)
AS
BEGIN
BEGIN TRANSACTION;
BEGIN TRY
-- Validaciones e inserciones...
COMMIT;
END TRY
BEGIN CATCH
ROLLBACK;
DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
RAISERROR(@msg, 16, 1);
END CATCH
END;
GO
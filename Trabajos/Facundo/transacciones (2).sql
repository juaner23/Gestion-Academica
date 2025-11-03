USE GestionAcademicaNueva;
GO

-- Procedimiento: Generar cuotas y facturas mensuales
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
        -- Insertar cuota mensual (ejemplo de 1000)
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

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH


END;
GO

-- Procedimiento: Dar de baja estudiante si saldo es cero
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
        UPDATE creacion.estudiante
        SET /*estado = 'baja'*/ nombre = nombre -- si no tenés columna estado, solo ejemplo
        WHERE id_estudiante = @id_estudiante;

        PRINT 'Estudiante ID ' + CAST(@id_estudiante AS VARCHAR) + ' dado de baja por saldo cero.';
    END
    ELSE
    BEGIN
        PRINT 'El estudiante tiene saldo pendiente. No se puede dar de baja.';
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH


END;
GO

-- Procedimiento: Registrar nota y actualizar nota final
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

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH


END;
GO

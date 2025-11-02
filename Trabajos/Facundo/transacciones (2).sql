USE GestionAcademica;
GO

CREATE PROCEDURE creacion.sp_GenerarCuotasYFacturasMensuales
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN

        DECLARE @id_estudiante INT
        DECLARE cursorEstudiantes CURSOR FOR
        SELECT id_estudiante FROM creacion.estudiante WHERE estado = 'activo'

        OPEN cursorEstudiantes
        FETCH NEXT FROM cursorEstudiantes INTO @id_estudiante

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Insertar cuota mensual
            INSERT INTO creacion.CuentaCorriente (id_estudiante, monto, fecha_pago)
            VALUES (@id_estudiante, 1000, GETDATE())

            -- Crear factura
            INSERT INTO creacion.Factura (id_estudiante, fecha_emision, total)
            VALUES (@id_estudiante, GETDATE(), 1000)

            -- Registrar movimiento (simulado)
            PRINT 'Cuota y factura registradas para estudiante ID ' + CAST(@id_estudiante AS VARCHAR)

            FETCH NEXT FROM cursorEstudiantes INTO @id_estudiante
        END

        CLOSE cursorEstudiantes
        DEALLOCATE cursorEstudiantes

        COMMIT
    END TRY
    BEGIN CATCH
        ROLLBACK
        PRINT 'Error: ' + ERROR_MESSAGE()
    END CATCH
END;
GO


CREATE PROCEDURE creacion.sp_BajaEstudianteSiSaldoCero
    @id_estudiante INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN

        DECLARE @saldo DECIMAL(10,2)

        SELECT @saldo = ISNULL(SUM(monto), 0)
        FROM creacion.CuentaCorriente
        WHERE id_estudiante = @id_estudiante

        IF @saldo = 0
        BEGIN
            UPDATE creacion.estudiante
            SET estado = 'baja'
            WHERE id_estudiante = @id_estudiante

            PRINT 'Estudiante ID ' + CAST(@id_estudiante AS VARCHAR) + ' dado de baja por saldo cero.'
        END
        ELSE
        BEGIN
            PRINT 'El estudiante tiene saldo pendiente. No se puede dar de baja.'
        END

        COMMIT
    END TRY
    BEGIN CATCH
        ROLLBACK
        PRINT 'Error: ' + ERROR_MESSAGE()
    END CATCH
END;
GO


CREATE PROCEDURE creacion.sp_RegistrarNotaYActualizarFinal
    @id_estudiante INT,
    @id_curso INT,
    @nota_teorica_1 DECIMAL(4,2),
    @nota_teorica_2 DECIMAL(4,2),
    @nota_practica DECIMAL(4,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRAN

        -- Actualizar notas parciales
        UPDATE creacion.inscripciones
        SET nota_teorica_1 = @nota_teorica_1,
            nota_teorica_2 = @nota_teorica_2,
            nota_practica = @nota_practica
        WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso

        -- Calcular nuevo promedio
        DECLARE @promedio DECIMAL(4,2)
        SET @promedio = (@nota_teorica_1 + @nota_teorica_2 + @nota_practica) / 3.0

        -- Actualizar nota final
        UPDATE creacion.inscripciones
        SET nota_final = @promedio
        WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso

        PRINT 'Nota final actualizada para estudiante ID ' + CAST(@id_estudiante AS VARCHAR)

        COMMIT
    END TRY
    BEGIN CATCH
        ROLLBACK
        PRINT 'Error: ' + ERROR_MESSAGE()
    END CATCH
END;
GO

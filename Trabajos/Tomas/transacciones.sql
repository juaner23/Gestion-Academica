-- Archivo: transacciones.sql
-- Autor: Tomas

USE GestionAcademicaNueva;
GO


--Procedimientos almacenados con transacciones
--1
--Registrar matrícula de un estudiante y generar factura y movimiento en cuenta corriente.


CREATE OR ALTER PROCEDURE creacion.sp_RegistrarMatriculaTransaccion (@id_estudiante INT, @anio INT, @monto DECIMAL(10,2))
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            RAISERROR('Estudiante no existe.', 16, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM creacion.matriculacion WHERE id_estudiante = @id_estudiante AND anio = @anio)
        BEGIN
            RAISERROR('Ya existe matrícula para ese año.', 16, 1);
            RETURN;
        END

        INSERT INTO creacion.matriculacion (id_estudiante, anio, fecha_pago, monto, estado_pago)
        VALUES (@id_estudiante, @anio, GETDATE(), @monto, 'Pendiente');

        INSERT INTO creacion.factura (id_estudiante, fecha, total, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
        VALUES (@id_estudiante, GETDATE(), @monto, 1, @anio, GETDATE(), DATEADD(MONTH, 1, GETDATE()), @monto, 'Pendiente');

        INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
        VALUES (@id_estudiante, GETDATE(), 'Cargo matrícula', -@monto, 'Matrícula año ' + CAST(@anio AS NVARCHAR), 'Pendiente');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

--2
--Inscribir a un estudiante en un curso y validar disponibilidad de vacantes.
CREATE OR ALTER PROCEDURE creacion.sp_InscribirEstudianteCursoTransaccion (@id_estudiante INT, @id_materia INT, @id_curso INT)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            RAISERROR('Estudiante no existe.', 16, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM creacion.inscripcion WHERE id_estudiante = @id_estudiante AND id_materia = @id_materia)
        BEGIN
            RAISERROR('Ya inscrito en esa materia.', 16, 1);
            RETURN;
        END

        DECLARE @cupo_ocupado INT, @cupo_maximo INT;
        SELECT @cupo_ocupado = cupo_ocupado, @cupo_maximo = cupo_maximo FROM creacion.curso WHERE id_curso = @id_curso;
        IF @cupo_ocupado >= @cupo_maximo
        BEGIN
            RAISERROR('No hay vacantes disponibles.', 16, 1);
            RETURN;
        END

        INSERT INTO creacion.inscripcion (id_estudiante, id_materia, fecha_inscripcion, id_curso)
        VALUES (@id_estudiante, @id_materia, GETDATE(), @id_curso);

        UPDATE creacion.curso SET cupo_ocupado = cupo_ocupado + 1 WHERE id_curso = @id_curso;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

--3
--Registrar pago de cuota y actualizar estado de factura y cuenta corriente.

CREATE OR ALTER PROCEDURE creacion.sp_RegistrarPagoCuotaTransaccion (@id_cuota INT, @monto_pago DECIMAL(10,2))
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @monto_cuota DECIMAL(10,2), @id_estudiante INT, @id_factura INT;
        SELECT @monto_cuota = monto, @id_estudiante = id_estudiante, @id_factura = id_factura FROM creacion.cuota WHERE id_cuota = @id_cuota;
        IF @monto_cuota IS NULL
        BEGIN
            RAISERROR('Cuota no existe.', 16, 1);
            RETURN;
        END
        IF @monto_pago < @monto_cuota
        BEGIN
            RAISERROR('Monto insuficiente.', 16, 1);
            RETURN;
        END

        UPDATE creacion.cuota SET estado_pago = 'Pagada' WHERE id_cuota = @id_cuota;

        UPDATE creacion.factura SET estado_pago = 'Pagada' WHERE id_factura = @id_factura;

        INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
        VALUES (@id_estudiante, GETDATE(), 'Pago cuota', @monto_pago, 'Pago cuota ' + CAST(@id_cuota AS NVARCHAR), 'Pagado');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

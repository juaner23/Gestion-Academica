USE GestionAcademicaNueva;
GO

DROP TRIGGER IF EXISTS creacion.trg_ActualizarEstadoPagoCuota;
DROP TRIGGER IF EXISTS creacion.trg_CalcularNotaFinal;
DROP TRIGGER IF EXISTS creacion.trg_ActualizarEstadoBaja;
GO

-- Trigger para actualizar el estado de pago de la cuota al registrar un pago.
CREATE TRIGGER creacion.trg_ActualizarEstadoPagoCuota
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
    UPDATE creacion.cuota
    SET estado_pago = 'Pagada'
    WHERE id_estudiante IN (SELECT id_estudiante FROM inserted WHERE monto > 0)
    AND estado_pago = 'Pendiente';
END;
GO

-- Trigger para calcular nota final al insertar una nota de recuperatorio.
CREATE TRIGGER creacion.trg_CalcularNotaFinal
ON creacion.inscripcion
AFTER UPDATE
AS
BEGIN
    IF UPDATE(nota_teorica_recuperatorio)
    BEGIN
        UPDATE creacion.inscripcion
        SET nota_final = CASE 
            WHEN nota_teorica_recuperatorio >= 4 THEN nota_teorica_recuperatorio
            ELSE (nota_teorica_1 + nota_teorica_2 + nota_practica) / 3
        END
        WHERE id_estudiante IN (SELECT id_estudiante FROM inserted)
        AND id_curso IN (SELECT id_curso FROM inserted);
    END
END;
GO

-- Trigger para actualizar el estado de baja de un estudiante al eliminar una inscripción.
CREATE TRIGGER creacion.trg_ActualizarEstadoBaja
ON creacion.inscripcion
AFTER DELETE
AS
BEGIN
    UPDATE creacion.estudiante
    SET estado_baja = 1
    WHERE id_estudiante IN (
        SELECT D.id_estudiante FROM deleted D
        LEFT JOIN creacion.inscripcion I ON D.id_estudiante = I.id_estudiante
        GROUP BY D.id_estudiante
        HAVING COUNT(I.id_estudiante) = 0
    );
END;
GO
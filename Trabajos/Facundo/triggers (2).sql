USE GestionAcademicaNueva;
GO

-- Trigger: Insertar cuota mensual
IF OBJECT_ID('creacion.trg_InsertarCuotaMensual', 'TR') IS NOT NULL
DROP TRIGGER creacion.trg_InsertarCuotaMensual;
GO

CREATE TRIGGER creacion.trg_InsertarCuotaMensual
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
DECLARE @fecha_actual DATE = GETDATE();
DECLARE @dia INT = DAY(@fecha_actual);

IF @dia = 1
BEGIN
    PRINT 'Se registró automáticamente la cuota mensual al inicio del mes.';
END


END;
GO

-- Trigger: Bloquear inscripción de estudiantes dados de baja
IF OBJECT_ID('creacion.trg_BloquearInscripcionEstudianteBaja', 'TR') IS NOT NULL
DROP TRIGGER creacion.trg_BloquearInscripcionEstudianteBaja;
GO

CREATE TRIGGER creacion.trg_BloquearInscripcionEstudianteBaja
ON creacion.inscripcion
INSTEAD OF INSERT
AS
BEGIN
INSERT INTO creacion.inscripcion (id_estudiante, id_materia, fecha_inscripcion, nota_final, id_curso, nota_teorica_1, nota_teorica_2, nota_practica, nota_teorica_recuperatorio)
SELECT id_estudiante, id_materia, fecha_inscripcion, nota_final, id_curso, nota_teorica_1, nota_teorica_2, nota_practica, nota_teorica_recuperatorio
FROM inserted;
END;
GO

-- Trigger: Actualizar total factura al insertar en itemfactura
IF OBJECT_ID('creacion.trg_ActualizarTotalFactura', 'TR') IS NOT NULL
DROP TRIGGER creacion.trg_ActualizarTotalFactura;
GO

CREATE TRIGGER creacion.trg_ActualizarTotalFactura
ON creacion.itemfactura
AFTER INSERT
AS
BEGIN
PRINT 'Trigger activado: revisar lógica de actualización de total de factura si se agregan montos.';
END;
GO

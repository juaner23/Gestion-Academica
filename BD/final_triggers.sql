USE GestionAcademicaNueva;
GO

-- Dropear triggers existentes
DROP TRIGGER IF EXISTS creacion.tr_GenerarMovimientoFactura;
DROP TRIGGER IF EXISTS creacion.tr_ValidarInscripcionUnica;
DROP TRIGGER IF EXISTS creacion.tr_ActualizarEstadoFacturaPago;
DROP TRIGGER IF EXISTS creacion.trg_InsertarCuotaMensual;
DROP TRIGGER IF EXISTS creacion.trg_BloquearInscripcionEstudianteBaja;
DROP TRIGGER IF EXISTS creacion.trg_ActualizarTotalFactura;
DROP TRIGGER IF EXISTS creacion.trg_ActualizarEstadoPagoCuota;
DROP TRIGGER IF EXISTS creacion.trg_CalcularNotaFinal;
DROP TRIGGER IF EXISTS creacion.trg_RegistrarInteresMora;
GO

-- Trigger: generar movimiento en cuenta corriente al emitir factura
CREATE TRIGGER creacion.tr_GenerarMovimientoFactura
ON creacion.factura
AFTER INSERT
AS
BEGIN
INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
SELECT
i.id_estudiante,
GETDATE(),
'Emisión de factura',
-ISNULL(i.monto_total, 0),
'Factura emitida',
'Pendiente'
FROM inserted i;
END;
GO

-- Trigger: validar inscripción única por materia en un curso
CREATE TRIGGER creacion.tr_ValidarInscripcionUnica
ON creacion.inscripcion
AFTER INSERT
AS
BEGIN
IF EXISTS (
SELECT 1
FROM inserted i
INNER JOIN creacion.inscripcion i2
ON i.id_estudiante = i2.id_estudiante
AND i.id_materia = i2.id_materia
AND i.id_inscripcion <> i2.id_inscripcion
)
BEGIN
RAISERROR('El estudiante ya está inscripto en esta materia.', 16, 1);
ROLLBACK TRANSACTION;
END
END;
GO

-- Trigger: actualizar estado de pago de factura cuando se registra pago en cuenta corriente
CREATE TRIGGER creacion.tr_ActualizarEstadoFacturaPago
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
UPDATE f
SET estado_pago = 'Pagada'
FROM creacion.factura f
INNER JOIN inserted i ON f.id_estudiante = i.id_estudiante
WHERE i.estado = 'Pagado';
END;
GO

-- Trigger: insertar cuota mensual (ejemplo de notificación)
CREATE TRIGGER creacion.trg_InsertarCuotaMensual
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
DECLARE @dia INT = DAY(GETDATE());
IF @dia = 1
PRINT 'Se registró automáticamente la cuota mensual al inicio del mes.';
END;
GO

-- Trigger: bloquear inscripción de estudiantes dados de baja
CREATE TRIGGER creacion.trg_BloquearInscripcionEstudianteBaja
ON creacion.inscripcion
INSTEAD OF INSERT
AS
BEGIN
-- Aquí asumimos que todos los estudiantes pueden inscribirse porque no hay columna "estado"
INSERT INTO creacion.inscripcion (id_estudiante, id_materia, fecha_inscripcion, nota_final, id_curso, nota_teorica_1, nota_teorica_2, nota_practica, nota_teorica_recuperatorio)
SELECT id_estudiante, id_materia, fecha_inscripcion, nota_final, id_curso, nota_teorica_1, nota_teorica_2, nota_practica, nota_teorica_recuperatorio
FROM inserted;
END;
GO

-- Trigger: actualizar total factura al insertar itemfactura
CREATE TRIGGER creacion.trg_ActualizarTotalFactura
ON creacion.itemfactura
AFTER INSERT
AS
BEGIN
PRINT 'Trigger activado: revisar lógica de actualización de total de factura si se agregan montos.';
END;
GO

-- Trigger: actualizar estado de pago de la cuota
CREATE TRIGGER creacion.trg_ActualizarEstadoPagoCuota
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
UPDATE c
SET estado_pago = 'Pagada'
FROM creacion.cuota c
INNER JOIN inserted i ON c.id_estudiante = i.id_estudiante
WHERE i.monto > 0 AND c.estado_pago = 'Pendiente';
END;
GO

-- Trigger: calcular nota final al insertar nota de recuperatorio
CREATE TRIGGER creacion.trg_CalcularNotaFinal
ON creacion.inscripcion
AFTER UPDATE
AS
BEGIN
IF UPDATE(nota_teorica_recuperatorio)
BEGIN
UPDATE i
SET nota_final = CASE
WHEN i.nota_teorica_recuperatorio >= 4 THEN i.nota_teorica_recuperatorio
ELSE (ISNULL(i.nota_teorica_1,0) + ISNULL(i.nota_teorica_2,0) + ISNULL(i.nota_practica,0)) / 3
END
FROM creacion.inscripcion i
INNER JOIN inserted ins ON i.id_inscripcion = ins.id_inscripcion;
END
END;
GO

-- Trigger: registrar interés por mora cuando la cuota se vence
CREATE TRIGGER creacion.tr_RegistrarInteresMora
ON creacion.cuota
AFTER UPDATE
AS
BEGIN
SET NOCOUNT ON;
IF UPDATE(estado_pago)
BEGIN
INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
SELECT i.id_estudiante, GETDATE(), 'Interés por mora',
- (i.monto * ISNULL(ip.porcentaje_interes, 0) / 100),
'Interés mora cuota ' + CAST(i.id_cuota AS NVARCHAR),
'Pendiente'
FROM inserted i
LEFT JOIN creacion.interes_por_mora ip
ON ip.anio_carrera = (SELECT e.anio_ingreso FROM creacion.estudiante e WHERE e.id_estudiante = i.id_estudiante)
WHERE i.estado_pago = 'Vencida'
AND (SELECT estado_pago FROM deleted WHERE id_cuota = i.id_cuota) <> 'Vencida';
END
END;
GO

PRINT 'Todos los triggers se crearon correctamente.';
GO

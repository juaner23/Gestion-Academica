USE GestionAcademicaNueva;
GO

-- Dropear 
DROP TRIGGER IF EXISTS creacion.tr_GenerarMovimientoFactura;
DROP TRIGGER IF EXISTS creacion.tr_ValidarInscripcionUnica;
DROP TRIGGER IF EXISTS creacion.tr_ActualizarEstadoFacturaPago;
GO

-- Trigger para generar movimiento en cuenta corriente al emitir una factura.
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
        -i.monto_total,  -- Débito (negativo)
        'Factura emitida',
        'Pendiente'
    FROM inserted i;
END;
GO

-- Trigger para validar que no se inscriba dos veces a la misma materia en el mismo cuatrimestre.
CREATE TRIGGER creacion.tr_ValidarInscripcionUnica
ON creacion.inscripcion
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN creacion.inscripcion i2 ON i.id_estudiante = i2.id_estudiante AND i.id_materia = i2.id_materia
        INNER JOIN creacion.curso c1 ON i.id_curso = c1.id_curso
        INNER JOIN creacion.curso c2 ON i2.id_curso = c2.id_curso
        WHERE c1.id_cuatrimestre = c2.id_cuatrimestre AND i.id_inscripcion <> i2.id_inscripcion
    )
    BEGIN
        RAISERROR('El estudiante ya está inscripto en esta materia en el mismo cuatrimestre.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger para actualizar el estado de pago de la factura al registrar un pago.
CREATE TRIGGER creacion.tr_ActualizarEstadoFacturaPago
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
    UPDATE creacion.factura
    SET estado_pago = 'Pagada'
    WHERE id_factura IN (
        SELECT DISTINCT f.id_factura
        FROM inserted i
        INNER JOIN creacion.cuota cu ON i.id_estudiante = cu.id_estudiante
        INNER JOIN creacion.factura f ON cu.id_factura = f.id_factura
        WHERE i.estado = 'Pagado' AND NOT EXISTS (
            SELECT 1 FROM creacion.cuota cu2 WHERE cu2.id_factura = f.id_factura AND cu2.estado_pago <> 'Pagada'
        )
    );
END;
GO
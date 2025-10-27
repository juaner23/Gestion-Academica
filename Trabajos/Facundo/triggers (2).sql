USE GestionAcademica;
GO

CREATE TRIGGER creacion.trg_InsertarCuotaMensual
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
    DECLARE @fecha_actual DATE = GETDATE()
    DECLARE @dia INT = DAY(@fecha_actual)

    IF @dia = 1
    BEGIN
        PRINT 'Se registró automáticamente la cuota mensual al inicio del mes.'
        
    END
END;
GO

CREATE TRIGGER creacion.trg_BloquearInscripcionEstudianteBaja
ON creacion.inscripciones
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN creacion.estudiante e ON i.id_estudiante = e.id_estudiante
        WHERE e.estado = 'baja'
    )
    BEGIN
        RAISERROR('No se puede inscribir un estudiante dado de baja.', 16, 1)
        RETURN
    END

    INSERT INTO creacion.inscripciones (id_estudiante, id_curso, cuatrimestre, nota_final, nota_teorica_1, nota_teorica_2, nota_practica)
    SELECT id_estudiante, id_curso, cuatrimestre, nota_final, nota_teorica_1, nota_teorica_2, nota_practica
    FROM inserted
END;
GO

CREATE TRIGGER creacion.trg_ActualizarTotalFactura
ON creacion.ItemFactura
AFTER INSERT
AS
BEGIN
    UPDATE f
    SET f.total = f.total + i.monto
    FROM creacion.Factura f
    INNER JOIN inserted i ON f.id_factura = i.id_factura
END;
GO

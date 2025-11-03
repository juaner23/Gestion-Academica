-- Archivo: triggers.sql
-- Autor: Tomas
use GestionAcademicaNueva;
GO

--TRIGGER  para registrar interés por mora al detectar cuota vencida.

DROP TRIGGER IF EXISTS creacion.tr_RegistrarInteresMora;
GO

CREATE TRIGGER tr_RegistrarInteresMora
ON creacion.cuota
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado_pago)
    BEGIN
        INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
        SELECT i.id_estudiante, GETDATE(), 'Interés por mora', 
               - (i.monto * ISNULL(ip.porcentaje_interes, 0) / 100), 'Interés mora cuota ' + CAST(i.id_cuota AS NVARCHAR), 'Pendiente'
        FROM inserted i
        LEFT JOIN creacion.estudiante e ON i.id_estudiante = e.id_estudiante
        LEFT JOIN creacion.interes_por_mora ip ON e.anio_ingreso = ip.anio_carrera
        WHERE i.estado_pago = 'Vencida' AND (SELECT estado_pago FROM deleted WHERE id_cuota = i.id_cuota) <> 'Vencida';
    END
END;
GO

PRINT 'Trigger creado correctamente.';
GO

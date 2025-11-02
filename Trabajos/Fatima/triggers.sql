USE GestionAcademicaNueva;
GO

-- Actualizar estado de pago de cuota al registrar un pago
CREATE OR ALTER TRIGGER creacion.tr_CuentaCorriente_ActualizarCuota
ON creacion.CuentaCorriente
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_estudiante INT;
    DECLARE @monto DECIMAL(10,2);
    DECLARE @descripcion NVARCHAR(200);
    DECLARE @id_factura INT;
    
    DECLARE pagos_cursor CURSOR FOR
    SELECT id_estudiante, monto, descripcion
    FROM inserted
    WHERE monto < 0;
    
    OPEN pagos_cursor;
    FETCH NEXT FROM pagos_cursor INTO @id_estudiante, @monto, @descripcion;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @descripcion LIKE '%cuota%' OR @descripcion LIKE '%Cuota%'
        BEGIN
            SELECT TOP 1 @id_factura = id_factura
            FROM creacion.factura
            WHERE id_estudiante = @id_estudiante
            ORDER BY fecha DESC;
            
            IF @id_factura IS NOT NULL
            BEGIN
                UPDATE creacion.factura
                SET total = total + ABS(@monto)
                WHERE id_factura = @id_factura;
            END
        END
        
        FETCH NEXT FROM pagos_cursor INTO @id_estudiante, @monto, @descripcion;
    END
    
    CLOSE pagos_cursor;
    DEALLOCATE pagos_cursor;
END;
GO

-- Calcular nota final al insertar nota de recuperatorio
CREATE OR ALTER TRIGGER creacion.tr_Inscripcion_CalcularNotaFinal
ON creacion.inscripcion
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(nota_final)
    BEGIN
        UPDATE i
        SET nota_final = CASE 
            WHEN i.nota_final IS NOT NULL AND i.nota_final >= 4 
            THEN i.nota_final
            WHEN i.nota_final IS NOT NULL AND i.nota_final < 4
            THEN (SELECT TOP 1 nota_final FROM creacion.inscripcion 
                  WHERE id_estudiante = i.id_estudiante 
                  AND id_materia = i.id_materia 
                  AND nota_final IS NOT NULL 
                  ORDER BY nota_final DESC)
            ELSE i.nota_final
        END
        FROM creacion.inscripcion i
        INNER JOIN inserted ins ON i.id_estudiante = ins.id_estudiante 
                                 AND i.id_materia = ins.id_materia
        WHERE i.nota_final IS NOT NULL;
    END
END;
GO

-- Actualizar estado de baja de estudiante al eliminar inscripción
CREATE OR ALTER TRIGGER creacion.tr_Inscripcion_ActualizarBajaEstudiante
ON creacion.inscripcion
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM sys.columns 
                   WHERE object_id = OBJECT_ID('creacion.estudiante') 
                   AND name = 'estado_baja')
    BEGIN
        RETURN;
    END
    
    DECLARE @id_estudiante INT;
    DECLARE @inscripciones_restantes INT;
    DECLARE @sql NVARCHAR(500);
    
    DECLARE estudiantes_cursor CURSOR FOR
    SELECT DISTINCT id_estudiante
    FROM deleted;
    
    OPEN estudiantes_cursor;
    FETCH NEXT FROM estudiantes_cursor INTO @id_estudiante;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @inscripciones_restantes = COUNT(*)
        FROM creacion.inscripcion
        WHERE id_estudiante = @id_estudiante;
        
        IF @inscripciones_restantes = 0
        BEGIN
            SET @sql = 'UPDATE creacion.estudiante SET estado_baja = 1 WHERE id_estudiante = ' + CAST(@id_estudiante AS NVARCHAR(10));
            EXEC sp_executesql @sql;
        END
        
        FETCH NEXT FROM estudiantes_cursor INTO @id_estudiante;
    END
    
    CLOSE estudiantes_cursor;
    DEALLOCATE estudiantes_cursor;
END;
GO

PRINT 'Triggers creados correctamente.';
GO


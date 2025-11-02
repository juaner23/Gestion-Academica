USE GestionAcademicaNueva;
GO

-- Listar estudiantes con matrícula activa en un año
CREATE OR ALTER FUNCTION creacion.fn_EstudiantesMatriculaActiva(@anio INT)
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT e.id_estudiante, e.nombre, e.apellido, e.email
    FROM creacion.estudiante e
    INNER JOIN creacion.inscripcion i ON e.id_estudiante = i.id_estudiante
    INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
    INNER JOIN creacion.curso c ON m.id_curso = c.id_curso
    WHERE c.anio = @anio
    AND i.nota_final IS NULL
);
GO

-- Obtener facturas emitidas en un mes
CREATE OR ALTER FUNCTION creacion.fn_FacturasPorMes(@mes INT, @anio INT)
RETURNS TABLE
AS
RETURN
(
    SELECT f.id_factura, f.id_estudiante, e.nombre, e.apellido, 
           f.fecha, f.total
    FROM creacion.factura f
    INNER JOIN creacion.estudiante e ON f.id_estudiante = e.id_estudiante
    WHERE MONTH(f.fecha) = @mes
    AND YEAR(f.fecha) = @anio
);
GO

-- Listar cursos con más de 30 estudiantes inscriptos
CREATE OR ALTER FUNCTION creacion.fn_CursosMas30Inscriptos()
RETURNS TABLE
AS
RETURN
(
    SELECT c.id_curso, c.nombre, c.anio, 
           COUNT(DISTINCT i.id_estudiante) AS cantidad_inscriptos
    FROM creacion.curso c
    INNER JOIN creacion.materia m ON c.id_curso = m.id_curso
    INNER JOIN creacion.inscripcion i ON m.id_materia = i.id_materia
    GROUP BY c.id_curso, c.nombre, c.anio
    HAVING COUNT(DISTINCT i.id_estudiante) > 30
);
GO

-- Mostrar movimientos de cuenta corriente de un estudiante
CREATE OR ALTER FUNCTION creacion.fn_MovimientosCuentaCorriente(@id_estudiante INT)
RETURNS TABLE
AS
RETURN
(
    SELECT cc.id_movimiento, cc.fecha, cc.descripcion, cc.monto
    FROM creacion.CuentaCorriente cc
    WHERE cc.id_estudiante = @id_estudiante
);
GO

PRINT 'Funciones con devolución de tabla creadas correctamente.';
GO


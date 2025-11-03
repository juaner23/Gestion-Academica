USE GestionAcademicaNueva;
GO

-- Listar los estudiantes con matrícula activa en un año determinado.
CREATE OR ALTER FUNCTION creacion.fn_EstudiantesMatriculaActiva (@anio INT)
RETURNS TABLE
AS
RETURN (
    SELECT E.id_estudiante, E.nombre, E.apellido
    FROM creacion.estudiante E
    INNER JOIN creacion.matriculacion M ON E.id_estudiante = M.id_estudiante
    WHERE M.anio = @anio AND M.estado_pago = 'Pagada'
);
GO

SELECT * FROM creacion.fn_EstudiantesMatriculaActiva(2023);
GO

-- Obtener todas las facturas emitidas en un mes específico.
CREATE OR ALTER FUNCTION creacion.fn_FacturasPorMes (@mes INT, @anio INT)
RETURNS TABLE
AS
RETURN (
    SELECT * FROM creacion.factura WHERE mes = @mes AND anio = @anio
);
GO

SELECT * FROM creacion.fn_FacturasPorMes(3, 2023);
GO

-- Listar los cursos con más de 30 estudiantes inscriptos.
CREATE OR ALTER FUNCTION creacion.fn_CursosMas30Inscriptos ()
RETURNS TABLE
AS
RETURN (
    SELECT C.id_curso, C.nombre, COUNT(I.id_estudiante) AS inscriptos
    FROM creacion.curso C
    INNER JOIN creacion.inscripcion I ON C.id_curso = I.id_curso
    GROUP BY C.id_curso, C.nombre
    HAVING COUNT(I.id_estudiante) > 30
);
GO

SELECT * FROM creacion.fn_CursosMas30Inscriptos();
GO

-- Mostrar los movimientos de cuenta corriente de un estudiante.
CREATE OR ALTER FUNCTION creacion.fn_MovimientosCuentaCorriente (@id_estudiante INT)
RETURNS TABLE
AS
RETURN (
    SELECT * FROM creacion.CuentaCorriente WHERE id_estudiante = @id_estudiante
);
GO

SELECT * FROM creacion.fn_MovimientosCuentaCorriente(1);
GO
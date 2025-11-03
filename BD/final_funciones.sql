
USE GestionAcademicaNueva;
GO


--Listar todos los cursos en los que está inscripto un estudiante.

CREATE OR ALTER FUNCTION creacion.fn_ListarCursosInscriptos (@id_estudiante INT)
RETURNS TABLE
AS
RETURN
    SELECT 
        c.id_curso,
        c.nombre AS nombre_curso,
        m.nombre AS nombre_materia,
        i.fecha_inscripcion,
        i.nota_final
    FROM creacion.inscripcion i
    INNER JOIN creacion.curso c ON i.id_curso = c.id_curso
    INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
    WHERE i.id_estudiante = @id_estudiante;
GO


-- Obtener todas las cuotas impagas de un estudiante.
CREATE OR ALTER FUNCTION creacion.fn_ObtenerCuotasImpagas (@id_estudiante INT)
RETURNS TABLE
AS
RETURN
    SELECT 
        cu.id_cuota,
        cu.mes,
        cu.monto,
        cu.fecha_vencimiento,
        cu.estado_pago,
        ct.nombre AS nombre_cuatrimestre
    FROM creacion.cuota cu
    INNER JOIN creacion.cuatrimestre ct ON cu.id_cuatrimestre = ct.id_cuatrimestre
    WHERE cu.id_estudiante = @id_estudiante AND cu.estado_pago IN ('Pendiente', 'Vencida');
GO

-- Listar los profesores que dictan materias en un cuatrimestre específico.
CREATE OR ALTER FUNCTION creacion.fn_ListarProfesoresPorCuatrimestre (@id_cuatrimestre INT)
RETURNS TABLE
AS
RETURN
    SELECT DISTINCT
        p.id_profesor,
        p.nombre AS nombre_profesor,
        p.apellido AS apellido_profesor,
        p.especialidad,
        m.nombre AS nombre_materia,
        c.nombre AS nombre_curso
    FROM creacion.curso c
    INNER JOIN creacion.profesor p ON c.id_profesor = p.id_profesor
    INNER JOIN creacion.materia m ON c.id_materia = m.id_materia
    WHERE c.id_cuatrimestre = @id_cuatrimestre;
GO

-- Mostrar todas las materias con más de 3 cursos activos.
CREATE OR ALTER FUNCTION creacion.fn_MateriasConMasDe3CursosActivos ()
RETURNS TABLE
AS
RETURN
    SELECT 
        m.id_materia,
        m.nombre AS nombre_materia,
        m.creditos,
        m.costo_curso_mensual,
        COUNT(c.id_curso) AS cantidad_cursos_activos
    FROM creacion.materia m
    INNER JOIN creacion.curso c ON m.id_materia = c.id_materia
    GROUP BY m.id_materia, m.nombre, m.creditos, m.costo_curso_mensual
    HAVING COUNT(c.id_curso) > 3;
GO



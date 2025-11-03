USE GestionAcademicaNueva;
GO

-- 1. Listar cursos en los que está inscripto un estudiante
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

-- 2. Obtener todas las cuotas impagas de un estudiante
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

-- 3. Listar los profesores que dictan materias en un cuatrimestre específico
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
INNER JOIN creacion.cuatrimestre cu ON cu.id_cuatrimestre = @id_cuatrimestre -- solo filtro por cuatrimestre
WHERE 1=1;
GO

-- 4. Mostrar todas las materias con más de 3 cursos activos
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

-- 5. Saldo de cuenta corriente
CREATE OR ALTER FUNCTION creacion.fn_SaldoCuentaCorriente (@id_estudiante INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @saldo DECIMAL(10,2);
SELECT @saldo = ISNULL(SUM(monto),0)
FROM creacion.CuentaCorriente
WHERE id_estudiante = @id_estudiante;
RETURN @saldo;
END;
GO

-- 6. Vacantes disponibles por curso
CREATE OR ALTER FUNCTION creacion.fn_VacantesDisponibles (@id_curso INT)
RETURNS INT
AS
BEGIN
DECLARE @cupo_max INT, @ocupado INT;
SELECT @cupo_max = cupo_maximo, @ocupado = cupo_ocupado
FROM creacion.curso
WHERE id_curso = @id_curso;
RETURN CASE WHEN (@cupo_max - @ocupado) < 0 THEN 0 ELSE (@cupo_max - @ocupado) END;
END;
GO

-- 7. Nombre completo del estudiante
CREATE OR ALTER FUNCTION creacion.fn_NombreCompleto (@id_estudiante INT)
RETURNS NVARCHAR(120)
AS
BEGIN
DECLARE @nombreCompleto NVARCHAR(120);
SELECT @nombreCompleto = nombre + ' ' + apellido
FROM creacion.estudiante
WHERE id_estudiante = @id_estudiante;
RETURN @nombreCompleto;
END;
GO

-- 8. Promedio final por curso
CREATE OR ALTER FUNCTION creacion.fn_PromedioFinal (@id_estudiante INT, @id_curso INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
DECLARE @promedio DECIMAL(4,2);
SELECT @promedio = (ISNULL(nota_teorica_1,0) + ISNULL(nota_teorica_2,0) + ISNULL(nota_practica,0))/3.0
FROM creacion.inscripcion
WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso;
RETURN @promedio;
END;
GO

-- 9. Cursos por profesor y año
CREATE OR ALTER FUNCTION creacion.fn_CursosPorProfesorYAnio (@id_profesor INT, @anio INT)
RETURNS TABLE
AS
RETURN
SELECT
c.id_curso,
c.nombre AS nombre_curso,
c.descripcion,
c.anio,
p.nombre AS nombre_profesor,
p.apellido AS apellido_profesor
FROM creacion.curso c
INNER JOIN creacion.profesor p ON c.id_profesor = p.id_profesor
WHERE c.id_profesor = @id_profesor AND c.anio = @anio;
GO

-- 10. Inscripciones sobresalientes
CREATE OR ALTER FUNCTION creacion.fn_InscripcionesSobresalientes ()
RETURNS TABLE
AS
RETURN
SELECT
i.id_estudiante,
e.nombre,
e.apellido,
i.id_curso,
c.nombre AS nombre_curso,
i.nota_final
FROM creacion.inscripcion i
INNER JOIN creacion.estudiante e ON i.id_estudiante = e.id_estudiante
INNER JOIN creacion.curso c ON i.id_curso = c.id_curso
WHERE i.nota_final > 8;
GO

-- 11. Estudiantes con matrícula activa en un año
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

-- 12. Facturas por mes
CREATE OR ALTER FUNCTION creacion.fn_FacturasPorMes (@mes INT, @anio INT)
RETURNS TABLE
AS
RETURN (
SELECT * FROM creacion.factura WHERE mes = @mes AND anio = @anio
);
GO

-- 13. Cursos con más de 30 estudiantes
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

-- 14. Movimientos de cuenta corriente de un estudiante
CREATE OR ALTER FUNCTION creacion.fn_MovimientosCuentaCorriente (@id_estudiante INT)
RETURNS TABLE
AS
RETURN (
SELECT * FROM creacion.CuentaCorriente WHERE id_estudiante = @id_estudiante
);
GO

-- 15. Estado de pago de una cuota específica
CREATE OR ALTER FUNCTION creacion.fn_EstadoPagoCuota (@id_estudiante INT, @id_cuota INT)
RETURNS NVARCHAR(50)
AS
BEGIN
DECLARE @estado NVARCHAR(50);
SELECT @estado = estado_pago
FROM creacion.cuota
WHERE id_estudiante = @id_estudiante AND id_cuota = @id_cuota;
RETURN @estado;
END;
GO

-- 16. Especialidad de un profesor dado su nombre
CREATE OR ALTER FUNCTION creacion.fn_EspecialidadProfesor (@nombre NVARCHAR(50))
RETURNS NVARCHAR(100)
AS
BEGIN
DECLARE @especialidad NVARCHAR(100);
SELECT @especialidad = especialidad
FROM creacion.profesor
WHERE nombre = @nombre;
RETURN @especialidad;
END;
GO

-- 17. Monto total adeudado por un estudiante (por nombre)
CREATE OR ALTER FUNCTION creacion.fn_MontoAdeudado (@nombre NVARCHAR(50))
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @count INT;
SELECT @count = COUNT(*) FROM creacion.estudiante WHERE nombre = @nombre;
IF @count > 1 RETURN -1;

DECLARE @adeudado DECIMAL(10,2);
SELECT @adeudado = ISNULL(SUM(CASE WHEN monto < 0 THEN monto ELSE 0 END), 0)
FROM creacion.CuentaCorriente cc
INNER JOIN creacion.estudiante e ON cc.id_estudiante = e.id_estudiante
WHERE e.nombre = @nombre;
RETURN @adeudado;

END;
GO
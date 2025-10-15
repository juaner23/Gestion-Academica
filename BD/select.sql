USE creacion;
GO

-- 1) Estudiantes inscriptos en cursos del año 2025
SELECT e.nombre
FROM dbo.estudiante e, dbo.inscripciones i, dbo.cursos c
WHERE e.id_estudiante = i.id_estudiante
AND c.id_curso = i.id_curso
AND c.anio = 2025;
GO

-- 2) Materias con más de 4 créditos y sus profesores
SELECT m.nombre_materia, p.nombre, p.apellido
FROM dbo.materias m, dbo.cursos c, dbo.profesor p
WHERE m.id_materia = c.id_materia
AND p.id_profesor = c.id_profesor
AND m.creditos > 4;
GO

-- 3) Cursos dictados por profesores cuya especialidad contiene "Especialidad1"
SELECT c.nombre_curso
FROM dbo.cursos c, dbo.profesor p
WHERE c.id_profesor = p.id_profesor
AND p.especialidad LIKE '%Especialidad1%';
GO

-- 4) Estudiantes con nota final >= 8
SELECT e.nombre
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
AND i.nota_final >= 8;
GO

-- 5) Cursos asociados a materias con exactamente 3 créditos
SELECT c.nombre_curso
FROM dbo.cursos c, dbo.materias m
WHERE c.id_materia = m.id_materia
AND m.creditos = 3;
GO

-- 6) Estudiantes inscritos después del 1 de junio de 2023
SELECT e.nombre
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
AND i.fecha_inscripcion > '2023-06-01';
GO

-- 7) Materias dictadas por profesor con especialidad “Especialidad5”
SELECT m.nombre_materia
FROM dbo.materias m, dbo.cursos c, dbo.profesor p
WHERE m.id_materia = c.id_materia
AND p.id_profesor = c.id_profesor
AND p.especialidad = 'Especialidad5';
GO

-- 8) Estudiantes con nota teórica < 6
SELECT e.nombre
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
AND i.nota_teorica < 6;
GO

-- 9) Cursos con inscripciones con nota final entre 7 y 9
SELECT DISTINCT c.nombre_curso
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
AND i.nota_final BETWEEN 7 AND 9;
GO

-- 10) Materias con 5 o más créditos y sus profesores
SELECT m.nombre_materia, p.nombre, p.apellido
FROM dbo.materias m, dbo.cursos c, dbo.profesor p
WHERE m.id_materia = c.id_materia
AND p.id_profesor = c.id_profesor
AND m.creditos >= 5;
GO

-- 11) Promedio de nota final por curso
SELECT c.nombre_curso, AVG(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso;
GO

-- 12) Cantidad de cursos por estudiante
SELECT e.nombre, COUNT(i.id_curso)
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
GROUP BY e.nombre;
GO

-- 13) Cantidad de materias dicta cada profesor
SELECT p.nombre, COUNT(DISTINCT c.id_materia)
FROM dbo.profesor p, dbo.cursos c
WHERE p.id_profesor = c.id_profesor
GROUP BY p.nombre;
GO

-- 14) Nota final máxima por curso
SELECT c.nombre_curso, MAX(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso;
GO

-- 15) Nota final mínima por curso
SELECT c.nombre_curso, MIN(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso;
GO

-- 16) Cantidad de cursos asociados a cada materia
SELECT m.nombre_materia, COUNT(c.id_curso)
FROM dbo.materias m, dbo.cursos c
WHERE m.id_materia = c.id_materia
GROUP BY m.nombre_materia;
GO

-- 17) Promedio de créditos por profesor
SELECT p.nombre, AVG(m.creditos)
FROM dbo.profesor p, dbo.cursos c, dbo.materias m
WHERE p.id_profesor = c.id_profesor
AND m.id_materia = c.id_materia
GROUP BY p.nombre;
GO

-- 18) Suma total de notas finales por estudiante
SELECT e.nombre, SUM(i.nota_final)
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
GROUP BY e.nombre;
GO

-- 19) Cantidad de estudiantes en cada curso
SELECT c.nombre_curso, COUNT(i.id_estudiante)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso;
GO

-- 20) Cantidad de cursos que dicta cada profesor
SELECT p.nombre, COUNT(c.id_curso)
FROM dbo.profesor p, dbo.cursos c
WHERE p.id_profesor = c.id_profesor
GROUP BY p.nombre;
GO

-- 21) Cursos con promedio de nota final > 7
SELECT c.nombre_curso, AVG(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING AVG(i.nota_final) > 7;
GO

-- 22) Estudiantes inscritos en 3 o más cursos
SELECT e.nombre, COUNT(i.id_curso)
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
GROUP BY e.nombre
HAVING COUNT(i.id_curso) >= 3;
GO

-- 23) Profesores que dictan más de una materia
SELECT p.nombre, COUNT(DISTINCT c.id_materia)
FROM dbo.profesor p, dbo.cursos c
WHERE p.id_profesor = c.id_profesor
GROUP BY p.nombre
HAVING COUNT(DISTINCT c.id_materia) > 1;
GO

-- 24) Cursos con nota final máxima igual a 10
SELECT c.nombre_curso
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING MAX(i.nota_final) = 10;
GO

-- 25) Cursos con nota final mínima menor a 4
SELECT c.nombre_curso
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING MIN(i.nota_final) < 4;
GO

-- 26) Materias asociadas a más de 2 cursos
SELECT m.nombre_materia, COUNT(c.id_curso)
FROM dbo.materias m, dbo.cursos c
WHERE m.id_materia = c.id_materia
GROUP BY m.nombre_materia
HAVING COUNT(c.id_curso) > 2;
GO

-- 27) Profesores con promedio de créditos >= 4
SELECT p.nombre, AVG(m.creditos)
FROM dbo.profesor p, dbo.cursos c, dbo.materias m
WHERE p.id_profesor = c.id_profesor
AND m.id_materia = c.id_materia
GROUP BY p.nombre
HAVING AVG(m.creditos) >= 4;
GO

-- 28) Estudiantes con suma de notas finales > 20
SELECT e.nombre, SUM(i.nota_final)
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
GROUP BY e.nombre
HAVING SUM(i.nota_final) > 20;
GO

-- 29) Cursos con más de 5 inscriptos
SELECT c.nombre_curso, COUNT(i.id_estudiante)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING COUNT(i.id_estudiante) > 5;
GO

-- 30) Profesores que dictan 2 o más cursos
SELECT p.nombre, COUNT(c.id_curso)
FROM dbo.profesor p, dbo.cursos c
WHERE p.id_profesor = c.id_profesor
GROUP BY p.nombre
HAVING COUNT(c.id_curso) >= 2;
GO

-- 31) Cursos con promedio de nota final superior al promedio general
SELECT c.nombre_curso, AVG(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING AVG(i.nota_final) > (SELECT AVG(nota_final) FROM dbo.inscripciones);
GO

-- 32) Estudiantes inscriptos en más cursos que el promedio
SELECT e.nombre, COUNT(i.id_curso)
FROM dbo.estudiante e, dbo.inscripciones i
WHERE e.id_estudiante = i.id_estudiante
GROUP BY e.nombre
HAVING COUNT(i.id_curso) > (SELECT AVG(cant) FROM (SELECT COUNT(*) AS cant FROM dbo.inscripciones GROUP BY id_estudiante) AS sub);
GO

-- 33) Profesores que dictan más materias que el promedio general
SELECT p.nombre, COUNT(DISTINCT c.id_materia)
FROM dbo.profesor p, dbo.cursos c
WHERE p.id_profesor = c.id_profesor
GROUP BY p.nombre
HAVING COUNT(DISTINCT c.id_materia) > (SELECT AVG(cant) FROM (SELECT COUNT(DISTINCT id_materia) AS cant FROM dbo.cursos GROUP BY id_profesor) AS sub);
GO

-- 34) Cursos con suma de notas finales superior a la suma máxima
SELECT c.nombre_curso, SUM(i.nota_final)
FROM dbo.cursos c, dbo.inscripciones i
WHERE c.id_curso = i.id_curso
GROUP BY c.nombre_curso
HAVING SUM(i.nota_final) > (SELECT MAX(suma_total) FROM (SELECT SUM(nota_final) AS suma_total FROM dbo.inscripciones GROUP BY id_curso) AS sub);
GO

-- 35) Materias asociadas a más cursos que el promedio general
SELECT m.nombre_materia, COUNT(c.id_curso)
FROM dbo.materias m, dbo.cursos c
WHERE m.id_materia = c.id_materia
GROUP BY m.nombre_materia
HAVING COUNT(c.id_curso) > (SELECT AVG(cant) FROM (SELECT COUNT(*) AS cant FROM dbo.cursos GROUP BY id_materia) AS sub);
GO

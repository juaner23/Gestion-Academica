USE creacion;
GO


INSERT INTO dbo.estudiante (id_estudiante, nombre, apellido, email)
VALUES 
(1, 'Juan', 'Pérez', 'juan.perez@email.com'),
(2, 'María', 'González', 'maria.gonzalez@email.com'),
(3, 'Luis', 'Rodríguez', 'luis.rodriguez@email.com'),
(4, 'Sofía', 'Martínez', 'sofia.martinez@email.com'),
(5, 'Carlos', 'López', 'carlos.lopez@email.com');


INSERT INTO dbo.profesor (id_profesor, nombre, apellido, especialidad)
VALUES
(1, 'Carlos', 'Sánchez', 'Matemática'),
(2, 'Ana', 'Martínez', 'Programación'),
(3, 'Roberto', 'López', 'Física'),
(4, 'Laura', 'Gómez', 'Química'),
(5, 'Diego', 'Fernández', 'Historia');


INSERT INTO dbo.materias (id_materia, nombre_materia, creditos)
VALUES
(1, 'Algoritmos y Estructuras de Datos', 6),
(2, 'Bases de Datos', 5),
(3, 'Física I', 4),
(4, 'Química General', 4),
(5, 'Historia Moderna', 3);


INSERT INTO dbo.cursos (id_curso, nombre_curso, descripcion, anio, id_profesor, id_materia)
VALUES
(1, 'Algoritmos Avanzados', 'Curso avanzado de algoritmos', 2025, 1, 1),
(2, 'SQL y Bases de Datos', 'Introducción a SQL', 2025, 2, 2),
(3, 'Física General', 'Curso de Física I', 2025, 3, 3),
(4, 'Química Básica', 'Introducción a Química', 2025, 4, 4),
(5, 'Historia Contemporánea', 'Estudio de historia moderna', 2025, 5, 5);


INSERT INTO dbo.inscripciones (id_estudiante, id_curso, fecha_inscripcion, nota_teorica, nota_practica, nota_final)
VALUES
(1, 1, '2025-08-29', 8.5, 9.0, 8.75),
(2, 2, '2025-08-29', 7.0, 8.0, 7.5),
(3, 3, '2025-08-29', 6.5, 7.0, 6.75),
(4, 4, '2025-08-29', 9.0, 8.5, 8.75),
(5, 5, '2025-08-29', 8.0, 7.5, 7.75),
(1, 2, '2025-08-29', 9.0, 9.5, 9.25),
(2, 3, '2025-08-29', 7.5, 7.0, 7.25),
(3, 4, '2025-08-29', 6.0, 6.5, 6.25),
(4, 5, '2025-08-29', 8.5, 8.0, 8.25),
(5, 1, '2025-08-29', 7.5, 8.0, 7.75);

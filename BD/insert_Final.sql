USE GestionAcademicaNueva;
GO

-- INSERT en orden ajustado para evitar errores de FK

-- 1. Tablas sin dependencias
-- Estudiante (original + anio_ingreso)
INSERT INTO creacion.estudiante (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email, anio_ingreso)
VALUES 
('Juan', 'Pérez', '40123456', '2000-05-10', 'Av. Siempre Viva 123', '1112345678', 'juan.perez@email.com', 2020),
('María', 'González', '40234567', '2001-07-12', 'Calle Falsa 456', '1123456789', 'maria.gonzalez@email.com', 2021),
('Luis', 'Rodríguez', '40345678', '1999-03-25', 'Belgrano 789', '1134567890', 'luis.rodriguez@email.com', 2019),
('Sofía', 'Martínez', '40456789', '2002-09-01', 'Rivadavia 321', '1145678901', 'sofia.martinez@email.com', 2022),
('Carlos', 'López', '40567890', '2000-12-14', 'Mitre 654', '1156789012', 'carlos.lopez@email.com', 2020);
GO

-- Profesor (nueva)
INSERT INTO creacion.profesor (nombre, apellido, especialidad)
VALUES 
('Ana', 'Torres', 'Informática'),
('Pedro', 'Sánchez', 'Bases de Datos'),
('Laura', 'Ramírez', 'Física'),
('Miguel', 'Fernández', 'Química'),
('Elena', 'Gómez', 'Historia');
GO

-- Cuatrimestre (nueva)
INSERT INTO creacion.cuatrimestre (nombre, fecha_inicio, fecha_fin)
VALUES 
('Cuatrimestre 1 - 2023', '2023-03-01', '2023-06-30'),
('Cuatrimestre 2 - 2023', '2023-08-01', '2023-11-30');
GO

-- Interes_por_mora (nueva)
INSERT INTO creacion.interes_por_mora (anio_carrera, porcentaje_interes)
VALUES 
(1, 5.00),
(2, 6.00),
(3, 7.00),
(4, 8.00),
(5, 9.00);
GO

-- 2. Curso (original + descripcion, id_profesor, id_materia = NULL temporalmente para romper ciclo)
INSERT INTO creacion.curso (nombre, anio, cupo_maximo, descripcion, id_profesor, id_materia)
VALUES
('Algoritmos Avanzados', 1, 30, 'Curso avanzado de algoritmos', 1, NULL),  -- id_profesor 1 (Ana), id_materia NULL temporal
('SQL y Bases de Datos', 1, 25, 'Introducción a SQL', 2, NULL),  -- id_profesor 2 (Pedro)
('Física General', 1, 20, 'Conceptos básicos de física', 3, NULL),  -- id_profesor 3 (Laura)
('Química Básica', 1, 20, 'Química introductoria', 4, NULL),  -- id_profesor 4 (Miguel)
('Historia Contemporánea', 1, 30, 'Historia del siglo XX', 5, NULL);  -- id_profesor 5 (Elena)
GO

-- 3. Materia (original + creditos, costo_curso_mensual; referencia a cursos existentes)
INSERT INTO creacion.materia (nombre, id_curso, creditos, costo_curso_mensual)
VALUES
('Algoritmos y Estructuras de Datos', 1, 4, 1000.00),
('Bases de Datos', 2, 5, 1200.00),
('Física I', 3, 6, 1500.00),
('Química General', 4, 4, 1100.00),
('Historia Moderna', 5, 3, 900.00);
GO

-- 4. UPDATE cursos ⬤
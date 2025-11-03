USE GestionAcademicaNueva;
GO

MERGE INTO creacion.estudiante AS target
USING (VALUES 
    ('Juan', 'Pérez', '40123456', '2000-05-10', 'Av. Siempre Viva 123', '1112345678', 'juan.perez@email.com', 2020),
    ('María', 'González', '40234567', '2001-07-12', 'Calle Falsa 456', '1123456789', 'maria.gonzalez@email.com', 2021),
    ('Luis', 'Rodríguez', '40345678', '1999-03-25', 'Belgrano 789', '1134567890', 'luis.rodriguez@email.com', 2019),
    ('Sofía', 'Martínez', '40456789', '2002-09-01', 'Rivadavia 321', '1145678901', 'sofia.martinez@email.com', 2022),
    ('Carlos', 'López', '40567890', '2000-12-14', 'Mitre 654', '1156789012', 'carlos.lopez@email.com', 2020)
) AS source (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email, anio_ingreso)
ON target.dni = source.dni
WHEN NOT MATCHED THEN
    INSERT (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email, anio_ingreso)
    VALUES (source.nombre, source.apellido, source.dni, source.fecha_nacimiento, source.direccion, source.telefono, source.email, source.anio_ingreso);
GO

INSERT INTO creacion.profesor (nombre, apellido, especialidad)
VALUES 
('Ana', 'Torres', 'Informática'),
('Pedro', 'Sánchez', 'Bases de Datos'),
('Laura', 'Ramírez', 'Física'),
('Miguel', 'Fernández', 'Química'),
('Elena', 'Gómez', 'Historia');
GO

INSERT INTO creacion.cuatrimestre (nombre, fecha_inicio, fecha_fin)
VALUES 
('Cuatrimestre 1 - 2023', '2023-03-01', '2023-06-30'),
('Cuatrimestre 2 - 2023', '2023-08-01', '2023-11-30');
GO

MERGE INTO creacion.interes_por_mora AS target
USING (VALUES 
    (1, 5.00),
    (2, 6.00),
    (3, 7.00),
    (4, 8.00),
    (5, 9.00)
) AS source (anio_carrera, porcentaje_interes)
ON target.anio_carrera = source.anio_carrera
WHEN NOT MATCHED THEN
    INSERT (anio_carrera, porcentaje_interes)
    VALUES (source.anio_carrera, source.porcentaje_interes);
GO

INSERT INTO creacion.curso (nombre, anio, cupo_maximo, descripcion, id_profesor, id_materia)
VALUES
('Algoritmos Avanzados', 1, 30, 'Curso avanzado de algoritmos', 1, NULL),
('SQL y Bases de Datos', 1, 25, 'Introducción a SQL', 2, NULL),
('Física General', 1, 20, 'Conceptos básicos de física', 3, NULL),
('Química Básica', 1, 20, 'Química introductoria', 4, NULL),
('Historia Contemporánea', 1, 30, 'Historia del siglo XX', 5, NULL);
GO

INSERT INTO creacion.materia (nombre, id_curso, creditos, costo_curso_mensual)
VALUES
('Algoritmos y Estructuras de Datos', 1, 4, 1000.00),
('Bases de Datos', 2, 5, 1200.00),
('Física I', 3, 6, 1500.00),
('Química General', 4, 4, 1100.00),
('Historia Moderna', 5, 3, 900.00);
GO

UPDATE creacion.curso SET id_materia = 1 WHERE id_curso = 1;
UPDATE creacion.curso SET id_materia = 2 WHERE id_curso = 2;
UPDATE creacion.curso SET id_materia = 3 WHERE id_curso = 3;
UPDATE creacion.curso SET id_materia = 4 WHERE id_curso = 4;
UPDATE creacion.curso SET id_materia = 5 WHERE id_curso = 5;
GO

INSERT INTO creacion.inscripcion (id_estudiante, id_materia, nota_final, id_curso, nota_teorica_1, nota_teorica_2, nota_practica, nota_teorica_recuperatorio)
VALUES
(1, 1, 8.75, 1, 8.0, 9.0, 8.5, NULL),
(2, 2, 7.5, 2, 7.0, 7.5, 8.0, NULL),
(3, 3, 6.75, 3, 6.0, 7.0, 7.5, 6.5),
(4, 4, 8.75, 4, 8.5, 9.0, 8.0, NULL),
(5, 5, 7.75, 5, 7.0, 8.0, 8.5, NULL),
(1, 2, 9.25, 2, 9.0, 9.5, 9.0, NULL),
(2, 3, 7.25, 3, 7.0, 7.0, 7.5, NULL),
(3, 4, 6.25, 4, 6.0, 6.0, 6.5, 7.0),
(4, 5, 8.25, 5, 8.0, 8.5, 8.0, NULL),
(5, 1, 7.75, 1, 7.5, 7.5, 8.0, NULL);
GO

INSERT INTO creacion.CuentaCorriente (id_estudiante, descripcion, monto, concepto, estado)
VALUES
(1, 'Pago cuota 1', 5000, 'Cuota mensual', 'Pagado'),
(2, 'Pago cuota 1', 4500, 'Cuota mensual', 'Pagado'),
(3, 'Pago cuota 1', 4000, 'Cuota mensual', 'Pendiente'),
(4, 'Pago cuota 1', 4800, 'Cuota mensual', 'Pagado'),
(5, 'Pago cuota 1', 4700, 'Cuota mensual', 'Pendiente');
GO

INSERT INTO creacion.factura (id_estudiante, total, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
VALUES
(1, 5000, 3, 2023, GETDATE(), DATEADD(DAY, 30, GETDATE()), 5000, 'Pagada'),
(2, 4500, 3, 2023, GETDATE(), DATEADD(DAY, 30, GETDATE()), 4500, 'Pagada'),
(3, 4000, 3, 2023, GETDATE(), DATEADD(DAY, 30, GETDATE()), 4000, 'Vencida'),
(4, 4800, 3, 2023, GETDATE(), DATEADD(DAY, 30, GETDATE()), 4800, 'Pagada'),
(5, 4700, 3, 2023, GETDATE(), DATEADD(DAY, 30, GETDATE()), 4700, 'Pendiente');
GO

INSERT INTO creacion.cuota (id_estudiante, id_cuatrimestre, id_factura, mes, monto, fecha_vencimiento, estado_pago)
VALUES 
(1, 1, 1, 3, 1000.00, '2023-03-31', 'Pagada'),
(2, 1, 2, 3, 900.00, '2023-03-31', 'Pagada'),
(3, 1, 3, 3, 800.00, '2023-03-31', 'Vencida'),
(4, 2, 4, 8, 960.00, '2023-08-31', 'Pagada'),
(5, 2, 5, 8, 940.00, '2023-08-31', 'Pendiente');
GO

INSERT INTO creacion.matriculacion (id_estudiante, anio, fecha_pago, monto, estado_pago)
VALUES 
(1, 2023, '2023-02-15', 2000.00, 'Pagada'),
(2, 2023, '2023-02-16', 1800.00, 'Pagada'),
(3, 2023, '2023-02-17', 1600.00, 'Pendiente'),
(4, 2023, '2023-02-18', 1920.00, 'Pagada'),
(5, 2023, '2023-02-19', 1880.00, 'Pendiente');
GO

INSERT INTO creacion.itemfactura (id_factura, id_curso)
VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);
GO

PRINT 'Datos insertados correctamente.';
GO
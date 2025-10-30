USE GestionAcademicaNueva;
GO

INSERT INTO creacion.estudiante (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email)
VALUES 
('Juan', 'Pérez', '40123456', '2000-05-10', 'Av. Siempre Viva 123', '1112345678', 'juan.perez@email.com'),
('María', 'González', '40234567', '2001-07-12', 'Calle Falsa 456', '1123456789', 'maria.gonzalez@email.com'),
('Luis', 'Rodríguez', '40345678', '1999-03-25', 'Belgrano 789', '1134567890', 'luis.rodriguez@email.com'),
('Sofía', 'Martínez', '40456789', '2002-09-01', 'Rivadavia 321', '1145678901', 'sofia.martinez@email.com'),
('Carlos', 'López', '40567890', '2000-12-14', 'Mitre 654', '1156789012', 'carlos.lopez@email.com');
GO

INSERT INTO creacion.curso (nombre, anio, cupo_maximo)
VALUES
('Algoritmos Avanzados', 1, 30),
('SQL y Bases de Datos', 1, 25),
('Física General', 1, 20),
('Química Básica', 1, 20),
('Historia Contemporánea', 1, 30);
GO

INSERT INTO creacion.materia (nombre, id_curso)
VALUES
('Algoritmos y Estructuras de Datos', 1),
('Bases de Datos', 2),
('Física I', 3),
('Química General', 4),
('Historia Moderna', 5);
GO

INSERT INTO creacion.inscripcion (id_estudiante, id_materia, nota_final)
VALUES
(1, 1, 8.75),
(2, 2, 7.5),
(3, 3, 6.75),
(4, 4, 8.75),
(5, 5, 7.75),
(1, 2, 9.25),
(2, 3, 7.25),
(3, 4, 6.25),
(4, 5, 8.25),
(5, 1, 7.75);
GO

INSERT INTO creacion.CuentaCorriente (id_estudiante, descripcion, monto)
VALUES
(1, 'Pago cuota 1', 5000),
(2, 'Pago cuota 1', 4500),
(3, 'Pago cuota 1', 4000),
(4, 'Pago cuota 1', 4800),
(5, 'Pago cuota 1', 4700);
GO

INSERT INTO creacion.factura (id_estudiante, total)
VALUES
(1, 5000),
(2, 4500),
(3, 4000),
(4, 4800),
(5, 4700);
GO

PRINT 'Datos insertados correctamente.';
GO
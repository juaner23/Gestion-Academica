CREATE DATABASE GestionAcademicaNueva;
GO

-- Seleccionar la base
USE GestionAcademicaNueva;
GO

-- Crear esquema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'creacion')
    EXEC('CREATE SCHEMA creacion');
GO

-- Tablas
CREATE TABLE creacion.estudiante (
    id_estudiante INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    dni CHAR(8) NOT NULL UNIQUE,
    fecha_nacimiento DATE,
    direccion NVARCHAR(100),
    telefono NVARCHAR(20),
    email NVARCHAR(100)
);
GO

CREATE TABLE creacion.curso (
    id_curso INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    anio INT CHECK (anio BETWEEN 1 AND 7),
    cupo_maximo INT NOT NULL,
    cupo_ocupado INT DEFAULT 0
);
GO

CREATE TABLE creacion.materia (
    id_materia INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    id_curso INT NOT NULL,
    CONSTRAINT fk_materia_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso)
);
GO

CREATE TABLE creacion.inscripcion (
    id_inscripcion INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_materia INT NOT NULL,
    fecha_inscripcion DATE DEFAULT GETDATE(),
    nota_final DECIMAL(4,2),
    CONSTRAINT fk_inscripcion_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante),
    CONSTRAINT fk_inscripcion_materia FOREIGN KEY (id_materia) REFERENCES creacion.materia(id_materia)
);
GO

CREATE TABLE creacion.CuentaCorriente (
    id_movimiento INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    fecha DATETIME DEFAULT GETDATE(),
    descripcion NVARCHAR(200),
    monto DECIMAL(10,2),
    CONSTRAINT fk_cc_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);
GO

CREATE TABLE creacion.factura (
    id_factura INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    fecha DATETIME DEFAULT GETDATE(),
    total DECIMAL(10,2),
    CONSTRAINT fk_factura_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);
GO

-- Funciones
CREATE OR ALTER FUNCTION creacion.fn_NombreCompleto (@id_estudiante INT)
RETURNS NVARCHAR(120)
AS
BEGIN
    DECLARE @nombre NVARCHAR(50), @apellido NVARCHAR(50);
    SELECT @nombre = nombre, @apellido = apellido
    FROM creacion.estudiante
    WHERE id_estudiante = @id_estudiante;
    RETURN (LTRIM(RTRIM(@apellido + ', ' + @nombre)));
END;
GO

CREATE OR ALTER FUNCTION creacion.fn_SaldoCuentaCorriente (@id_estudiante INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @saldo DECIMAL(10,2);
    SELECT @saldo = ISNULL(SUM(monto), 0)
    FROM creacion.CuentaCorriente
    WHERE id_estudiante = @id_estudiante;
    RETURN @saldo;
END;
GO

CREATE OR ALTER FUNCTION creacion.fn_PromedioFinal (@id_estudiante INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @promedio DECIMAL(4,2);
    SELECT @promedio = AVG(nota_final)
    FROM creacion.inscripcion
    WHERE id_estudiante = @id_estudiante AND nota_final IS NOT NULL;
    RETURN @promedio;
END;
GO

CREATE OR ALTER FUNCTION creacion.fn_VacantesDisponibles (@id_curso INT)
RETURNS INT
AS
BEGIN
    DECLARE @cupo_max INT, @ocupado INT;
    SELECT @cupo_max = cupo_maximo, @ocupado = cupo_ocupado
    FROM creacion.curso
    WHERE id_curso = @id_curso;
    RETURN (@cupo_max - @ocupado);
END;
GO

PRINT 'Esquema creacion y funciones creadas correctamente.';
GO
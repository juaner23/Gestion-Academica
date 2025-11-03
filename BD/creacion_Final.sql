-- Fix para que puedan correr este, si ya corrieron el create anterior 
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'GestionAcademicaNueva')
BEGIN
    USE master;
    ALTER DATABASE GestionAcademicaNueva SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GestionAcademicaNueva;
END;
GO

CREATE DATABASE GestionAcademicaNueva;
GO

USE GestionAcademicaNueva;
GO

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'creacion')
    EXEC('DROP SCHEMA creacion');
GO

EXEC('CREATE SCHEMA creacion');
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'estudiante' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.estudiante;
GO

CREATE TABLE creacion.estudiante (
    id_estudiante INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    dni CHAR(8) NOT NULL UNIQUE,
    fecha_nacimiento DATE,
    direccion NVARCHAR(100),
    telefono NVARCHAR(20),
    email NVARCHAR(100),
    anio_ingreso INT 
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'profesor' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.profesor;
GO

CREATE TABLE creacion.profesor (
    id_profesor INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    especialidad NVARCHAR(100)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'curso' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.curso;
GO

CREATE TABLE creacion.curso (
    id_curso INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    anio INT CHECK (anio BETWEEN 1 AND 7),
    cupo_maximo INT NOT NULL,
    cupo_ocupado INT DEFAULT 0,
    descripcion NVARCHAR(255),  -- Agregado
    id_profesor INT,  
    id_materia INT  
);  -- ¡Aquí agregué el ) faltante!
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'materia' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.materia;
GO

CREATE TABLE creacion.materia (
    id_materia INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    id_curso INT NOT NULL,  
    creditos INT, 
    costo_curso_mensual DECIMAL(10,2), 
    CONSTRAINT fk_materia_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso) 
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'inscripcion' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.inscripcion;
GO

CREATE TABLE creacion.inscripcion (
    id_inscripcion INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_materia INT NOT NULL,
    fecha_inscripcion DATE DEFAULT GETDATE(),
    nota_final DECIMAL(4,2),
    id_curso INT,  
    nota_teorica_1 DECIMAL(4,2), 
    nota_teorica_2 DECIMAL(4,2),  
    nota_practica DECIMAL(4,2), 
    nota_teorica_recuperatorio DECIMAL(4,2), 
    CONSTRAINT fk_inscripcion_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante),
    CONSTRAINT fk_inscripcion_materia FOREIGN KEY (id_materia) REFERENCES creacion.materia(id_materia)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CuentaCorriente' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.CuentaCorriente;
GO

CREATE TABLE creacion.CuentaCorriente (
    id_movimiento INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    fecha DATETIME DEFAULT GETDATE(),
    descripcion NVARCHAR(200),
    monto DECIMAL(10,2),
    concepto NVARCHAR(200),  
    estado NVARCHAR(50), 
    CONSTRAINT fk_cc_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'factura' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.factura;
GO

CREATE TABLE creacion.factura (
    id_factura INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    fecha DATETIME DEFAULT GETDATE(),
    total DECIMAL(10,2),
    mes INT,  
    anio INT,  
    fecha_emision DATETIME,  
    fecha_vencimiento DATE,  
    monto_total DECIMAL(10,2),  
    estado_pago NVARCHAR(50),  
    CONSTRAINT fk_factura_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'cuatrimestre' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.cuatrimestre;
GO

CREATE TABLE creacion.cuatrimestre (
    id_cuatrimestre INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50),
    fecha_inicio DATE,
    fecha_fin DATE
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'cuota' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.cuota;
GO

CREATE TABLE creacion.cuota (
    id_cuota INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_cuatrimestre INT NOT NULL,
    id_factura INT NOT NULL,
    mes INT,
    monto DECIMAL(10,2),
    fecha_vencimiento DATE,
    estado_pago NVARCHAR(50),
    CONSTRAINT fk_cuota_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante),
    CONSTRAINT fk_cuota_cuatrimestre FOREIGN KEY (id_cuatrimestre) REFERENCES creacion.cuatrimestre(id_cuatrimestre),
    CONSTRAINT fk_cuota_factura FOREIGN KEY (id_factura) REFERENCES creacion.factura(id_factura)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'matriculacion' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.matriculacion;
GO

CREATE TABLE creacion.matriculacion (
    id_matricula INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante INT NOT NULL,
    anio INT,
    fecha_pago DATE,
    monto DECIMAL(10,2),
    estado_pago NVARCHAR(50),
    CONSTRAINT fk_matriculacion_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'interes_por_mora' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.interes_por_mora;
GO

CREATE TABLE creacion.interes_por_mora (
    anio_carrera INT PRIMARY KEY,
    porcentaje_interes DECIMAL(5,2)
);
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'itemfactura' AND schema_id = SCHEMA_ID('creacion'))
    DROP TABLE creacion.itemfactura;
GO

CREATE TABLE creacion.itemfactura (
    id_factura INT NOT NULL,
    id_curso INT NOT NULL,
    CONSTRAINT PK_itemfactura PRIMARY KEY (id_factura, id_curso),
    CONSTRAINT fk_itemfactura_factura FOREIGN KEY (id_factura) REFERENCES creacion.factura(id_factura),
    CONSTRAINT fk_itemfactura_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso)
);
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'fk_curso_profesor')
BEGIN
    ALTER TABLE creacion.curso
    ADD CONSTRAINT fk_curso_profesor FOREIGN KEY (id_profesor) REFERENCES creacion.profesor(id_profesor);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'fk_curso_materia')
BEGIN
    ALTER TABLE creacion.curso
    ADD CONSTRAINT fk_curso_materia FOREIGN KEY (id_materia) REFERENCES creacion.materia(id_materia);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'fk_inscripcion_curso')
BEGIN
    ALTER TABLE creacion.inscripcion
    ADD CONSTRAINT fk_inscripcion_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso);
END;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_NombreCompleto' AND schema_id = SCHEMA_ID('creacion') AND type = 'FN')
    DROP FUNCTION creacion.fn_NombreCompleto;
GO

CREATE FUNCTION creacion.fn_NombreCompleto (@id_estudiante INT)
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

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_SaldoCuentaCorriente' AND schema_id = SCHEMA_ID('creacion') AND type = 'FN')
    DROP FUNCTION creacion.fn_SaldoCuentaCorriente;
GO

CREATE FUNCTION creacion.fn_SaldoCuentaCorriente (@id_estudiante INT)
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

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_PromedioFinal' AND schema_id = SCHEMA_ID('creacion') AND type = 'FN')
    DROP FUNCTION creacion.fn_PromedioFinal;
GO

CREATE FUNCTION creacion.fn_PromedioFinal (@id_estudiante INT)
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

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_VacantesDisponibles' AND schema_id = SCHEMA_ID('creacion') AND type = 'FN')
    DROP FUNCTION creacion.fn_VacantesDisponibles;
GO

CREATE FUNCTION creacion.fn_VacantesDisponibles (@id_curso INT)
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


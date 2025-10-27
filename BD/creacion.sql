USE master;
GO
IF DB_ID('GestionAcademica') IS NULL
    CREATE DATABASE GestionAcademica;
GO
USE GestionAcademica;
GO

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'DROP TABLE creacion.' + QUOTENAME(t.name) + ';'
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'creacion';
EXEC sp_executesql @sql;

IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'creacion')
    DROP SCHEMA creacion;
GO

CREATE SCHEMA creacion;
GO

USE GestionAcademica;
GO

CREATE TABLE creacion.estudiante(
    id_estudiante INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    anio_ingreso INT,
    CONSTRAINT pk_estudiante PRIMARY KEY (id_estudiante)
);

CREATE TABLE creacion.profesor(
    id_profesor INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    especialidad VARCHAR(50),
    CONSTRAINT pk_profesor PRIMARY KEY (id_profesor)
);

CREATE TABLE creacion.materia(
    id_materia INT NOT NULL,
    nombre_materia VARCHAR(100) NOT NULL,
    creditos INT NOT NULL,
    costo_curso_mensual DECIMAL(10,2),
    CONSTRAINT pk_materia PRIMARY KEY (id_materia),
    CONSTRAINT ck_materia_creditos CHECK (creditos >= 0)
);

CREATE TABLE creacion.curso(
    id_curso INT NOT NULL,
    nombre_curso VARCHAR(100) NOT NULL,
    descripcion TEXT,
    anio INT NOT NULL,
    id_profesor INT NOT NULL,
    id_materia INT NOT NULL,
    CONSTRAINT pk_curso PRIMARY KEY (id_curso),
    CONSTRAINT fk_curso_profesor FOREIGN KEY (id_profesor) REFERENCES creacion.profesor(id_profesor),
    CONSTRAINT fk_curso_materia FOREIGN KEY (id_materia) REFERENCES creacion.materia(id_materia),
    CONSTRAINT ck_curso_anio CHECK (anio >= 2000)
);

CREATE TABLE creacion.inscripcion(
    id_estudiante INT NOT NULL,
    id_curso INT NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    nota_teorica_1 DECIMAL(4,2),
    nota_teorica_2 DECIMAL(4,2),
    nota_practica DECIMAL(4,2),
    nota_teorica_recuperatorio DECIMAL(4,2),
    nota_final DECIMAL(4,2),
    CONSTRAINT pk_inscripcion PRIMARY KEY (id_estudiante, id_curso),
    CONSTRAINT fk_inscripcion_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante),
    CONSTRAINT fk_inscripcion_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso)
);

CREATE TABLE creacion.cuatrimestre(
    id_cuatrimestre INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CONSTRAINT pk_cuatrimestre PRIMARY KEY (id_cuatrimestre)
);

CREATE TABLE creacion.factura(
    id_factura INT NOT NULL,
    id_estudiante INT NOT NULL,
    mes INT,
    anio INT,
    fecha_emision DATE,
    fecha_vencimiento DATE,
    monto_total DECIMAL(10,2),
    estado_pago VARCHAR(20),
    CONSTRAINT pk_factura PRIMARY KEY (id_factura),
    CONSTRAINT fk_factura_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);

CREATE TABLE creacion.cuota(
    id_cuota INT NOT NULL,
    id_estudiante INT NOT NULL,
    id_cuatrimestre INT NOT NULL,
    id_factura INT NOT NULL,
    mes INT NOT NULL,
    monto DECIMAL(10,2),
    fecha_vencimiento DATE,
    estado_pago VARCHAR(20),
    CONSTRAINT pk_cuota PRIMARY KEY (id_cuota),
    CONSTRAINT fk_cuota_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante),
    CONSTRAINT fk_cuota_cuatrimestre FOREIGN KEY (id_cuatrimestre) REFERENCES creacion.cuatrimestre(id_cuatrimestre),
    CONSTRAINT fk_cuota_factura FOREIGN KEY (id_factura) REFERENCES creacion.factura(id_factura)
);

CREATE TABLE creacion.matriculacion(
    id_matricula INT NOT NULL,
    id_estudiante INT NOT NULL,
    anio INT,
    fecha_pago DATE,
    monto DECIMAL(10,2),
    estado_pago VARCHAR(20),
    CONSTRAINT pk_matriculacion PRIMARY KEY (id_matricula),
    CONSTRAINT fk_matriculacion_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);

CREATE TABLE creacion.cuenta_corriente(
    id_movimiento INT NOT NULL,
    id_estudiante INT NOT NULL,
    fecha DATE,
    concepto VARCHAR(200),
    monto DECIMAL(10,2),
    estado VARCHAR(20),
    CONSTRAINT pk_cuenta_corriente PRIMARY KEY (id_movimiento),
    CONSTRAINT fk_cuenta_corriente_estudiante FOREIGN KEY (id_estudiante) REFERENCES creacion.estudiante(id_estudiante)
);

CREATE TABLE creacion.interes_por_mora(
    anio_carrera INT NOT NULL,
    porcentaje_interes DECIMAL(5,2),
    CONSTRAINT pk_interes_por_mora PRIMARY KEY (anio_carrera)
);

CREATE TABLE creacion.item_factura(
    id_factura INT NOT NULL,
    id_curso INT NOT NULL,
    CONSTRAINT pk_item_factura PRIMARY KEY (id_factura, id_curso),
    CONSTRAINT fk_item_factura_factura FOREIGN KEY (id_factura) REFERENCES creacion.factura(id_factura),
    CONSTRAINT fk_item_factura_curso FOREIGN KEY (id_curso) REFERENCES creacion.curso(id_curso)
);

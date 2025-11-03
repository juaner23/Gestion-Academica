-- Archivo: funciones.sql
-- Autor: Tomas

use GestionAcademicaNueva;
GO


--1
--Determinar el estado de pago de una cuota específica de un estudiante.

USE GestionAcademicaNueva;
GO

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




--2
--Obtener la especialidad de un profesor dado el nombre del profesor.

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

--3
--Calcular el monto total adeudado por un estudiante pasándole el nombre como parámetro. 
--Si existe más de un estudiante con ese nombre devolver -1.
CREATE OR ALTER FUNCTION creacion.fn_MontoAdeudado (@nombre NVARCHAR(50))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*) FROM creacion.estudiante WHERE nombre = @nombre;

    IF @count > 1
        RETURN -1;

    DECLARE @adeudado DECIMAL(10,2);
    SELECT @adeudado = ISNULL(SUM(CASE WHEN monto < 0 THEN monto ELSE 0 END), 0)
    FROM creacion.CuentaCorriente cc
    INNER JOIN creacion.estudiante e ON cc.id_estudiante = e.id_estudiante
    WHERE e.nombre = @nombre;
    RETURN @adeudado;
END;
GO

SELECT creacion.fn_EstadoPagoCuota(1, 1) AS Estado;
SELECT creacion.fn_EspecialidadProfesor('Ana') AS Especialidad;
SELECT creacion.fn_MontoAdeudado('Juan') AS Adeudado;


USE GestionAcademicaNueva;
GO


--Crear un procedimiento que permita registrar un pago a un alumno determinado.
CREATE OR ALTER PROCEDURE creacion.sp_RegistrarPago
    @id_estudiante INT,
    @monto DECIMAL(10,2),
    @concepto NVARCHAR(200),
    @fecha DATETIME = NULL
AS
BEGIN
    IF @fecha IS NULL SET @fecha = GETDATE();

    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, monto, concepto, estado)
    VALUES (@id_estudiante, @fecha, @monto, @concepto, 'Pagado');
END;
GO

--Crear un procedimiento que calcule los intereses por mora para los alumnos que adeudan más de un mes de cuota.

USE GestionAcademicaNueva;
GO

CREATE OR ALTER PROCEDURE creacion.sp_CalcularInteresesPorMora
AS
BEGIN
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, monto, concepto, estado)
    SELECT 
        c.id_estudiante,
        GETDATE(),
        c.monto * (i.porcentaje_interes / 100),  
        'Interés por mora cuota ' + CAST(c.mes AS NVARCHAR) + '/' + CAST(c.anio AS NVARCHAR),
        'Pendiente'
    FROM creacion.cuota c
    INNER JOIN creacion.estudiante e ON c.id_estudiante = e.id_estudiante
    INNER JOIN creacion.interes_por_mora i ON e.anio_ingreso = i.anio_carrera  
    WHERE c.estado_pago != 'Pagada' 
      AND c.fecha_vencimiento < DATEADD(DAY, -30, GETDATE());  
END;
GO


--Crear un procedimiento que permita generar la cuota de un alumno determinado para un mes del cuatrimestre actual
--generando para ello la facturación y el cargo correspondiente a la cuenta corriente.

CREATE OR ALTER PROCEDURE creacion.sp_GenerarCuotaAlumno
    @id_estudiante INT,
    @mes INT
AS
BEGIN
    DECLARE @id_cuatrimestre INT = (SELECT TOP 1 id_cuatrimestre FROM creacion.cuatrimestre WHERE fecha_inicio <= GETDATE() AND fecha_fin >= GETDATE());
    DECLARE @anio INT = YEAR(GETDATE());
    DECLARE @monto DECIMAL(10,2) = 1000.00;  -- Monto fijo; ajusta si querés cálculo real
    DECLARE @fecha_vencimiento DATE = EOMONTH(DATEFROMPARTS(@anio, @mes, 1));  -- Fin del mes

    -- Generar cuota
    DECLARE @id_factura INT;
    INSERT INTO creacion.factura (id_estudiante, fecha_emision, monto_total, mes, anio, fecha_vencimiento, estado_pago)
    VALUES (@id_estudiante, GETDATE(), @monto, @mes, @anio, @fecha_vencimiento, 'Pendiente');
    SET @id_factura = SCOPE_IDENTITY();  -- Obtener ID de factura generada

    INSERT INTO creacion.cuota (id_estudiante, id_cuatrimestre, id_factura, mes, monto, fecha_vencimiento, estado_pago)
    VALUES (@id_estudiante, @id_cuatrimestre, @id_factura, @mes, @monto, @fecha_vencimiento, 'Pendiente');

    -- Cargo en cuenta corriente
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, monto, concepto, estado)
    VALUES (@id_estudiante, GETDATE(), @monto, 'Cuota ' + CAST(@mes AS NVARCHAR) + '/' + CAST(@anio AS NVARCHAR), 'Pendiente');
END;
GO




-- Listar los estudiantes con cuotas vencidas.
CREATE OR ALTER FUNCTION creacion.fn_ListarEstudiantesConCuotasVencidas ()
RETURNS TABLE
AS
RETURN
    SELECT DISTINCT
        e.id_estudiante,
        e.nombre AS nombre_estudiante,
        e.apellido AS apellido_estudiante,
        cu.id_cuota,
        cu.mes,
        cu.monto,
        cu.fecha_vencimiento
    FROM creacion.estudiante e
    INNER JOIN creacion.cuota cu ON e.id_estudiante = cu.id_estudiante
    WHERE cu.estado_pago = 'Vencida';
GO

-- Mostrar los cursos con su cantidad de inscriptos.
CREATE OR ALTER FUNCTION creacion.fn_MostrarCursosConInscriptos ()
RETURNS TABLE
AS
RETURN
    SELECT 
        c.id_curso,
        c.nombre AS nombre_curso,
        c.anio,
        COUNT(i.id_inscripcion) AS cantidad_inscriptos
    FROM creacion.curso c
    LEFT JOIN creacion.inscripcion i ON c.id_curso = i.id_curso
    GROUP BY c.id_curso, c.nombre, c.anio;
GO

-- Listar las facturas agrupadas por estado de pago.
CREATE OR ALTER FUNCTION creacion.fn_ListarFacturasAgrupadasPorEstado ()
RETURNS TABLE
AS
RETURN
    SELECT 
        estado_pago,
        COUNT(*) AS cantidad_facturas,
        SUM(monto_total) AS total_monto
    FROM creacion.factura
    GROUP BY estado_pago;
GO
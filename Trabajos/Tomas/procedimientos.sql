-- Archivo: procedimientos.sql
-- Autor: Tomas

use GestionAcademicaNueva;
GO

--1
--Crear un procedimiento almacenado (uno para cada uno) para cargar datos los conceptos de alumnos, materias, cursos, 
--profesores, cuatrimestres e intereses por mora (este solo carga un registro para cada año de la carrera,
--si el año existe se actualiza.)
--ALUMNO

CREATE OR ALTER PROCEDURE creacion.sp_CargarAlumno
    @nombre NVARCHAR(50),
    @apellido NVARCHAR(50),
    @dni CHAR(8),
    @fecha_nacimiento DATE = NULL,
    @direccion NVARCHAR(100) = NULL,
    @telefono NVARCHAR(20) = NULL,
    @email NVARCHAR(100) = NULL,
    @anio_ingreso INT = NULL
AS
BEGIN
    INSERT INTO creacion.estudiante (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email, anio_ingreso)
    VALUES (@nombre, @apellido, @dni, @fecha_nacimiento, @direccion, @telefono, @email, @anio_ingreso);
END;
GO


--MATERIA
CREATE OR ALTER PROCEDURE creacion.sp_CargarMateria
    @nombre NVARCHAR(100),
    @id_curso INT,
    @creditos INT = NULL,
    @costo_curso_mensual DECIMAL(10,2) = NULL
AS
BEGIN
    INSERT INTO creacion.materia (nombre, id_curso, creditos, costo_curso_mensual)
    VALUES (@nombre, @id_curso, @creditos, @costo_curso_mensual);
END;
GO


--CURSO
CREATE OR ALTER PROCEDURE creacion.sp_CargarCurso
    @nombre NVARCHAR(100),
    @anio INT,
    @cupo_maximo INT,
    @descripcion NVARCHAR(255) = NULL,
    @id_profesor INT = NULL,
    @id_materia INT = NULL
AS
BEGIN
    INSERT INTO creacion.curso (nombre, anio, cupo_maximo, descripcion, id_profesor, id_materia)
    VALUES (@nombre, @anio, @cupo_maximo, @descripcion, @id_profesor, @id_materia);
END;
GO

--PROFESOR
CREATE OR ALTER PROCEDURE creacion.sp_CargarProfesor
    @nombre NVARCHAR(50),
    @apellido NVARCHAR(50),
    @especialidad NVARCHAR(100) = NULL
AS
BEGIN
    INSERT INTO creacion.profesor (nombre, apellido, especialidad)
    VALUES (@nombre, @apellido, @especialidad);
END;
GO

--CUATRIMESTRE
CREATE OR ALTER PROCEDURE creacion.sp_CargarCuatrimestre
    @nombre NVARCHAR(50),
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    INSERT INTO creacion.cuatrimestre (nombre, fecha_inicio, fecha_fin)
    VALUES (@nombre, @fecha_inicio, @fecha_fin);
END;
GO

--INTERESES POR MORA
CREATE OR ALTER PROCEDURE creacion.sp_CargarInteresPorMora
    @anio_carrera INT,
    @porcentaje_interes DECIMAL(5,2)
AS
BEGIN
    MERGE INTO creacion.interes_por_mora AS target
    USING (VALUES (@anio_carrera, @porcentaje_interes)) AS source (anio_carrera, porcentaje_interes)
    ON target.anio_carrera = source.anio_carrera
    WHEN MATCHED THEN
        UPDATE SET porcentaje_interes = source.porcentaje_interes
    WHEN NOT MATCHED THEN
        INSERT (anio_carrera, porcentaje_interes) VALUES (source.anio_carrera, source.porcentaje_interes);
END;
GO

--2
--Crear un procedimiento que permita dar de baja a un alumno. 
--El mismo debe contemplar que la cuenta corriente este en cero para hacerlo. No debe borrarse el historial del alumno, 
--solo indicar que esta de baja.


-- Agregar columna estado a estudiante (si no existe)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'estado' AND object_id = OBJECT_ID('creacion.estudiante'))
BEGIN
    ALTER TABLE creacion.estudiante ADD estado NVARCHAR(50) DEFAULT 'Activo';
END;
GO



CREATE OR ALTER PROCEDURE creacion.sp_DarDeBajaAlumno
    @id_estudiante INT
AS
BEGIN
    DECLARE @saldo DECIMAL(10,2) = creacion.fn_SaldoCuentaCorriente(@id_estudiante);

    IF @saldo <> 0
    BEGIN
        RAISERROR('El saldo de la cuenta corriente debe ser cero para dar de baja.', 16, 1);
        RETURN;
    END

    UPDATE creacion.estudiante
    SET estado = 'Baja'
    WHERE id_estudiante = @id_estudiante;
END;
GO

--3
--Crear un procedimiento que permita volver a dar de alta a un alumno.

CREATE OR ALTER PROCEDURE creacion.sp_DarDeAltaAlumno
    @id_estudiante INT
AS
BEGIN
    UPDATE creacion.estudiante
    SET estado = 'Activo'
    WHERE id_estudiante = @id_estudiante;
END;
GO

--4
--Crear un procedimiento que permita matricular un alumno a un año. Solo se acepta una matricula por año por alumno. 
--El procedimiento además de validar los datos ingresados debe generar la factura correspondiente 
--y el cargo en la cuenta corriente.

USE GestionAcademicaNueva;
GO

CREATE OR ALTER PROCEDURE creacion.sp_MatricularAlumno
    @id_estudiante INT,
    @anio INT,
    @monto DECIMAL(10,2)
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
    BEGIN
        RAISERROR('Estudiante no existe.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM creacion.matriculacion WHERE id_estudiante = @id_estudiante AND anio = @anio)
    BEGIN
        RAISERROR('Ya existe matrícula para ese año.', 16, 1);
        RETURN;
    END

    INSERT INTO creacion.matriculacion (id_estudiante, anio, fecha_pago, monto, estado_pago)
    VALUES (@id_estudiante, @anio, GETDATE(), @monto, 'Pendiente');

    INSERT INTO creacion.factura (id_estudiante, fecha, total, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
    VALUES (@id_estudiante, GETDATE(), @monto, 1, @anio, GETDATE(), DATEADD(MONTH, 1, GETDATE()), @monto, 'Pendiente');

    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    VALUES (@id_estudiante, GETDATE(), 'Cargo matrícula', -@monto, 'Matrícula año ' + CAST(@anio AS NVARCHAR), 'Pendiente');
END;
GO


--PROCEDIMIENTOS CON CURSOR 
--1
--Mostrar los intereses por mora aplicados por año de carrera.

USE GestionAcademicaNueva;
GO

CREATE OR ALTER PROCEDURE creacion.sp_ListarInteresesPorMora
AS
BEGIN
    DECLARE @anio_carrera INT, @porcentaje_interes DECIMAL(5,2);

    DECLARE cur CURSOR FOR
        SELECT anio_carrera, porcentaje_interes
        FROM creacion.interes_por_mora
        ORDER BY anio_carrera;

    OPEN cur;
    FETCH NEXT FROM cur INTO @anio_carrera, @porcentaje_interes;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Año de carrera: ' + CAST(@anio_carrera AS NVARCHAR) + ', Interés: ' + CAST(@porcentaje_interes AS NVARCHAR) + '%';
        FETCH NEXT FROM cur INTO @anio_carrera, @porcentaje_interes;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

--2
--Listar los cursos con mayor cantidad de inscripciones.

CREATE OR ALTER PROCEDURE creacion.sp_ListarCursosMasInscripciones
AS
BEGIN
    DECLARE @id_curso INT, @nombre NVARCHAR(100), @cantidad INT;

    DECLARE cur CURSOR FOR
        SELECT c.id_curso, c.nombre, COUNT(i.id_inscripcion) AS cantidad
        FROM creacion.curso c
        LEFT JOIN creacion.inscripcion i ON c.id_curso = i.id_curso
        GROUP BY c.id_curso, c.nombre
        ORDER BY cantidad DESC;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id_curso, @nombre, @cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Curso: ' + @nombre + ', Inscripciones: ' + CAST(@cantidad AS NVARCHAR);
        FETCH NEXT FROM cur INTO @id_curso, @nombre, @cantidad;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

--3
--Mostrar los estudiantes que no tienen matrícula en el año actual


CREATE OR ALTER PROCEDURE creacion.sp_ListarEstudiantesSinMatriculaActual
AS
BEGIN
    DECLARE @id_estudiante INT, @nombre NVARCHAR(50), @apellido NVARCHAR(50);

    DECLARE cur CURSOR FOR
        SELECT e.id_estudiante, e.nombre, e.apellido
        FROM creacion.estudiante e
        LEFT JOIN creacion.matriculacion m ON e.id_estudiante = m.id_estudiante AND m.anio = YEAR(GETDATE())
        WHERE m.id_matricula IS NULL;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id_estudiante, @nombre, @apellido;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Estudiante: ' + @nombre + ' ' + @apellido + ' (ID: ' + CAST(@id_estudiante AS NVARCHAR) + ')';
        FETCH NEXT FROM cur INTO @id_estudiante, @nombre, @apellido;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO


--1
--Listar cuotas vencidas ordenadas por un campo dinámico (fecha_vencimiento, monto, estado_pago).
USE GestionAcademicaNueva;
GO

CREATE OR ALTER PROCEDURE creacion.sp_ListarCuotasVencidasDinamico (@campo_orden NVARCHAR(50))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
        DECLARE cur CURSOR FOR
            SELECT id_cuota, id_estudiante, fecha_vencimiento, monto, estado_pago
            FROM creacion.cuota
            WHERE fecha_vencimiento < GETDATE()
            ORDER BY ' + @campo_orden + ';
        
        DECLARE @id_cuota INT, @id_estudiante INT, @fecha_vencimiento DATE, @monto DECIMAL(10,2), @estado_pago NVARCHAR(50);
        OPEN cur;
        FETCH NEXT FROM cur INTO @id_cuota, @id_estudiante, @fecha_vencimiento, @monto, @estado_pago;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT ''Cuota ID: '' + CAST(@id_cuota AS NVARCHAR) + '', Estudiante: '' + CAST(@id_estudiante AS NVARCHAR) + '', Vencimiento: '' + CAST(@fecha_vencimiento AS NVARCHAR) + '', Monto: '' + CAST(@monto AS NVARCHAR) + '', Estado: '' + @estado_pago;
            FETCH NEXT FROM cur INTO @id_cuota, @id_estudiante, @fecha_vencimiento, @monto, @estado_pago;
        END
        
        CLOSE cur;
        DEALLOCATE cur;';

    EXEC(@sql);
END;
GO

--2
--Mostrar los cursos que cumplen con una condición dinámica (por ejemplo, costo mensual > X, créditos < Y, año = Z).

CREATE OR ALTER PROCEDURE creacion.sp_ListarCursosCondicionDinamica (@condicion NVARCHAR(MAX))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
        DECLARE cur CURSOR FOR
            SELECT id_curso, nombre, anio, costo_curso_mensual, creditos
            FROM creacion.curso c
            INNER JOIN creacion.materia m ON c.id_materia = m.id_materia
            WHERE ' + @condicion + ';
        
        DECLARE @id_curso INT, @nombre NVARCHAR(100), @anio INT, @costo DECIMAL(10,2), @creditos INT;
        OPEN cur;
        FETCH NEXT FROM cur INTO @id_curso, @nombre, @anio, @costo, @creditos;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT ''Curso: '' + @nombre + '' (ID: '' + CAST(@id_curso AS NVARCHAR) + '', Año: '' + CAST(@anio AS NVARCHAR) + '', Costo: '' + CAST(@costo AS NVARCHAR) + '', Créditos: '' + CAST(@creditos AS NVARCHAR) + '')'';
            FETCH NEXT FROM cur INTO @id_curso, @nombre, @anio, @costo, @creditos;
        END
        
        CLOSE cur;
        DEALLOCATE cur;';

    EXEC(@sql);
END;
GO

--3
--Listar profesores que dictan cursos en un cuatrimestre específico, 
--con posibilidad de ordenar por nombre, apellido o especialidad.

CREATE OR ALTER PROCEDURE creacion.sp_ListarProfesoresCuatrimestreDinamico (@id_cuatrimestre INT, @campo_orden NVARCHAR(50))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
        DECLARE cur CURSOR FOR
            SELECT DISTINCT p.id_profesor, p.nombre, p.apellido, p.especialidad
            FROM creacion.profesor p
            INNER JOIN creacion.curso c ON p.id_profesor = c.id_profesor
            INNER JOIN creacion.cuota cu ON c.id_curso = cu.id_curso
            WHERE cu.id_cuatrimestre = ' + CAST(@id_cuatrimestre AS NVARCHAR) + '
            ORDER BY ' + @campo_orden + ';
        
        DECLARE @id_profesor INT, @nombre NVARCHAR(50), @apellido NVARCHAR(50), @especialidad NVARCHAR(100);
        OPEN cur;
        FETCH NEXT FROM cur INTO @id_profesor, @nombre, @apellido, @especialidad;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT ''Profesor: '' + @nombre + '' '' + @apellido + '' (Especialidad: '' + @especialidad + '')'';
            FETCH NEXT FROM cur INTO @id_profesor, @nombre, @apellido, @especialidad;
        END
        
        CLOSE cur;
        DEALLOCATE cur;';

    EXEC(@sql);
END;
GO





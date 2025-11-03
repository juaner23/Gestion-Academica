USE GestionAcademicaNueva;
GO

DROP PROCEDURE IF EXISTS creacion.sp_InscribirAlumnoACurso;
DROP PROCEDURE IF EXISTS creacion.sp_CargarNotaAlumno;
DROP PROCEDURE IF EXISTS creacion.sp_GenerarCuotasTodosAlumnos;
DROP PROCEDURE IF EXISTS creacion.sp_ListarEstudiantesDinamico;
DROP PROCEDURE IF EXISTS creacion.sp_ConsultarInscripcionesNotas;
DROP PROCEDURE IF EXISTS creacion.sp_ListarCursosInscriptosDinamico;
DROP PROCEDURE IF EXISTS creacion.sp_ReporteFacturasDinamico;
GO

-- Agregar campo estado_baja si no existe
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('creacion.estudiante') AND name = 'estado_baja')
BEGIN
    ALTER TABLE creacion.estudiante ADD estado_baja BIT DEFAULT 0;
END;
GO

-- Crear un procedimiento que permita inscribir a un alumno a un curso.
CREATE PROCEDURE creacion.sp_InscribirAlumnoACurso
    @id_estudiante INT,
    @id_curso INT
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante AND ISNULL(estado_baja, 0) = 0)
    BEGIN
        RAISERROR('Estudiante no existe o está dado de baja.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM creacion.curso WHERE id_curso = @id_curso)
    BEGIN
        RAISERROR('Curso no existe.', 16, 1);
        RETURN;
    END

    
    IF EXISTS (SELECT 1 FROM creacion.inscripcion WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso)
    BEGIN
        RAISERROR('El estudiante ya está inscripto en este curso.', 16, 1);
        RETURN;
    END


    DECLARE @id_materia INT, @id_cuatrimestre INT;
    SELECT @id_materia = id_materia FROM creacion.curso WHERE id_curso = @id_curso;
    SELECT TOP 1 @id_cuatrimestre = id_cuatrimestre FROM creacion.cuatrimestre WHERE fecha_inicio <= GETDATE() AND fecha_fin >= GETDATE();

    
    IF EXISTS (
        SELECT 1 FROM creacion.inscripcion I
        INNER JOIN creacion.curso C ON I.id_curso = C.id_curso
        WHERE I.id_estudiante = @id_estudiante AND C.id_materia = @id_materia
    )
    BEGIN
        RAISERROR('El estudiante ya está inscripto en otro curso de la misma materia en este cuatrimestre.', 16, 1);
        RETURN;
    END

 
    INSERT INTO creacion.inscripcion (id_estudiante, id_curso, fecha_inscripcion)
    VALUES (@id_estudiante, @id_curso, GETDATE());

    PRINT 'Inscripción realizada exitosamente.';
END;
GO

-- Crear un procedimiento de le permita cargar nota a un alumno
CREATE PROCEDURE creacion.sp_CargarNotaAlumno
    @id_curso INT,
    @id_estudiante INT,
    @examen VARCHAR(50),
    @nota DECIMAL(4,2)
AS
BEGIN
   
    IF @nota < 0 OR @nota > 10
    BEGIN
        RAISERROR('La nota debe estar entre 0 y 10.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM creacion.inscripcion WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso)
    BEGIN
        RAISERROR('Inscripción no encontrada.', 16, 1);
        RETURN;
    END

   
    IF @examen = 'nota_teorica_recuperatorio'
    BEGIN
        
        IF NOT EXISTS (
            SELECT 1 FROM creacion.inscripcion
            WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso
            AND (nota_teorica_1 < 4 OR nota_teorica_2 < 4 OR nota_practica < 4)
        )
        BEGIN
            RAISERROR('No se puede cargar recuperatorio: ninguna instancia anterior es menor a 4.', 16, 1);
            RETURN;
        END

       
        DECLARE @count_menor4 INT;
        SELECT @count_menor4 = 
            CASE WHEN nota_teorica_1 < 4 THEN 1 ELSE 0 END +
            CASE WHEN nota_teorica_2 < 4 THEN 1 ELSE 0 END +
            CASE WHEN nota_practica < 4 THEN 1 ELSE 0 END
        FROM creacion.inscripcion WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso;

        IF @count_menor4 >= 2
        BEGIN
            RAISERROR('No se puede cargar recuperatorio: dos o más instancias anteriores son menores a 4.', 16, 1);
            RETURN;
        END
    END

   
    DECLARE @sql NVARCHAR(MAX) = 'UPDATE creacion.inscripcion SET ' + @examen + ' = @nota WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso';
    EXEC sp_executesql @sql, N'@nota DECIMAL(4,2), @id_estudiante INT, @id_curso INT', @nota, @id_estudiante, @id_curso;

    PRINT 'Nota cargada exitosamente.';
END;
GO

-- Crear un procedimiento que permita generar las cuotas de todos los alumnos cada mes del cuatrimestre actual
CREATE PROCEDURE creacion.sp_GenerarCuotasTodosAlumnos
AS
BEGIN
    
    DECLARE @id_cuatrimestre INT = (SELECT TOP 1 id_cuatrimestre FROM creacion.cuatrimestre WHERE fecha_inicio <= GETDATE() AND fecha_fin >= GETDATE());

    
    DECLARE cur CURSOR FOR SELECT id_estudiante FROM creacion.estudiante WHERE ISNULL(estado_baja, 0) = 0;
    DECLARE @id_estudiante INT;
    OPEN cur;
    FETCH NEXT FROM cur INTO @id_estudiante;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        
        DECLARE @monto DECIMAL(10,2) = (SELECT SUM(M.costo_curso_mensual) FROM creacion.inscripcion I INNER JOIN creacion.curso C ON I.id_curso = C.id_curso INNER JOIN creacion.materia M ON C.id_materia = M.id_materia WHERE I.id_estudiante = @id_estudiante);
        IF @monto > 0
        BEGIN
            
            DECLARE @id_factura INT;
            IF NOT EXISTS (SELECT 1 FROM creacion.factura WHERE id_estudiante = @id_estudiante AND mes = MONTH(GETDATE()) AND anio = YEAR(GETDATE()))
            BEGIN
                INSERT INTO creacion.factura (id_estudiante, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago) VALUES (@id_estudiante, MONTH(GETDATE()), YEAR(GETDATE()), GETDATE(), DATEADD(DAY, 30, GETDATE()), @monto, 'Pendiente');
                SET @id_factura = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @id_factura = id_factura FROM creacion.factura WHERE id_estudiante = @id_estudiante AND mes = MONTH(GETDATE()) AND anio = YEAR(GETDATE());
            END

            INSERT INTO creacion.cuota (id_estudiante, id_cuatrimestre, id_factura, mes, monto, fecha_vencimiento, estado_pago) VALUES (@id_estudiante, @id_cuatrimestre, @id_factura, MONTH(GETDATE()), @monto, DATEADD(DAY, 30, GETDATE()), 'Pendiente');

            INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado) VALUES (@id_estudiante, GETDATE(), 'Cuota mensual generada', -@monto, 'Cuota mensual', 'Pendiente');
        END
        FETCH NEXT FROM cur INTO @id_estudiante;
    END
    CLOSE cur;
    DEALLOCATE cur;

    PRINT 'Cuotas generadas para todos los alumnos.';
END;
GO

-- Listar estudiantes según un campo de búsqueda variable 
    @campo VARCHAR(50),
    @valor VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM creacion.estudiante WHERE ' + @campo + ' LIKE ''%' + @valor + '%''';
    EXEC sp_executesql @sql;
END;
GO

-- Consultar inscripciones filtrando por una combinación dinámica de notas  y operador
CREATE PROCEDURE creacion.sp_ConsultarInscripcionesNotas
    @campo_nota VARCHAR(50),
    @operador VARCHAR(10),
    @valor DECIMAL(4,2)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM creacion.inscripcion WHERE ' + @campo_nota + ' ' + @operador + ' @valor';
    EXEC sp_executesql @sql, N'@valor DECIMAL(4,2)', @valor;
END;
GO

-- Listar cursos que tengan más de X inscriptos, donde X es un parámetro, y el campo de agrupación puede ser por año, materia o profesor.
CREATE PROCEDURE creacion.sp_ListarCursosInscriptosDinamico
    @X INT,
    @campo_agrupacion VARCHAR(50)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'SELECT ' + @campo_agrupacion + ', COUNT(I.id_estudiante) AS inscriptos FROM creacion.curso C INNER JOIN creacion.inscripcion I ON C.id_curso = I.id_curso GROUP BY ' + @campo_agrupacion + ' HAVING COUNT(I.id_estudiante) > @X';
    EXEC sp_executesql @sql, N'@X INT', @X;
END;
GO

-- Generar un reporte de facturas agrupadas por un campo dinámico (mes, estado_pago, estudiante).
CREATE PROCEDURE creacion.sp_ReporteFacturasDinamico
    @campo_agrupacion VARCHAR(50)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = 'SELECT ' + @campo_agrupacion + ', COUNT(*) AS cantidad FROM creacion.factura GROUP BY ' + @campo_agrupacion;
    EXEC sp_executesql @sql;
END;
GO
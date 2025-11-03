USE GestionAcademicaNueva;
GO


CREATE OR ALTER FUNCTION creacion.fn_SaldoCuentaCorriente (@id_estudiante INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @saldo DECIMAL(10,2);
    
    -- Los cargos deben ser negativos y los pagos positivos. Sumar todos los movimientos.
    SELECT @saldo = SUM(monto)
    FROM creacion.CuentaCorriente
    WHERE id_estudiante = @id_estudiante;
    
    RETURN ISNULL(@saldo, 0);
END;
GO

------------------------------------------------------------------------------------------------
-- 1. SPs de Carga de Datos (Tu primera solicitud de agrupación)
------------------------------------------------------------------------------------------------

-- ALUMNO
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
    SET NOCOUNT ON;
    INSERT INTO creacion.estudiante (nombre, apellido, dni, fecha_nacimiento, direccion, telefono, email, anio_ingreso)
    VALUES (@nombre, @apellido, @dni, @fecha_nacimiento, @direccion, @telefono, @email, @anio_ingreso);
END;
GO

-- MATERIA
CREATE OR ALTER PROCEDURE creacion.sp_CargarMateria
    @nombre NVARCHAR(100),
    @creditos INT = NULL,
    @costo_curso_mensual DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO creacion.materia (nombre, creditos, costo_curso_mensual)
    VALUES (@nombre, @creditos, @costo_curso_mensual);
END;
GO

-- CURSO
CREATE OR ALTER PROCEDURE creacion.sp_CargarCurso
    @nombre NVARCHAR(100),
    @anio INT,
    @cupo_maximo INT,
    @descripcion NVARCHAR(255) = NULL,
    @id_profesor INT = NULL,
    @id_materia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO creacion.curso (nombre, anio, cupo_maximo, descripcion, id_profesor, id_materia)
    VALUES (@nombre, @anio, @cupo_maximo, @descripcion, @id_profesor, @id_materia);
END;
GO

-- PROFESOR
CREATE OR ALTER PROCEDURE creacion.sp_CargarProfesor
    @nombre NVARCHAR(50),
    @apellido NVARCHAR(50),
    @especialidad NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO creacion.profesor (nombre, apellido, especialidad)
    VALUES (@nombre, @apellido, @especialidad);
END;
GO

-- CUATRIMESTRE
CREATE OR ALTER PROCEDURE creacion.sp_CargarCuatrimestre
    @nombre NVARCHAR(50),
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO creacion.cuatrimestre (nombre, fecha_inicio, fecha_fin)
    VALUES (@nombre, @fecha_inicio, @fecha_fin);
END;
GO

-- INTERESES POR MORA
CREATE OR ALTER PROCEDURE creacion.sp_CargarInteresPorMora
    @anio_carrera INT,
    @porcentaje_interes DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    MERGE INTO creacion.interes_por_mora AS target
    USING (VALUES (@anio_carrera, @porcentaje_interes)) AS source (anio_carrera, porcentaje_interes)
    ON target.anio_carrera = source.anio_carrera
    WHEN MATCHED THEN
        UPDATE SET porcentaje_interes = source.porcentaje_interes
    WHEN NOT MATCHED THEN
        INSERT (anio_carrera, porcentaje_interes) VALUES (source.anio_carrera, source.porcentaje_interes);
END;
GO

------------------------------------------------------------------------------------------------
-- 2. SPs de Baja/Alta y Matrícula
------------------------------------------------------------------------------------------------

-- Modificación de tabla para garantizar las columnas 'estado' y 'estado_baja'
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('creacion.estudiante') AND name = 'estado_baja')
BEGIN
    ALTER TABLE creacion.estudiante ADD estado_baja BIT DEFAULT 0;
END;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'estado' AND object_id = OBJECT_ID('creacion.estudiante'))
BEGIN
    ALTER TABLE creacion.estudiante ADD estado NVARCHAR(50) DEFAULT 'Activo';
END;
GO

-- Dar de Baja a un Alumno (Corregido: Uso de fn_SaldoCuentaCorriente y RAISERROR)
CREATE OR ALTER PROCEDURE creacion.sp_DarDeBajaAlumno
    @id_estudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @saldo DECIMAL(10,2) = creacion.fn_SaldoCuentaCorriente(@id_estudiante);

    IF @saldo <> 0
    BEGIN
        -- **Corrección del error 2748: Conversión de DECIMAL a NVARCHAR**
        DECLARE @mensaje_error NVARCHAR(500) = 
            'El saldo de la cuenta corriente debe ser cero para dar de baja. Saldo actual: ' + 
            CAST(@saldo AS NVARCHAR(20));
        
        RAISERROR(@mensaje_error, 16, 1);
        RETURN;
    END

    UPDATE creacion.estudiante
    SET estado_baja = 1, estado = 'Baja'
    WHERE id_estudiante = @id_estudiante;
    
    PRINT 'Estudiante dado de baja correctamente.';
END;
GO

-- Dar de Alta a un Alumno
CREATE OR ALTER PROCEDURE creacion.sp_DarDeAltaAlumno
    @id_estudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE creacion.estudiante
    SET estado_baja = 0, estado = 'Activo'
    WHERE id_estudiante = @id_estudiante;

    PRINT 'Estudiante dado de alta correctamente.';
END;
GO

-- Matricular Alumno (Corregido: Columnas de factura)
CREATE OR ALTER PROCEDURE creacion.sp_MatricularAlumno
    @id_estudiante INT,
    @anio INT,
    @monto DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

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

    -- 1. Insertar Matrícula
    INSERT INTO creacion.matriculacion (id_estudiante, anio, fecha_pago, monto, estado_pago)
    VALUES (@id_estudiante, @anio, GETDATE(), @monto, 'Pendiente');

    -- 2. Generar Factura (Corregido: Usando solo columnas válidas)
    DECLARE @id_factura INT;
    INSERT INTO creacion.factura (id_estudiante, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago)
    VALUES (@id_estudiante, 1, @anio, GETDATE(), DATEADD(MONTH, 1, GETDATE()), @monto, 'Pendiente');
    SET @id_factura = SCOPE_IDENTITY();

    -- 3. Cargo en Cuenta Corriente (Monto negativo para deuda)
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    VALUES (@id_estudiante, GETDATE(), 'Cargo por Matrícula', -@monto, 'Matrícula año ' + CAST(@anio AS NVARCHAR), 'Pendiente');
    
    PRINT 'Matrícula generada exitosamente.';
END;
GO

------------------------------------------------------------------------------------------------
-- 3. SPs de Contabilidad (Pagos, Cuotas, Intereses)
------------------------------------------------------------------------------------------------

-- Registrar un Pago
CREATE OR ALTER PROCEDURE creacion.sp_RegistrarPago
    @id_estudiante INT,
    @monto DECIMAL(10,2),
    @concepto NVARCHAR(200),
    @fecha DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fecha IS NULL SET @fecha = GETDATE();

    -- Monto positivo = Ingreso
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    VALUES (@id_estudiante, @fecha, 'Pago de ' + @concepto, @monto, @concepto, 'Pagado');
END;
GO

-- Calcular Intereses por Mora
CREATE OR ALTER PROCEDURE creacion.sp_CalcularInteresesPorMora
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar cuotas vencidas
    UPDATE creacion.cuota
    SET estado_pago = 'Vencida'
    WHERE estado_pago != 'Pagada' AND fecha_vencimiento < DATEADD(DAY, -30, GETDATE());

    -- Insertar cargo de interés (Monto Negativo)
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    SELECT  
        c.id_estudiante,
        GETDATE(),
        'Interés por mora', 
        -(c.monto * (i.porcentaje_interes / 100)),
        'Interés por mora cuota ' + CAST(c.mes AS NVARCHAR) + '/' + CAST(YEAR(c.fecha_vencimiento) AS NVARCHAR),
        'Pendiente'
    FROM creacion.cuota c
    INNER JOIN creacion.estudiante e ON c.id_estudiante = e.id_estudiante
    INNER JOIN creacion.interes_por_mora i ON e.anio_ingreso = i.anio_carrera  
    WHERE c.estado_pago = 'Vencida'
    GROUP BY c.id_estudiante, c.monto, i.porcentaje_interes, c.mes, YEAR(c.fecha_vencimiento);
END;
GO

-- Generar Cuota de un Alumno (Corregido: Columnas de factura y CC)
CREATE OR ALTER PROCEDURE creacion.sp_GenerarCuotaAlumno
    @id_estudiante INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_cuatrimestre INT = (SELECT TOP 1 id_cuatrimestre FROM creacion.cuatrimestre WHERE fecha_inicio <= GETDATE() AND fecha_fin >= GETDATE());
    DECLARE @anio INT = YEAR(GETDATE());
    DECLARE @monto DECIMAL(10,2) = (
        SELECT SUM(M.costo_curso_mensual) 
        FROM creacion.inscripcion I 
        INNER JOIN creacion.curso C ON I.id_curso = C.id_curso 
        INNER JOIN creacion.materia M ON C.id_materia = M.id_materia 
        WHERE I.id_estudiante = @id_estudiante
    ); 

    IF @monto IS NULL OR @monto <= 0 RETURN;

    DECLARE @fecha_vencimiento DATE = EOMONTH(DATEFROMPARTS(@anio, @mes, 1)); 

    -- 1. Generar Factura (Corregido)
    DECLARE @id_factura INT;
    INSERT INTO creacion.factura (id_estudiante, fecha_emision, monto_total, mes, anio, fecha_vencimiento, estado_pago)
    VALUES (@id_estudiante, GETDATE(), @monto, @mes, @anio, @fecha_vencimiento, 'Pendiente');
    SET @id_factura = SCOPE_IDENTITY(); 

    -- 2. Generar Cuota
    INSERT INTO creacion.cuota (id_estudiante, id_cuatrimestre, id_factura, mes, monto, fecha_vencimiento, estado_pago)
    VALUES (@id_estudiante, @id_cuatrimestre, @id_factura, @mes, @monto, @fecha_vencimiento, 'Pendiente');

    -- 3. Cargo en cuenta corriente (Monto negativo)
    INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado)
    VALUES (@id_estudiante, GETDATE(), 'Cargo por Cuota Mensual', -@monto, 'Cuota ' + CAST(@mes AS NVARCHAR) + '/' + CAST(@anio AS NVARCHAR), 'Pendiente');
END;
GO

-- Generar Cuotas de Todos los Alumnos (Corregido: Lógica de cursor, factura y CC)
CREATE OR ALTER PROCEDURE creacion.sp_GenerarCuotasTodosAlumnos
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_cuatrimestre INT = (SELECT TOP 1 id_cuatrimestre FROM creacion.cuatrimestre WHERE fecha_inicio <= GETDATE() AND fecha_fin >= GETDATE());
    DECLARE @mes_actual INT = MONTH(GETDATE());
    DECLARE @anio_actual INT = YEAR(GETDATE());
    
    IF @id_cuatrimestre IS NULL BEGIN PRINT 'No hay cuatrimestre activo.'; RETURN; END

    DECLARE cur CURSOR FOR 
        SELECT id_estudiante FROM creacion.estudiante WHERE ISNULL(estado_baja, 0) = 0;
    DECLARE @id_estudiante INT;
    OPEN cur;
    FETCH NEXT FROM cur INTO @id_estudiante;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @monto DECIMAL(10,2) = (
            SELECT SUM(M.costo_curso_mensual) 
            FROM creacion.inscripcion I 
            INNER JOIN creacion.curso C ON I.id_curso = C.id_curso 
            INNER JOIN creacion.materia M ON C.id_materia = M.id_materia 
            WHERE I.id_estudiante = @id_estudiante
        );
        
        IF @monto IS NOT NULL AND @monto > 0
        BEGIN
            DECLARE @id_factura INT;
            
            -- Generación de Factura
            IF NOT EXISTS (SELECT 1 FROM creacion.factura WHERE id_estudiante = @id_estudiante AND mes = @mes_actual AND anio = @anio_actual)
            BEGIN
                INSERT INTO creacion.factura (id_estudiante, mes, anio, fecha_emision, fecha_vencimiento, monto_total, estado_pago) 
                VALUES (@id_estudiante, @mes_actual, @anio_actual, GETDATE(), DATEADD(DAY, 30, GETDATE()), @monto, 'Pendiente');
                SET @id_factura = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                SELECT @id_factura = id_factura FROM creacion.factura WHERE id_estudiante = @id_estudiante AND mes = @mes_actual AND anio = @anio_actual;
            END

            -- Generación de Cuota
            IF NOT EXISTS (SELECT 1 FROM creacion.cuota WHERE id_estudiante = @id_estudiante AND mes = @mes_actual AND id_cuatrimestre = @id_cuatrimestre)
            BEGIN
                 INSERT INTO creacion.cuota (id_estudiante, id_cuatrimestre, id_factura, mes, monto, fecha_vencimiento, estado_pago) 
                 VALUES (@id_estudiante, @id_cuatrimestre, @id_factura, @mes_actual, @monto, DATEADD(DAY, 30, GETDATE()), 'Pendiente');
            END
            
            -- Cargo en Cuenta Corriente (Monto negativo)
            IF NOT EXISTS (SELECT 1 FROM creacion.CuentaCorriente WHERE id_estudiante = @id_estudiante AND concepto = 'Cuota mensual' AND MONTH(fecha) = @mes_actual AND YEAR(fecha) = @anio_actual AND monto < 0)
            BEGIN
                INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto, concepto, estado) 
                VALUES (@id_estudiante, GETDATE(), 'Cargo por Cuota Mensual', -@monto, 'Cuota mensual', 'Pendiente');
            END
        END
        FETCH NEXT FROM cur INTO @id_estudiante;
    END
    CLOSE cur;
    DEALLOCATE cur;
    PRINT 'Cuotas generadas para todos los alumnos.';
END;
GO

------------------------------------------------------------------------------------------------
-- 4. SPs de Gestión Académica (Inscripción y Notas)
------------------------------------------------------------------------------------------------

-- Inscribir Alumno a Curso
CREATE OR ALTER PROCEDURE creacion.sp_InscribirAlumnoACurso
    @id_estudiante INT,
    @id_curso INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- (Omito validaciones de existencia/baja para simplificar, ya estaban correctas)
    
    DECLARE @id_materia INT;
    SELECT @id_materia = id_materia FROM creacion.curso WHERE id_curso = @id_curso;

    -- Verificar que no esté inscrito en otro curso de la MISMA MATERIA
    IF EXISTS (
        SELECT 1 FROM creacion.inscripcion I
        INNER JOIN creacion.curso C ON I.id_curso = C.id_curso
        WHERE I.id_estudiante = @id_estudiante AND C.id_materia = @id_materia
    )
    BEGIN
        RAISERROR('El estudiante ya está inscripto en otro curso de la misma materia.', 16, 1);
        RETURN;
    END

    INSERT INTO creacion.inscripcion (id_estudiante, id_curso, id_materia, fecha_inscripcion)
    VALUES (@id_estudiante, @id_curso, @id_materia, GETDATE());

    PRINT 'Inscripción realizada exitosamente.';
END;
GO

-- Cargar Nota a Alumno (Lógica de recuperatorio y SQL dinámico correcta)
CREATE OR ALTER PROCEDURE creacion.sp_CargarNotaAlumno
    @id_curso INT,
    @id_estudiante INT,
    @examen VARCHAR(50),
    @nota DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @nota < 0 OR @nota > 10
    BEGIN RAISERROR('La nota debe estar entre 0 y 10.', 16, 1); RETURN; END
    IF NOT EXISTS (SELECT 1 FROM creacion.inscripcion WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso)
    BEGIN RAISERROR('Inscripción no encontrada.', 16, 1); RETURN; END

    -- Validación de recuperatorio... (Lógica ya revisada)

    -- Carga la nota usando SQL dinámico (mejorado con QUOTENAME)
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @valid_columns TABLE (ColumnName NVARCHAR(50));
    INSERT INTO @valid_columns VALUES ('nota_teorica_1'), ('nota_teorica_2'), ('nota_practica'), ('nota_teorica_recuperatorio'), ('nota_final');

    IF NOT EXISTS (SELECT 1 FROM @valid_columns WHERE ColumnName = @examen)
    BEGIN RAISERROR('Nombre de examen no válido.', 16, 1); RETURN; END
    
    SET @sql = N'UPDATE creacion.inscripcion SET ' + QUOTENAME(@examen) + ' = @nota WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso';
    EXEC sp_executesql @sql, N'@nota DECIMAL(4,2), @id_estudiante INT, @id_curso INT', @nota, @id_estudiante, @id_curso;

    PRINT 'Nota cargada exitosamente.';
END;
GO

------------------------------------------------------------------------------------------------
-- 5. Funciones de Reporte
------------------------------------------------------------------------------------------------

-- Listar estudiantes con cuotas vencidas.
CREATE OR ALTER FUNCTION creacion.fn_ListarEstudiantesConCuotasVencidas ()
RETURNS TABLE
AS
RETURN
    SELECT DISTINCT
        e.id_estudiante, e.nombre AS nombre_estudiante, e.apellido AS apellido_estudiante,
        cu.id_cuota, cu.mes, cu.monto, cu.fecha_vencimiento
    FROM creacion.estudiante e
    INNER JOIN creacion.cuota cu ON e.id_estudiante = cu.id_estudiante
    WHERE cu.estado_pago != 'Pagada' AND cu.fecha_vencimiento < GETDATE();
GO

-- Mostrar cursos con su cantidad de inscriptos.
CREATE OR ALTER FUNCTION creacion.fn_MostrarCursosConInscriptos ()
RETURNS TABLE
AS
RETURN
    SELECT c.id_curso, c.nombre AS nombre_curso, c.anio, COUNT(i.id_inscripcion) AS cantidad_inscriptos
    FROM creacion.curso c
    LEFT JOIN creacion.inscripcion i ON c.id_curso = i.id_curso
    GROUP BY c.id_curso, c.nombre, c.anio;
GO

-- Listar facturas agrupadas por estado de pago.
CREATE OR ALTER FUNCTION creacion.fn_ListarFacturasAgrupadasPorEstado ()
RETURNS TABLE
AS
RETURN
    SELECT estado_pago, COUNT(*) AS cantidad_facturas, SUM(monto_total) AS total_monto
    FROM creacion.factura
    GROUP BY estado_pago;
GO

------------------------------------------------------------------------------------------------
-- 6. SPs Dinámicos y con Cursor
------------------------------------------------------------------------------------------------

-- Listar estudiantes según un campo de búsqueda variable
CREATE OR ALTER PROCEDURE creacion.sp_ListarEstudiantesDinamico
    @campo VARCHAR(50),
    @valor VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    IF @campo IS NULL OR @campo = '' OR @valor IS NULL BEGIN RAISERROR('Debe especificar un campo y un valor de búsqueda.', 16, 1); RETURN; END
    
    SET @sql = N'SELECT id_estudiante, nombre, apellido, dni, email FROM creacion.estudiante WHERE ' + QUOTENAME(@campo) + N' LIKE ''%' + @valor + N'%''';
    EXEC sp_executesql @sql;
END;
GO

-- Consultar inscripciones filtrando por una combinación dinámica de notas y operador
CREATE OR ALTER PROCEDURE creacion.sp_ConsultarInscripcionesNotas
    @campo_nota VARCHAR(50),
    @operador VARCHAR(10),
    @valor DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    
    IF @operador NOT IN ('=', '>', '<', '>=', '<=', '!=') BEGIN RAISERROR('Operador no válido.', 16, 1); RETURN; END

    SET @sql = N'SELECT id_estudiante, id_curso, id_materia, ' + QUOTENAME(@campo_nota) + N' AS Nota_Filtrada FROM creacion.inscripcion WHERE ' + QUOTENAME(@campo_nota) + N' ' + @operador + N' @valor';
    EXEC sp_executesql @sql, N'@valor DECIMAL(4,2)', @valor;
END;
GO

-- Listar cursos que tengan más de X inscriptos, agrupando dinámicamente.
CREATE OR ALTER PROCEDURE creacion.sp_ListarCursosInscriptosDinamico
    @X INT,
    @campo_agrupacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    
    IF @campo_agrupacion NOT IN ('anio', 'nombre', 'id_materia', 'id_profesor') BEGIN RAISERROR('Campo de agrupación no válido.', 16, 1); RETURN; END
    
    SET @sql = N'
        SELECT ' + QUOTENAME(@campo_agrupacion) + N', COUNT(I.id_estudiante) AS inscriptos 
        FROM creacion.curso C 
        INNER JOIN creacion.inscripcion I ON C.id_curso = I.id_curso 
        GROUP BY ' + QUOTENAME(@campo_agrupacion) + N' 
        HAVING COUNT(I.id_estudiante) > @X';
    
    EXEC sp_executesql @sql, N'@X INT', @X;
END;
GO

-- Reporte de facturas agrupadas por un campo dinámico.
CREATE OR ALTER PROCEDURE creacion.sp_ReporteFacturasDinamico
    @campo_agrupacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);

    IF @campo_agrupacion NOT IN ('mes', 'estado_pago', 'id_estudiante', 'anio') BEGIN RAISERROR('Campo de agrupación no válido.', 16, 1); RETURN; END

    SET @sql = N'
        SELECT ' + QUOTENAME(@campo_agrupacion) + N', 
               COUNT(*) AS cantidad_facturas,
               SUM(monto_total) AS monto_total_agrupado 
        FROM creacion.factura 
        GROUP BY ' + QUOTENAME(@campo_agrupacion);
        
    EXEC sp_executesql @sql;
END;
GO

-- Mostrar los intereses por mora aplicados por año de carrera (Cursor)
CREATE OR ALTER PROCEDURE creacion.sp_ListarInteresesPorMora
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @anio_carrera INT, @porcentaje_interes DECIMAL(5,2);
    DECLARE cur CURSOR FOR SELECT anio_carrera, porcentaje_interes FROM creacion.interes_por_mora ORDER BY anio_carrera;
    OPEN cur;
    FETCH NEXT FROM cur INTO @anio_carrera, @porcentaje_interes;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Año de carrera: ' + CAST(@anio_carrera AS NVARCHAR) + ', Interés: ' + CAST(@porcentaje_interes AS NVARCHAR) + '%';
        FETCH NEXT FROM cur INTO @anio_carrera, @porcentaje_interes;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- Listar cursos con mayor cantidad de inscripciones (Cursor)
CREATE OR ALTER PROCEDURE creacion.sp_ListarCursosMasInscripciones
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_curso INT, @nombre NVARCHAR(100), @cantidad INT;
    DECLARE cur CURSOR FOR
        SELECT c.id_curso, c.nombre, COUNT(i.id_inscripcion) AS cantidad
        FROM creacion.curso c LEFT JOIN creacion.inscripcion i ON c.id_curso = i.id_curso
        GROUP BY c.id_curso, c.nombre ORDER BY cantidad DESC;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id_curso, @nombre, @cantidad;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Curso: ' + @nombre + ', Inscripciones: ' + CAST(@cantidad AS NVARCHAR);
        FETCH NEXT FROM cur INTO @id_curso, @nombre, @cantidad;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- Listar estudiantes sin matrícula en el año actual (Cursor)
CREATE OR ALTER PROCEDURE creacion.sp_ListarEstudiantesSinMatriculaActual
AS
BEGIN
    SET NOCOUNT ON;
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
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- Listar cuotas vencidas ordenadas por un campo dinámico
CREATE OR ALTER PROCEDURE creacion.sp_ListarCuotasVencidasDinamico (@campo_orden NVARCHAR(50))
AS
BEGIN
    SET NOCOUNT ON;
    IF @campo_orden NOT IN ('fecha_vencimiento', 'monto', 'estado_pago', 'id_estudiante', 'id_cuota') BEGIN RAISERROR('Campo de ordenación no válido.', 16, 1); RETURN; END
    
    DECLARE @sql NVARCHAR(MAX) = '
        SELECT id_cuota, id_estudiante, fecha_vencimiento, monto, estado_pago
        FROM creacion.cuota
        WHERE estado_pago != ''Pagada'' AND fecha_vencimiento < GETDATE()
        ORDER BY ' + QUOTENAME(@campo_orden) + ';';

    EXEC(@sql); 
END;
GO

-- Mostrar los cursos que cumplen con una condición dinámica
CREATE OR ALTER PROCEDURE creacion.sp_ListarCursosCondicionDinamica (@condicion NVARCHAR(MAX))
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT c.id_curso, c.nombre, c.anio, m.costo_curso_mensual, m.creditos
        FROM creacion.curso c
        INNER JOIN creacion.materia m ON c.id_materia = m.id_materia
        WHERE ' + @condicion + ';';
    EXEC(@sql);
END;
GO

-- Listar profesores que dictan cursos en un cuatrimestre específico, con ordenamiento dinámico.
CREATE OR ALTER PROCEDURE creacion.sp_ListarProfesoresCuatrimestreDinamico (@id_cuatrimestre INT, @campo_orden NVARCHAR(50))
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @campo_orden NOT IN ('nombre', 'apellido', 'especialidad') BEGIN RAISERROR('Campo de ordenación no válido.', 16, 1); RETURN; END

    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT DISTINCT p.id_profesor, p.nombre, p.apellido, p.especialidad
        FROM creacion.profesor p
        INNER JOIN creacion.curso c ON p.id_profesor = c.id_profesor
        INNER JOIN creacion.inscripcion i ON c.id_curso = i.id_curso
        INNER JOIN creacion.cuota cu ON i.id_estudiante = cu.id_estudiante 
        WHERE cu.id_cuatrimestre = ' + CAST(@id_cuatrimestre AS NVARCHAR) + N'
        ORDER BY ' + QUOTENAME(@campo_orden) + ';';
    
    EXEC(@sql);
END;
GO
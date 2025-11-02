USE GestionAcademicaNueva;
GO

-- Inscribir alumno a curso
CREATE OR ALTER PROCEDURE creacion.sp_InscribirAlumnoACurso
    @id_estudiante INT,
    @id_materia INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_curso INT;
    DECLARE @mensaje NVARCHAR(500);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante con ID ' + CAST(@id_estudiante AS NVARCHAR) + ' no existe.';
            THROW 50001, @mensaje, 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM creacion.materia WHERE id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: La materia con ID ' + CAST(@id_materia AS NVARCHAR) + ' no existe.';
            THROW 50002, @mensaje, 1;
        END
        
        SELECT @id_curso = id_curso FROM creacion.materia WHERE id_materia = @id_materia;
        
        IF EXISTS (SELECT 1 FROM creacion.inscripcion 
                   WHERE id_estudiante = @id_estudiante 
                   AND id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante ya está inscripto en esta materia.';
            THROW 50003, @mensaje, 1;
        END
        
        IF EXISTS (SELECT 1 FROM creacion.inscripcion i
                   INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
                   WHERE i.id_estudiante = @id_estudiante
                   AND m.id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante ya está inscripto en otro curso de la misma materia.';
            THROW 50004, @mensaje, 1;
        END
        
        IF EXISTS (SELECT 1 FROM creacion.curso 
                   WHERE id_curso = @id_curso 
                   AND cupo_ocupado >= cupo_maximo)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: No hay cupo disponible en el curso.';
            THROW 50005, @mensaje, 1;
        END
        
        INSERT INTO creacion.inscripcion (id_estudiante, id_materia, fecha_inscripcion)
        VALUES (@id_estudiante, @id_materia, GETDATE());
        
        UPDATE creacion.curso
        SET cupo_ocupado = cupo_ocupado + 1
        WHERE id_curso = @id_curso;
        
        COMMIT TRANSACTION;
        
        SET @mensaje = 'Inscripción realizada exitosamente.';
        PRINT @mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

-- Cargar nota a alumno
CREATE OR ALTER PROCEDURE creacion.sp_CargarNotaAlumno
    @id_estudiante INT,
    @id_materia INT,
    @tipo_examen NVARCHAR(50),
    @nota DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @mensaje NVARCHAR(500);
    DECLARE @notas_menores_4 INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM creacion.estudiante WHERE id_estudiante = @id_estudiante)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante con ID ' + CAST(@id_estudiante AS NVARCHAR) + ' no existe.';
            THROW 50010, @mensaje, 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM creacion.materia WHERE id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: La materia con ID ' + CAST(@id_materia AS NVARCHAR) + ' no existe.';
            THROW 50011, @mensaje, 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM creacion.inscripcion 
                       WHERE id_estudiante = @id_estudiante 
                       AND id_materia = @id_materia)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: El estudiante no está inscripto en esta materia.';
            THROW 50012, @mensaje, 1;
        END
        
        IF @nota < 0 OR @nota > 10
        BEGIN
            ROLLBACK TRANSACTION;
            SET @mensaje = 'Error: La nota debe estar entre 0 y 10.';
            THROW 50013, @mensaje, 1;
        END
        
        IF LOWER(@tipo_examen) = 'recuperatorio'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM creacion.inscripcion 
                           WHERE id_estudiante = @id_estudiante 
                           AND id_materia = @id_materia
                           AND nota_final IS NOT NULL
                           AND nota_final < 4)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @mensaje = 'Error: No puede rendir recuperatorio. No hay notas anteriores menores a 4.';
                THROW 50014, @mensaje, 1;
            END
            
            SET @notas_menores_4 = (SELECT COUNT(*) FROM creacion.inscripcion 
                                      WHERE id_estudiante = @id_estudiante 
                                      AND id_materia = @id_materia
                                      AND nota_final IS NOT NULL
                                      AND nota_final < 4);
            
            IF @notas_menores_4 >= 2
            BEGIN
                ROLLBACK TRANSACTION;
                SET @mensaje = 'Error: No puede rendir recuperatorio. Tiene dos o más notas anteriores menores a 4.';
                THROW 50015, @mensaje, 1;
            END
        END
        
        UPDATE creacion.inscripcion
        SET nota_final = @nota
        WHERE id_estudiante = @id_estudiante 
        AND id_materia = @id_materia;
        
        COMMIT TRANSACTION;
        
        SET @mensaje = 'Nota cargada exitosamente.';
        PRINT @mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

-- Generar cuotas de todos los alumnos
CREATE OR ALTER PROCEDURE creacion.sp_GenerarCuotasTodosAlumnos
    @mes INT = NULL,
    @anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @id_estudiante INT;
    DECLARE @id_materia INT;
    DECLARE @id_curso INT;
    DECLARE @monto_cuota DECIMAL(10,2);
    DECLARE @monto_total DECIMAL(10,2);
    DECLARE @id_factura INT;
    DECLARE @concepto NVARCHAR(200);
    DECLARE @contador INT = 0;
    
    IF @mes IS NULL
        SET @mes = MONTH(GETDATE());
    
    IF @anio IS NULL
        SET @anio = YEAR(GETDATE());
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE estudiantes_cursor CURSOR FOR
        SELECT DISTINCT id_estudiante
        FROM creacion.inscripcion;
        
        OPEN estudiantes_cursor;
        FETCH NEXT FROM estudiantes_cursor INTO @id_estudiante;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @monto_total = 0;
            SET @concepto = 'Cuota mes ' + CAST(@mes AS NVARCHAR) + '/' + CAST(@anio AS NVARCHAR);
            
            SELECT @monto_total = COUNT(*) * 5000.00
            FROM creacion.inscripcion i
            INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
            WHERE i.id_estudiante = @id_estudiante
            AND i.nota_final IS NULL;
            
            IF @monto_total > 0
            BEGIN
                INSERT INTO creacion.factura (id_estudiante, fecha, total)
                VALUES (@id_estudiante, GETDATE(), @monto_total);
                
                SET @id_factura = SCOPE_IDENTITY();
                
                INSERT INTO creacion.CuentaCorriente (id_estudiante, fecha, descripcion, monto)
                VALUES (@id_estudiante, GETDATE(), @concepto, @monto_total);
                
                SET @contador = @contador + 1;
            END
            
            FETCH NEXT FROM estudiantes_cursor INTO @id_estudiante;
        END
        
        CLOSE estudiantes_cursor;
        DEALLOCATE estudiantes_cursor;
        
        COMMIT TRANSACTION;
        
        PRINT 'Cuotas generadas exitosamente para ' + CAST(@contador AS NVARCHAR) + ' estudiantes.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF CURSOR_STATUS('global', 'estudiantes_cursor') >= 0
        BEGIN
            CLOSE estudiantes_cursor;
            DEALLOCATE estudiantes_cursor;
        END
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error al generar cuotas: ' + @ErrorMsg;
        THROW;
    END CATCH
END;
GO

PRINT 'Procedimientos almacenados creados correctamente.';
GO

-- Listar estudiantes según un campo de búsqueda variable
CREATE OR ALTER PROCEDURE creacion.sp_BuscarEstudiantesDinamico
    @campo_busqueda NVARCHAR(50),
    @valor_busqueda NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @campo_valido BIT = 0;
    
    IF UPPER(@campo_busqueda) IN ('NOMBRE', 'APELLIDO', 'EMAIL', 'ANIO_INGRESO', 'AÑO_INGRESO')
    BEGIN
        SET @campo_valido = 1;
    END
    ELSE
    BEGIN
        THROW 50040, 'Error: Campo de búsqueda inválido. Use: nombre, apellido, email o anio_ingreso', 1;
        RETURN;
    END
    
    SET @sql = 'SELECT id_estudiante, nombre, apellido, dni, email, fecha_nacimiento, telefono, direccion 
                FROM creacion.estudiante 
                WHERE 1=1';
    
    IF UPPER(@campo_busqueda) = 'NOMBRE'
    BEGIN
        SET @sql = @sql + ' AND nombre LIKE ''%' + REPLACE(@valor_busqueda, '''', '''''') + '%''';
    END
    ELSE IF UPPER(@campo_busqueda) = 'APELLIDO'
    BEGIN
        SET @sql = @sql + ' AND apellido LIKE ''%' + REPLACE(@valor_busqueda, '''', '''''') + '%''';
    END
    ELSE IF UPPER(@campo_busqueda) = 'EMAIL'
    BEGIN
        SET @sql = @sql + ' AND email LIKE ''%' + REPLACE(@valor_busqueda, '''', '''''') + '%''';
    END
    ELSE IF UPPER(@campo_busqueda) IN ('ANIO_INGRESO', 'AÑO_INGRESO')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.columns 
                   WHERE object_id = OBJECT_ID('creacion.estudiante') 
                   AND name = 'anio_ingreso')
        BEGIN
            SET @sql = @sql + ' AND anio_ingreso = ' + @valor_busqueda;
        END
        ELSE
        BEGIN
            THROW 50041, 'Error: La columna anio_ingreso no existe en la tabla estudiante.', 1;
            RETURN;
        END
    END
    
    SET @sql = @sql + ' ORDER BY apellido, nombre';
    
    EXEC sp_executesql @sql;
END;
GO

-- Consultar inscripciones filtrando por una combinación dinámica de notas
CREATE OR ALTER PROCEDURE creacion.sp_FiltrarInscripcionesPorNotas
    @campo_nota NVARCHAR(50),
    @operador NVARCHAR(10),
    @valor_nota DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @campo_valido BIT = 0;
    
    IF UPPER(@campo_nota) IN ('NOTA_TEORICA_1', 'NOTA_TEORICA_2', 'NOTA_PRACTICA', 'NOTA_FINAL')
    BEGIN
        SET @campo_valido = 1;
    END
    ELSE
    BEGIN
        THROW 50050, 'Error: Campo de nota inválido. Use: nota_teorica_1, nota_teorica_2, nota_practica o nota_final', 1;
        RETURN;
    END
    
    IF @operador NOT IN ('>', '<', '=', '>=', '<=', '<>')
    BEGIN
        THROW 50051, 'Error: Operador inválido. Use: >, <, =, >=, <=, <>', 1;
        RETURN;
    END
    
    SET @sql = 'SELECT 
                    i.id_inscripcion,
                    e.id_estudiante,
                    e.nombre + '' '' + e.apellido AS estudiante,
                    m.nombre AS materia,
                    c.nombre AS curso,
                    i.fecha_inscripcion,
                    i.nota_final';
    
    IF EXISTS (SELECT 1 FROM sys.columns 
               WHERE object_id = OBJECT_ID('creacion.inscripcion') 
               AND name = 'nota_teorica_1')
    BEGIN
        SET @sql = @sql + ', i.nota_teorica_1';
    END
    IF EXISTS (SELECT 1 FROM sys.columns 
               WHERE object_id = OBJECT_ID('creacion.inscripcion') 
               AND name = 'nota_teorica_2')
    BEGIN
        SET @sql = @sql + ', i.nota_teorica_2';
    END
    IF EXISTS (SELECT 1 FROM sys.columns 
               WHERE object_id = OBJECT_ID('creacion.inscripcion') 
               AND name = 'nota_practica')
    BEGIN
        SET @sql = @sql + ', i.nota_practica';
    END
    
    SET @sql = @sql + ' FROM creacion.inscripcion i
                        INNER JOIN creacion.estudiante e ON i.id_estudiante = e.id_estudiante
                        INNER JOIN creacion.materia m ON i.id_materia = m.id_materia
                        INNER JOIN creacion.curso c ON m.id_curso = c.id_curso
                        WHERE i.' + @campo_nota + ' ' + @operador + ' ' + CAST(@valor_nota AS NVARCHAR(10));
    
    SET @sql = @sql + ' ORDER BY i.nota_final DESC, e.apellido, e.nombre';
    
    EXEC sp_executesql @sql;
END;
GO

-- Listar cursos que tengan más de X inscriptos con agrupación dinámica
CREATE OR ALTER PROCEDURE creacion.sp_CursosConMasInscriptos
    @cantidad_minima INT,
    @agrupar_por NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @campo_agrupacion NVARCHAR(100) = '';
    DECLARE @campos_select NVARCHAR(MAX) = '';
    DECLARE @join_profesor NVARCHAR(MAX) = '';
    
    IF UPPER(@agrupar_por) NOT IN ('ANIO', 'AÑO', 'MATERIA', 'PROFESOR')
    BEGIN
        THROW 50060, 'Error: Campo de agrupación inválido. Use: anio, materia o profesor', 1;
        RETURN;
    END
    
    IF UPPER(@agrupar_por) IN ('ANIO', 'AÑO')
    BEGIN
        SET @campos_select = 'c.anio AS agrupacion, c.anio AS año_carrera';
        SET @campo_agrupacion = 'c.anio';
    END
    ELSE IF UPPER(@agrupar_por) = 'MATERIA'
    BEGIN
        SET @campos_select = 'm.nombre AS agrupacion, m.id_materia, m.nombre AS nombre_materia';
        SET @campo_agrupacion = 'm.id_materia, m.nombre';
    END
    ELSE IF UPPER(@agrupar_por) = 'PROFESOR'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'profesor' AND schema_id = SCHEMA_ID('creacion'))
        BEGIN
            IF EXISTS (SELECT 1 FROM sys.columns 
                       WHERE object_id = OBJECT_ID('creacion.curso') 
                       AND name = 'id_profesor')
            BEGIN
                SET @campos_select = 'p.nombre + '' '' + p.apellido AS agrupacion, p.id_profesor, p.nombre AS nombre_profesor, p.apellido AS apellido_profesor';
                SET @campo_agrupacion = 'p.id_profesor, p.nombre, p.apellido';
                SET @join_profesor = 'LEFT JOIN creacion.profesor p ON c.id_profesor = p.id_profesor';
            END
            ELSE
            BEGIN
                THROW 50061, 'Error: La tabla curso no tiene relación con profesor.', 1;
                RETURN;
            END
        END
        ELSE
        BEGIN
            THROW 50062, 'Error: La tabla profesor no existe en el esquema creacion.', 1;
            RETURN;
        END
    END
    
    SET @sql = 'SELECT 
                    ' + @campos_select + ',
                    COUNT(DISTINCT i.id_estudiante) AS cantidad_inscriptos,
                    c.id_curso,
                    c.nombre AS nombre_curso
                FROM creacion.curso c
                INNER JOIN creacion.materia m ON c.id_curso = m.id_curso
                INNER JOIN creacion.inscripcion i ON m.id_materia = i.id_materia
                ' + @join_profesor + '
                GROUP BY ' + @campo_agrupacion + ', c.id_curso, c.nombre';
    
    SET @sql = @sql + ' HAVING COUNT(DISTINCT i.id_estudiante) > ' + CAST(@cantidad_minima AS NVARCHAR(10));
    
    SET @sql = @sql + ' ORDER BY cantidad_inscriptos DESC, agrupacion';
    
    EXEC sp_executesql @sql;
END;
GO

-- Generar reporte de facturas agrupadas por un campo dinámico
CREATE OR ALTER PROCEDURE creacion.sp_ReporteFacturasAgrupado
    @agrupar_por NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @campos_select NVARCHAR(MAX) = '';
    DECLARE @campo_agrupacion NVARCHAR(100) = '';
    
    IF UPPER(@agrupar_por) NOT IN ('MES', 'ESTADO_PAGO', 'ESTUDIANTE')
    BEGIN
        THROW 50070, 'Error: Campo de agrupación inválido. Use: mes, estado_pago o estudiante', 1;
        RETURN;
    END
    
    IF UPPER(@agrupar_por) = 'MES'
    BEGIN
        SET @campos_select = 'MONTH(f.fecha) AS mes, YEAR(f.fecha) AS año, 
                              CAST(MONTH(f.fecha) AS NVARCHAR) + ''/'' + CAST(YEAR(f.fecha) AS NVARCHAR) AS agrupacion';
        SET @campo_agrupacion = 'MONTH(f.fecha), YEAR(f.fecha)';
    END
    ELSE IF UPPER(@agrupar_por) = 'ESTADO_PAGO'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.columns 
                   WHERE object_id = OBJECT_ID('creacion.factura') 
                   AND name = 'estado_pago')
        BEGIN
            SET @campos_select = 'f.estado_pago AS agrupacion, f.estado_pago';
            SET @campo_agrupacion = 'f.estado_pago';
        END
        ELSE
        BEGIN
            SET @campos_select = 'CASE 
                                    WHEN EXISTS (SELECT 1 FROM creacion.CuentaCorriente cc 
                                                 WHERE cc.id_estudiante = f.id_estudiante 
                                                 AND cc.monto < 0 
                                                 AND ABS(cc.monto) >= f.total) 
                                    THEN ''Pagada'' 
                                    ELSE ''Impaga'' 
                                  END AS agrupacion';
            SET @campo_agrupacion = 'CASE 
                                      WHEN EXISTS (SELECT 1 FROM creacion.CuentaCorriente cc 
                                                   WHERE cc.id_estudiante = f.id_estudiante 
                                                   AND cc.monto < 0 
                                                   AND ABS(cc.monto) >= f.total) 
                                      THEN ''Pagada'' 
                                      ELSE ''Impaga'' 
                                    END';
        END
    END
    ELSE IF UPPER(@agrupar_por) = 'ESTUDIANTE'
    BEGIN
        SET @campos_select = 'e.id_estudiante, e.nombre + '' '' + e.apellido AS agrupacion, e.nombre, e.apellido';
        SET @campo_agrupacion = 'e.id_estudiante, e.nombre, e.apellido';
    END
    
    SET @sql = 'SELECT 
                    ' + @campos_select + ',
                    COUNT(f.id_factura) AS cantidad_facturas,
                    SUM(f.total) AS monto_total,
                    AVG(f.total) AS monto_promedio,
                    MIN(f.fecha) AS fecha_primera,
                    MAX(f.fecha) AS fecha_ultima
                FROM creacion.factura f
                INNER JOIN creacion.estudiante e ON f.id_estudiante = e.id_estudiante
                GROUP BY ' + @campo_agrupacion;
    
    SET @sql = @sql + ' ORDER BY monto_total DESC';
    
    EXEC sp_executesql @sql;
END;
GO

PRINT 'Procedimientos con SQL dinámico creados correctamente.';
GO


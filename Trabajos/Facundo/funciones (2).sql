USE GestionAcademica;
GO

-- Función 1: Saldo de cuenta corriente
CREATE FUNCTION creacion.fn_SaldoCuentaCorriente (@id_estudiante INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @saldo DECIMAL(10,2)

    SELECT @saldo = ISNULL(SUM(monto), 0)
    FROM creacion.CuentaCorriente
    WHERE id_estudiante = @id_estudiante

    RETURN @saldo
END;
GO

-- Función 2: Vacantes disponibles por curso
CREATE FUNCTION creacion.fn_VacantesDisponibles (@id_curso INT)
RETURNS INT
AS
BEGIN
    DECLARE @inscriptos INT
    DECLARE @vacantes INT

    SELECT @inscriptos = COUNT(*) 
    FROM creacion.inscripciones
    WHERE id_curso = @id_curso

    SET @vacantes = 35 - @inscriptos

    RETURN CASE WHEN @vacantes < 0 THEN 0 ELSE @vacantes END
END;
GO

-- Función 3: Nombre completo del estudiante
CREATE FUNCTION creacion.fn_NombreCompleto (@id_estudiante INT)
RETURNS VARCHAR(120)
AS
BEGIN
    DECLARE @nombreCompleto VARCHAR(120)

    SELECT @nombreCompleto = nombre + ' ' + apellido
    FROM creacion.estudiante
    WHERE id_estudiante = @id_estudiante

    RETURN @nombreCompleto
END;
GO

-- Función 4: Promedio final por curso
CREATE FUNCTION creacion.fn_PromedioFinal (@id_estudiante INT, @id_curso INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @promedio DECIMAL(4,2)

    SELECT @promedio = 
        (ISNULL(nota_teorica_1,0) + ISNULL(nota_teorica_2,0) + ISNULL(nota_practica,0)) / 3.0
    FROM creacion.inscripciones
    WHERE id_estudiante = @id_estudiante AND id_curso = @id_curso

    RETURN @promedio
END;
GO

-- Función 5: Cursos por profesor y año (tabla)
CREATE FUNCTION creacion.fn_CursosPorProfesorYAnio (
    @id_profesor INT,
    @anio INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        c.id_curso,
        c.nombre_curso,
        c.descripcion,
        c.anio,
        p.nombre AS nombre_profesor,
        p.apellido AS apellido_profesor
    FROM creacion.cursos c
    INNER JOIN creacion.profesor p ON c.id_profesor = p.id_profesor
    WHERE c.id_profesor = @id_profesor AND c.anio = @anio
);
GO

-- Función 6: Inscripciones sobresalientes (tabla)
CREATE FUNCTION creacion.fn_InscripcionesSobresalientes ()
RETURNS TABLE
AS
RETURN (
    SELECT 
        i.id_estudiante,
        e.nombre,
        e.apellido,
        i.id_curso,
        c.nombre_curso,
        i.nota_final
    FROM creacion.inscripciones i
    INNER JOIN creacion.estudiante e ON i.id_estudiante = e.id_estudiante
    INNER JOIN creacion.cursos c ON i.id_curso = c.id_curso
    WHERE i.nota_final > 8
);
GO

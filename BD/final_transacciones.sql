USE GestionAcademicaNueva;
GO

DROP PROCEDURE IF EXISTS creacion.sp_RegistrarInscripcionYItemFactura;
GO

CREATE PROCEDURE creacion.sp_RegistrarInscripcionYItemFactura
    @id_estudiante INT,
    @id_curso INT,
    @id_factura INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO creacion.inscripcion (id_estudiante, id_curso, fecha_inscripcion)
        VALUES (@id_estudiante, @id_curso, GETDATE());
        INSERT INTO creacion.itemfactura (id_factura, id_curso)
        VALUES (@id_factura, @id_curso);
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
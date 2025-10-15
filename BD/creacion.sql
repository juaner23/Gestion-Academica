CREATE SCHEMA creacion;
go
USE creacion;
go
create table estudiante(
    id_estudiante int not null,
    nombre varchar(50) not null,
    apellido varchar(50) not null,
    email varchar(100) unique,
    constraint pk_estudiantes primary key (id_estudiante)
);

create table profesor(
    id_profesor int not null,
    nombre varchar(50) not null,
    apellido varchar(50) not null,
    especialidad varchar(50),
    constraint pk_profesores primary key (id_profesor)
); 

create table materias(
    id_materia int not null,
    nombre_materia varchar(100) not null,
    creditos int not null,
    constraint pk_materias primary key (id_materia),
    constraint ck_materias_creditos check (creditos >= 0)
);

create table cursos(
    id_curso int not null,
    nombre_curso varchar(100) not null,
    descripcion text,
    anio int not null,
    id_profesor int not null,
    id_materia int not null,
    constraint pk_cursos primary key (id_curso),
    constraint fk_cursos_profesor foreign key (id_profesor) references profesor(id_profesor),
    constraint fk_cursos_materia foreign key (id_materia) references materias(id_materia),
    constraint ck_cursos_anio check (anio >= 2000)
);

create table inscripciones(
    id_estudiante int not null,
    id_curso int not null,
    fecha_inscripcion date not null,
    nota_teorica decimal(4,2),
    nota_practica decimal(4,2),
    nota_final decimal(4,2),
    constraint pk_inscripciones primary key (id_estudiante, id_curso),
    constraint fk_inscripciones_estudiante foreign key (id_estudiante) references estudiante(id_estudiante),
    constraint fk_inscripciones_curso foreign key (id_curso) references cursos(id_curso)
);


#  Sistema de Gestión Académica

##  Descripción general
Este repositorio contiene el desarrollo colaborativo de una **base de datos para un sistema de gestión académica**, implementado en **SQL Server**.  
El proyecto forma parte del trabajo práctico grupal, donde cada integrante desarrolla procedimientos almacenados, funciones, triggers y transacciones sobre una base común.

---

##  Estructura del repositorio

```
Gestion-Academica/
│S
├── BD/
│   ├── creacion.sql              → Script de creación de la base y sus tablas
│   ├── insert.sql                → Script de inserción de datos iniciales
│   ├── select.sql                → Consultas de prueba
│   ├── final_procedimientos.sql  → Unificación de procedimientos terminados
│   ├── final_funciones.sql       → Unificación de funciones terminadas
│   ├── final_triggers.sql        → Unificación de triggers terminados
│   ├── final_transacciones.sql   → Unificación de transacciones terminadas
│   └── README.md
│
├── Consignas/
│   └── Gestion_Academica.docx    → Documento con todas las consignas del trabajo
│
├── Trabajos/
│   ├── Juan/
│   ├── Fatima/
│   ├── Facundo/
│   └── Tomas/
│
└── .gitignore
```

---



---

##  Instrucciones para ejecutar la base

1. Abrir **SQL Server Management Studio (SSMS)**.  
2. Crear una base de datos vacía llamada `GestionAcademica`.  
3. Ejecutar los scripts en este orden:
   - `BD/creacion.sql`
   - `BD/insert.sql`
   - `BD/select.sql`
4. Verificar que las tablas, datos y consultas se ejecuten correctamente.

---

##  Flujo de trabajo colaborativo

1. Cada integrante trabaja **solo dentro de su carpeta**:  
   ```
   /Trabajos/TuNombre/
   ```
2. Antes de empezar:
   ```bash
   git pull origin main
   ```
   (para traer los últimos cambios del repositorio)
3. Al finalizar su parte:
   ```bash
   git add .
   git commit -m "Agrego procedimiento de matrícula (Juan)"
   git push origin main
   ```
4. Al final del trabajo, Juanchi unifica los scripts en `/BD/final_*.sql` para la entrega.

---

##  Buenas prácticas

- Usar nombres descriptivos en procedimientos y funciones (`sp_InscribirAlumno`, `fn_PromedioAlumno`, etc.).
- No ejecutar scripts de otros compañeros sin revisarlos.
- Antes de subir, verificar que los scripts no generen errores ni duplicados.
- No subir archivos temporales (`.bak`, `.mdf`, `.ldf`, `.vs`, etc.).

---

##  Entrega final
El profesor podrá ejecutar directamente los archivos `final_*.sql` dentro de la carpeta **BD**,  
que contienen la versión consolidada y funcional del proyecto.

---


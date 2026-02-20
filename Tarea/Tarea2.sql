use Escuela

/* Consulta 1. Listar alumnos que cursan 
               al menos dos materias */
/* Análisis de una alternativa de solución:
   Generar dos conjuntos y obtener la intersección
   Conjunto A. Recuperar boleta y nombre del alumno
               de la tabla cursa debo seleccionar
   Conjunto B. boletas que tengan asociado dos o más
               claves de materia.
*/

-- 1ra. solución con inner join 
select al.boleta, nombre
from Escuela.Alumno al
inner join
(select boleta, count(*) num_mat
from escuela.cursa c
group by boleta
having count(*) >= 2) as mat_alum
on al.boleta = mat_alum.boleta

-- 2da. solución con subconsulta de pertenencia
-- IN
select boleta, nombre
from Escuela.Alumno 
where boleta in 
       (select boleta
        from escuela.cursa c
        group by boleta
        having count(*) >= 2)

/* 
   Consulta 2
   Listar alumnos que hayan cursado y aprobado todas
   las materias que imparte el profesor P0000001 
*/
/* Datos para pueba de la consulta 2 */

select * from escuela.grupo
insert into Escuela.Grupo values ('1TM3','20242')

insert into Escuela.Cursa 
values ('2020630002',103, '1TM2', '20242', 6)

insert into Escuela.Cursa 
values ('2020630002',101, '1TM1', '20241', 7)

insert into Escuela.Cursa 
values ('2020630001',102, '1TM2', '20242', 9)

insert into Escuela.Cursa 
values ('2020630001',103, '1TM3', '20242', 9)

insert into Escuela.Cursa 
values ('2020630002',103, '1TM3', '20242', 7)

insert into Escuela.Cursa 
values ('2020630003',103, '1TM3', '20242', 5)


insert into Escuela.Imparte 
values ('P0000001',102, '1TM2', '20242')

insert into Escuela.Imparte 
values ('P0000001',103, '1TM3', '20242')


/*
  Solución 1 que genera dos conjuntos:
  Conjunto 1: la cantidad de materias cursadas
              con el profesor P0000001
  Conjunto 2: La cantidad de materias impartidas
              por el profesor P0000001
  Se filtra en el resultado final aquellos
  donde la cant_mat del conjunto 1 sea igual
  al conjunto 2 a través de un JOIN
*/
select T1.boleta
from (
select c.boleta, count(distinct c.clave) cant_mat
from Escuela.Cursa c
join  Escuela.Imparte i
on c.clave = i.clave
and c.Semestre = i.semestre
and c.idGrupo = i.idGrupo
and c.calif >= 6 
and i.numEmpleado = 'P0000001'
group by c.boleta) as T1
join (
select count(distinct clave) as cant_mat
from Escuela.Imparte
where numEmpleado = 'P0000001') as T2
on T1.cant_mat = t2.cant_mat

/*
  Solución 2 que genera dos conjuntos:
  Conjunto 1: la cantidad de materias cursadas
              con el profesor P0000001
  Conjunto 2: La cantidad de materias impartidas
              por el profesor P0000001
  Se filtra en el resultado final aquellos
  donde la cant_mat del conjunto 1 sea igual
  al conjunto 2 a través de una subconsulta en
  el having
*/

select c.boleta, count(distinct c.clave) cant_mat
from Escuela.Cursa c
join  Escuela.Imparte i
on c.clave = i.clave
and c.Semestre = i.semestre
and c.idGrupo = i.idGrupo
and c.calif >= 6 
and i.numEmpleado = 'P0000001'
group by c.boleta
having count(distinct c.clave) = 
      (select count(distinct clave) as cant_mat
       from Escuela.Imparte
       where numEmpleado = 'P0000001')

/* Tarea 1 - entrega 13/02/2026 */
-- Consulta de IA de la codigo de la consulta

-- primera mejora
SELECT c.boleta,
       COUNT(DISTINCT c.clave) AS cant_mat
FROM Escuela.Cursa c
INNER JOIN Escuela.Imparte i
    ON  c.clave = i.clave
    AND c.semestre = i.semestre
    AND c.idGrupo = i.idGrupo
WHERE c.calif >= 6
  AND i.numEmpleado = 'P0000001'
GROUP BY c.boleta
HAVING COUNT(DISTINCT c.clave) = (
        SELECT COUNT(DISTINCT i2.clave)
        FROM Escuela.Imparte i2
        WHERE i2.numEmpleado = 'P0000001'
);

-- segunda mejora
WITH MateriasProfesor AS (
    SELECT COUNT(DISTINCT clave) AS total_materias
    FROM Escuela.Imparte
    WHERE numEmpleado = 'P0000001'
)
SELECT c.boleta,
       COUNT(DISTINCT c.clave) AS cant_mat
FROM Escuela.Cursa c
INNER JOIN Escuela.Imparte i
    ON  c.clave = i.clave
    AND c.semestre = i.semestre
    AND c.idGrupo = i.idGrupo
CROSS JOIN MateriasProfesor mp
WHERE c.calif >= 6
  AND i.numEmpleado = 'P0000001'
GROUP BY c.boleta, mp.total_materias
HAVING COUNT(DISTINCT c.clave) = mp.total_materias;

/* tercera mejora - NOT EXISTS
   Devuelve los alumnos para los cuales 
   NO EXISTE una materia impartida por el 
   profesor que el alumno NO haya aprobado

   Evita COUNT(DISTINCT)
   Evita agrupamientos costosos
   No recalcula totales
   Mejor plan de ejecución en tablas grandes
   Más cercana al modelo relacional teórico
   
*/

SELECT DISTINCT c.boleta
FROM Escuela.Cursa c
WHERE NOT EXISTS (
    SELECT 1
    FROM Escuela.Imparte i
    WHERE i.numEmpleado = 'P0000001'
      AND NOT EXISTS (
            SELECT 1
            FROM Escuela.Cursa c2
            WHERE c2.boleta = c.boleta
              AND c2.clave = i.clave
              AND c2.semestre = i.semestre
              AND c2.idGrupo = i.idGrupo
              AND c2.calif >= 6
      )
);

-- más refinado
SELECT a.boleta
FROM Escuela.Alumno a
WHERE NOT EXISTS (
    SELECT 1
    FROM Escuela.Imparte i
    WHERE i.numEmpleado = 'P0000001'
      AND NOT EXISTS (
            SELECT 1
            FROM Escuela.Cursa c
            WHERE c.boleta = a.boleta
              AND c.clave = i.clave
              AND c.semestre = i.semestre
              AND c.idGrupo = i.idGrupo
              AND c.calif >= 6
      )
);

-- reescritura de la versión NOT EXISTS con
-- LEFT JOIN
SELECT *
FROM Escuela.Alumno a
LEFT JOIN (
    -- Materias del profesor
    SELECT i.clave, i.semestre, i.idGrupo
    FROM Escuela.Imparte i
    WHERE i.numEmpleado = 'P0000001'
) mp
ON 1 = 1   -- producto cartesiano controlado
LEFT JOIN Escuela.Cursa c
    ON c.boleta = a.boleta
    AND c.clave = mp.clave
    AND c.semestre = mp.semestre
    AND c.idGrupo = mp.idGrupo
    AND c.calif >= 6
GROUP BY a.boleta
HAVING COUNT(mp.clave) = COUNT(c.clave);

-- versión anti-join
SELECT a.boleta
FROM Escuela.Alumno a
LEFT JOIN (
    SELECT i.clave, i.semestre, i.idGrupo, a2.boleta
    FROM Escuela.Alumno a2
    CROSS JOIN Escuela.Imparte i
    WHERE i.numEmpleado = 'P0000001'
) faltantes
ON 1 = 1
LEFT JOIN Escuela.Cursa c
    ON c.boleta = a.boleta
    AND c.clave = faltantes.clave
    AND c.semestre = faltantes.semestre
    AND c.idGrupo = faltantes.idGrupo
    AND c.calif >= 6
WHERE c.boleta IS NULL;

/* Tarea 2 - entrega 13/02/2026 */
-- Crear un repositorio en Github y compartirlo
-- cdelacruz@ipn.mx
-- cdelacruz-upiita

/* Tema asignado a Itzel y José Luis
  not exists para implementar la division del algebra 
  relacional
*/

/* Consulta 3. Listar alumnos que no cursado 
               alguna materia con el profesor 
			   P0000001 
  -- Aplicando la resta de conjuntos A - B
  -- EXCEPT
  -- LEFT JOIN (is null)
  -- not exists
  -- not in
*/
select distinct a.boleta  
from escuela.alumno as a left join escuela.cursa as c
on a.boleta = c.boleta
left join escuela.Imparte as i
on i.clave = c.clave 
and i.semestre = c.Semestre
and i.idGrupo = c.idGrupo
and i.numEmpleado = 'P0000001'
where i.numEmpleado is null

select boleta
from escuela.Alumno
except
select distinct c.boleta
from escuela.cursa c
join escuela.Imparte i
on i.clave = c.clave 
and i.semestre = c.Semestre
and i.idGrupo = c.idGrupo
where i.numEmpleado = 'P0000001'

select boleta
from escuela.cursa c
where not exists ( select 1
                   from escuela.imparte i
				   where i.clave = c.clave 
					and i.semestre = c.Semestre
					and i.idGrupo = c.idGrupo
					and i.numEmpleado = 'P0000001')
 
select boleta
from escuela.alumno 
where boleta not in ( select boleta
                      from escuela.imparte i join escuela.cursa c
				      on i.clave = c.clave 
					  and i.semestre = c.Semestre
					  and i.idGrupo = c.idGrupo
					  and i.numEmpleado = 'P0000001')

 /* Implementación de una división del álgebra relacional 
 R÷S=π_X (R) - π_X ((π_X (R)×S)-R)
 */
 -- R es tabla cursa
 -- S es subconjunto de imparte que contiene solamente materias
 --   que ha impartido el profesor 'P0000001'
 -- x es la columna boleta en R
 -- y clave que coincida con el grupo donde ha cursado el alumno

 -- solución usando vistas
 -- tabla virtual generada a través de una consulta

 go
 create view PXC as
 select boleta
 from escuela.cursa
 where calif >= 6

 go 
 create view S as
 select clave, semestre, idGrupo
 from escuela.Imparte
 where numEmpleado = 'P0000001'

 go
 create view RXS as
 select *
 from PXC cross join S

 go 
 create view RXS_R as
 select distinct boleta
 from RXS
 where not exists (select 1
                  from escuela.cursa c
				  where RXS.boleta = c.boleta 
				  and RXS.clave = c.clave
				  and RXS.semestre = c.Semestre
				  and RXS.idGrupo = c.idGrupo)
go
select boleta
from PXC
except
select boleta
from RXS_R



select * from Escuela.cursa
select * from Escuela.imparte

select * from Escuela.cursa
where boleta = '2020630003'


--Tarea 2 
--Implementacion de WITH en nuestras consultas

WITH R as
(SELECT DISTINCT c.boleta, c.clave
    FROM escuela.cursa c
    JOIN escuela.Imparte i
      ON c.clave = i.clave
    WHERE i.numEmpleado = 'P0000001'
      AND c.calif >= 6),
S as
(SELECT DISTINCT clave
FROM escuela.Imparte
WHERE numEmpleado = 'P0000001'),
RXS as
(SELECT a.boleta, s.clave
    FROM (SELECT DISTINCT boleta FROM R) a
    CROSS JOIN S),
 RXS_R as
   (SELECT tc.boleta, tc.clave
    FROM RXS tc
	where not exists (select 1
	                  from R
					  where tc.boleta = r.boleta 
					  AND tc.clave = r.clave))

SELECT boleta
FROM R
EXCEPT
SELECT boleta 
FROM RXS_R
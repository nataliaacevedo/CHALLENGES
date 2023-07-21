--1. Proyectos activos hay por producto
SELECT  product_id, COUNT(*)
FROM FCT_TASKS
WHERE date_closed is null
GROUP BY product_id
;

--2. Proyectos activos hay por equipo
SELECT  _EQUIPO_ID, COUNT(*)
FROM FCT_TASKS
WHERE date_closed is null
GROUP BY _EQUIPO_ID
;

--3.a Tarea padre con la eficiencia más alta
SELECT 
     PARENT_TASK_ID
    ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
FROM FCT_TASKS
WHERE --Filtro por tareas con tiempo estimado y gastado
    TIME_ESTIMATE IS NOT NULL 
    AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
ORDER BY EFFICIENCY DESC
LIMIT 1
;

--3.b Tarea padre con la eficiencia más baja
SELECT 
     PARENT_TASK_ID
    ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
FROM FCT_TASKS
WHERE 
    TIME_ESTIMATE IS NOT NULL 
    AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
ORDER BY EFFICIENCY
LIMIT 1
;

--3.C  Desviación estándar del total de tareas padre
SELECT 
    STDDEV(DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE))
FROM FCT_TASKS

/*
Una eficiencia del 28% en el tiempo gastado respecto al tiempo estimado en una tarea indica que la tarea se ha completado con una eficiencia relativamente baja. 
La eficiencia se calcula como la relación del tiempo gastado al tiempo estimado, por lo que un valor del 28% significa que se ha utilizado aproximadamente el 28% 
del tiempo estimado para completar la tarea.
*/
;

--3.D Promedio de las sub-tareas ( tareas hijas ) por tareas padre
SELECT 
     AVG(TOTAL) AS AVGTASK_PER_PARENT
FROM (
    SELECT PARENT_TASK_ID, COUNT(TASK_ID) TOTAL 
    FROM FCT_TASKS
    GROUP BY PARENT_TASK_ID
)
;

--3.E Medida adicional: Promedio de eficiencia de tareas padre
SELECT
    PARENT_TASK_ID
    ,AVG(EFFICIENCY) AS AVG_EFF
FROM (
    SELECT 
         PARENT_TASK_ID
        ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
    FROM FCT_TASKS
    WHERE 
        TIME_ESTIMATE IS NOT NULL 
        AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
    )
GROUP BY PARENT_TASK_ID
;

--3.F

SELECT
     PARENT_TASK_ID
    ,PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY EFFICIENCY) AS PERCENTIL_25
    ,PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY EFFICIENCY) AS PERCENTIL_75
FROM (
        SELECT 
             PARENT_TASK_ID
            ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
        FROM FCT_TASKS
        WHERE 
            TIME_ESTIMATE IS NOT NULL 
            AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
)
GROUP BY PARENT_TASK_ID
order by PARENT_TASK_ID DESC
;

--3.G  Eficiencia de todas las tareas, por usuario asignado
SELECT 
     USER_ASSIGNES_INITIALS
    ,TASK_ID
    ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
FROM FCT_TASKS
WHERE 
    TIME_ESTIMATE IS NOT NULL 
    AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
ORDER BY USER_ASSIGNES_INITIALS

;

----3.G.i. Usuario con la tarea más eficiente
SELECT 
     USER_ASSIGNES_INITIALS
    ,TASK_ID
    ,DIV0(TIME_SPENT_IN_MILISECONDS,TIME_ESTIMATE) AS EFFICIENCY
FROM FCT_TASKS
WHERE 
    TIME_ESTIMATE IS NOT NULL 
    AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
    AND USER_ASSIGNES_INITIALS IS NOT NULL
ORDER BY EFFICIENCY DESC
LIMIT 1 --nos arroja solamente el valor no 1

;

----3.G.ii. Usuario con mayor eficiencia por total de tareas 

SELECT 
     USER_ASSIGNES_INITIALS
    ,DIV0(TOTAL_SPEND,TOTAL_ESTIMATE) AS EFFICIENCY
FROM (
    SELECT 
         USER_ASSIGNES_INITIALS
        ,SUM(TIME_SPENT_IN_MILISECONDS) TOTAL_SPEND
        ,SUM(TIME_ESTIMATE) AS TOTAL_ESTIMATE
    FROM FCT_TASKS
    WHERE 
        TIME_ESTIMATE IS NOT NULL 
        AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
        AND USER_ASSIGNES_INITIALS IS NOT NULL
    GROUP BY USER_ASSIGNES_INITIALS
)
ORDER BY EFFICIENCY DESC
limit 1 --nos arroja solamente el valor no 1
;


----3.G.iii. Timpo promedio que el usuario gasta para completar una tarea en minutos, segundos y milisegundos

SELECT 
     USER_ASSIGNES_INITIALS
    ,ROUND(AVG(TIME_SPENT_IN_MILISECONDS),2) AS AVG_TIME_SPEND_IN_MILISECONDS
    ,ROUND(AVG(TIME_SPENT_IN_MILISECONDS/1000),2) AS AVG_TIME_SPEND_IN_SECONDS
    ,ROUND(AVG(TIME_SPENT_IN_MILISECONDS)/60000,2) AS AVG_TIME_SPEND_IN_MINUTS
    ,COUNT(TASK_ID) AS TOTAL_TASKS
FROM FCT_TASKS
WHERE 
    TIME_SPENT_IN_MILISECONDS IS NOT NULL
    AND USER_ASSIGNES_INITIALS IS NOT NULL
    AND DATE_CLOSED IS NOT NULL
    AND DATE_DONE IS NOT NULL
GROUP BY USER_ASSIGNES_INITIALS
ORDER BY TIME_SPEND_IN_MINUTS 
;

--3-G.iii usuario con menor eficiencia

SELECT 
     USER_ASSIGNES_INITIALS
    ,DIV0(TOTAL_SPEND,TOTAL_ESTIMATE) AS EFFICIENCY
FROM (
    SELECT 
         USER_ASSIGNES_INITIALS
        ,SUM(TIME_SPENT_IN_MILISECONDS) TOTAL_SPEND
        ,SUM(TIME_ESTIMATE) AS TOTAL_ESTIMATE
    FROM FCT_TASKS
    WHERE 
        TIME_ESTIMATE IS NOT NULL 
        AND TIME_SPENT_IN_MILISECONDS IS NOT NULL
        AND USER_ASSIGNES_INITIALS IS NOT NULL
    GROUP BY USER_ASSIGNES_INITIALS
)
ORDER BY EFFICIENCY
limit 1 --nos arroja solamente el valor no 1

; 

--4. Porcentaje de tareas completadas
----4.A General
SELECT
    ROUND((SELECT COUNT(TASK_ID) FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL)/COUNT(TASK_ID),2)*100 AS PERC_GENERAL_COMPLETED_TASKS
FROM FCT_TASKS
;

----4.B Producto
WITH COMPLETED AS( --se extrae únicamente las tareas completadas por producto
    SELECT
         PRODUCT_ID
        ,COUNT(TASK_ID) AS COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL
    GROUP BY PRODUCT_ID
)

, RESUME AS (SELECT --se extrae el total de tareas
     F.PRODUCT_ID
    ,COMPLETED_TASKS
    ,COUNT(TASK_ID) AS TOTAL_TASKS

FROM FCT_TASKS F
LEFT JOIN COMPLETED C ON F.PRODUCT_ID = C.PRODUCT_ID
GROUP BY F.PRODUCT_ID,COMPLETED_TASKS
)

SELECT
     PRODUCT_NAME
    ,COMPLETED_TASKS
    ,TOTAL_TASKS
    ,CASE WHEN COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(COMPLETED_TASKS/TOTAL_TASKS*100,2) --calculo del %
     END AS PERC_COMPL_TASKS  --Se le asigna 0% a los productos que no tienen ninguna tarea completada

FROM RESUME R
LEFT JOIN DIM_PRODUCTS P ON R.PRODUCT_ID = P.PRODUCT_ID
WHERE PRODUCT_NAME IS NOT NULL
ORDER BY PERC_COMPL_TASKS DESC

;
----4.C Equipo
WITH COMPLETED AS( --se extrae únicamente las tareas completadas por equipo
    SELECT
         _EQUIPO_ID
        ,COUNT(TASK_ID) AS COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL
    GROUP BY _EQUIPO_ID
)

, RESUME AS (SELECT
     F._EQUIPO_ID
    ,COMPLETED_TASKS
    ,COUNT(TASK_ID) AS TOTAL_TASKS

FROM FCT_TASKS F
LEFT JOIN COMPLETED C ON F._EQUIPO_ID = C._EQUIPO_ID
GROUP BY F._EQUIPO_ID,COMPLETED_TASKS
)

SELECT
     NOMBRE_EQUIPO
    ,COMPLETED_TASKS
    ,TOTAL_TASKS
    ,CASE WHEN COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(COMPLETED_TASKS/TOTAL_TASKS*100,2) --calculo del %
     END AS PERC_COMPL_TASKS --Se le asigna 0% a los equipos que no tienen ninguna tarea completada
FROM RESUME R
LEFT JOIN DIM_EQUIPOS E ON R._EQUIPO_ID = E._EQUIPO_ID
WHERE NOMBRE_EQUIPO IS NOT NULL
ORDER BY PERC_COMPL_TASKS DESC
;

--5.A Porcentaje de tareas por cada estado, del total de tareas padre que
--existen(en general)
--Se hace el procedimiento similar al paso anterior y se le adiciona el conteo de tareas no completadas

WITH COMPLETED AS(
    SELECT
         PARENT
        ,COUNT(TASK_ID) AS COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL
    GROUP BY PARENT
)

,NOT_COMPLETED AS(
    SELECT
         PARENT
        ,COUNT(TASK_ID) AS NOT_COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NULL AND DATE_DONE IS NULL
    GROUP BY PARENT
)

, RESUME AS (SELECT
     F.PARENT
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,COUNT(TASK_ID) AS TOTAL_TASKS

FROM FCT_TASKS F
LEFT JOIN COMPLETED C ON F.PARENT = C.PARENT
LEFT JOIN NOT_COMPLETED NC ON F.PARENT = NC.PARENT
GROUP BY F.PARENT,COMPLETED_TASKS, NOT_COMPLETED_TASKS
)

SELECT
     PARENT
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,TOTAL_TASKS
    ,CASE WHEN COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_COMPL_TASKS
    ,CASE WHEN NOT_COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(NOT_COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_NOT_COMPL_TASKS
FROM RESUME R
ORDER BY PERC_COMPL_TASKS DESC

;
--5.B Porcentaje de tareas por cada estado, del total de tareas padre que
--existen  (por producto)
WITH COMPLETED AS(
    SELECT
        PRODUCT_ID
        ,COUNT(PARENT_TASK_ID) AS COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL
    GROUP BY PRODUCT_ID
)

,NOT_COMPLETED AS(
    SELECT
        PRODUCT_ID
        ,COUNT(PARENT_TASK_ID) AS NOT_COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NULL AND DATE_DONE IS NULL
    GROUP BY PRODUCT_ID
)

, RESUME AS (SELECT
     F.PRODUCT_ID
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,COUNT(PARENT_TASK_ID) AS TOTAL_TASKS

FROM FCT_TASKS F
LEFT JOIN COMPLETED C ON F.PRODUCT_ID = C.PRODUCT_ID
LEFT JOIN NOT_COMPLETED NC ON F.PRODUCT_ID = NC.PRODUCT_ID
GROUP BY F.PRODUCT_ID, COMPLETED_TASKS, NOT_COMPLETED_TASKS
)

SELECT
    PRODUCT_NAME
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,TOTAL_TASKS
    ,CASE WHEN COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_COMPL_TASKS
    ,CASE WHEN NOT_COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(NOT_COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_NOT_COMPL_TASKS
FROM RESUME R 
LEFT JOIN DIM_PRODUCTS P ON R.PRODUCT_ID = P.PRODUCT_ID

ORDER BY PERC_COMPL_TASKS DESC

;
--5.C Porcentaje de tareas por cada estado, del total de tareas padre que
--existen(por equipo)

WITH COMPLETED AS(
    SELECT
        _EQUIPO_ID
        ,COUNT(PARENT_TASK_ID) AS COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NOT NULL AND DATE_DONE IS NOT NULL
    GROUP BY _EQUIPO_ID
)

,NOT_COMPLETED AS(
    SELECT
        _EQUIPO_ID
        ,COUNT(PARENT_TASK_ID) AS NOT_COMPLETED_TASKS
    FROM FCT_TASKS
    WHERE DATE_CLOSED IS NULL AND DATE_DONE IS NULL
    GROUP BY _EQUIPO_ID
)

, RESUME AS (SELECT
     F._EQUIPO_ID
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,COUNT(PARENT_TASK_ID) AS TOTAL_TASKS

FROM FCT_TASKS F
LEFT JOIN COMPLETED C ON F._EQUIPO_ID = C._EQUIPO_ID
LEFT JOIN NOT_COMPLETED NC ON F._EQUIPO_ID = NC._EQUIPO_ID
GROUP BY F._EQUIPO_ID, COMPLETED_TASKS, NOT_COMPLETED_TASKS
)

SELECT
    NOMBRE_EQUIPO
    ,COMPLETED_TASKS
    ,NOT_COMPLETED_TASKS
    ,TOTAL_TASKS
    ,CASE WHEN COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_COMPL_TASKS
    ,CASE WHEN NOT_COMPLETED_TASKS IS NULL THEN 0
          ELSE ROUND(NOT_COMPLETED_TASKS/TOTAL_TASKS*100,2)
     END AS PERC_NOT_COMPL_TASKS
FROM RESUME R 
LEFT JOIN DIM_EQUIPOS P ON R._EQUIPO_ID = P._EQUIPO_ID

ORDER BY PERC_COMPL_TASKS DESC

;

--6. Calcular la cantidad de tareas padre ( proyectos ) por semana de creación.

SELECT
     DATE_TRUNC('WEEK', DATE_CREATED::DATE) AS WEEK --Se trunquea por semana y se agrupa por el número de tareas
    ,COUNT(PARENT_TASK_ID) TOTAL_PARENT_TASKS
FROM FCT_TASKS
GROUP BY WEEK
ORDER BY WEEK
;

--7. Calcular la cantidad de tareas padre ( proyectos ) por mes de creación.
SELECT
     DATE_TRUNC('MONTH', DATE_CREATED::DATE) AS MONTH --Se trunquea por mes y se agrupa por el número de tareas
    ,COUNT(PARENT_TASK_ID) TOTAL_PARENT_TASKS
FROM FCT_TASKS
GROUP BY MONTH
ORDER BY MONTH

;

--8. Calcular la cantidad de tareas padre ( proyectos ) por trimestre de creación
SELECT
     DATE_TRUNC('QUARTER', DATE_CREATED::DATE) AS QUARTER --Se trunquea por trimestre y se agrupa por el número de tareas
    ,COUNT(PARENT_TASK_ID) TOTAL_PARENT_TASKS
FROM FCT_TASKS
GROUP BY QUARTER
ORDER BY QUARTER

;

--PARTE 3 
--Extracción de claves y valores:
--Ya que estos datos tenian varios niveles de anidación/indentación se tiene que especificar los niveles de anidación options>>value>> 'key a extraer'
--Adicionalmente se define el tipo de dato de cada key
CREATE OR REPLACE VIEW view_json AS
SELECT 
   T.ID AS ID_ORIGINAL
  ,option.value:color::STRING as color
  ,option.value:id::STRING as id
  ,option.value:name::STRING as name
  ,option.value:orderindex::INT as orderindex
FROM 
  TYPE_CONFIG T,
  LATERAL FLATTEN(input => TYPE_CONFIG:options) option --función para extraer claves y valores de un dato tipo VARIANT (JSON)
;

/*

9. Relaciones entre variables

    - PARENT_TASK_ID son las tareas padre y estas contienen múltiples sub-tareas (TASK_ID)
    - Existe una tarea padre pero las subtareas pueden tener hasta 3 nivelees de profundidad
    - La mauoría de tareas existentes se asignan a un equipo y usuario y cada una de ellas hace parte de un producto
    - Se calcula el tiempo estimado y el tiempo gastado en completar una tarea para posteriormente medir la eficiencia por equipos y usuarios

10. Conclusiones adicionales

    - Existe 74 mil tareas en total de las cuales sólo el 20% de las tareas existentes se han completado
    - Existen aproximandamente 3000  sin equipo asignado hasta el momento de los 15000 proyectos activos en la actualidad
    - El equipo B es el equipo con mayor número de tareas asignadas
    - Mayo de 2023 fue el mes con mayor creación de tareas respecto a los demás meses
    - El producto WEN | KD-WEB es el que mayor tareas contiene con un 20% de tareas completadas
    - El promedio existen 6.32 sub-tareas por tarea padre




*/

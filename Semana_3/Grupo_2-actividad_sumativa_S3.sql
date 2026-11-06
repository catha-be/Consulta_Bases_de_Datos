-- =============================================================================
-- Semana 3 - Actividad sumativa: "Aplicando funciones de agrupación"
-- Empresa ASOCIADOS - Usuario: PRY2205_S3
-- Requisito: haber ejecutado PRY2205_Exp1_S3_CreaEsquemaPoblado (forma B).SQL
-- =============================================================================

-- =============================================================================
-- CASO 1: Análisis de Propiedades
-- Resumen por tipo de propiedad. Solo se muestran los tipos cuyo total de gasto
-- común supera el valor ingresado por el operador (variable de sustitución).
-- =============================================================================
SELECT
    TP.desc_tipo_propiedad                                        AS "TIPO PROPIEDAD",
    COUNT(P.nro_propiedad)                                        AS "TOTAL PROPIEDADES",
    TO_CHAR(ROUND(MAX(P.valor_arriendo)),
            'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')    AS "MAXIMO ARRIENDO",
    TO_CHAR(ROUND(MIN(P.valor_arriendo)),
            'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')    AS "MINIMO ARRIENDO",
    TO_CHAR(ROUND(AVG(P.valor_arriendo)),
            'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')    AS "PROMEDIO ARRIENDO",
    -- Clasificación según el valor máximo de arriendo del tipo
    CASE
        WHEN MAX(P.valor_arriendo) > 1000000 THEN 'PREMIUM'
        ELSE 'ESTÁNDAR'
    END                                                           AS "CLASIFICACION",
    TO_CHAR(ROUND(SUM(NVL(P.valor_gasto_comun, 0))),
            'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')    AS "TOTAL GASTO COMUN"
FROM propiedad P
JOIN tipo_propiedad TP
  ON TP.id_tipo_propiedad = P.id_tipo_propiedad
GROUP BY TP.desc_tipo_propiedad
HAVING SUM(NVL(P.valor_gasto_comun, 0)) > 100000
ORDER BY SUM(NVL(P.valor_gasto_comun, 0)) DESC;

-- =============================================================================
-- CASO 2: Análisis de antigüedad de empleados
-- Ejecutivos de Arriendo (categoría 3) con más de 5 años de antigüedad que NO
-- pertenezcan a la sucursal ingresada por el operador.
-- =============================================================================
SELECT
    E.numrut_emp || '-' || E.dvrut_emp                            AS "RUT EMPLEADO",
    INITCAP(E.nombre_emp || ' ' || E.appaterno_emp || ' ' || E.apmaterno_emp)
                                                                  AS "NOMBRE EMPLEADO",
    E.fecing_emp                                                  AS "FECHA INGRESO",
    TRUNC(MONTHS_BETWEEN(SYSDATE, E.fecing_emp) / 12)             AS "AÑOS ANTIGUEDAD",
    TO_CHAR(E.sueldo_emp, 'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
                                                                  AS "SUELDO",
    -- Nivel de sueldo
    CASE
        WHEN E.sueldo_emp > 2000000 THEN 'ALTO'
        ELSE 'MEDIO'
    END                                                           AS "NIVEL SUELDO",
    -- Bono de antigüedad según tramo de años de servicio
    TO_CHAR(
        ROUND(E.sueldo_emp *
            CASE
                WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, E.fecing_emp) / 12) > 20 THEN 0.15
                WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, E.fecing_emp) / 12) >= 11 THEN 0.10
                ELSE 0.05
            END),
        'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')        AS "BONO ANTIGUEDAD"
FROM empleado E
WHERE E.id_categoria_emp = 3
  AND MONTHS_BETWEEN(SYSDATE, E.fecing_emp) / 12 > 5
  AND E.id_sucursal <> 30
ORDER BY E.sueldo_emp DESC;

-- =============================================================================
-- CASO 3: Lista de clientes
-- Clasificación por renta, cantidad de clientes y disponibilidad de teléfono.
-- Solo se consideran las clasificaciones con promedio de renta sobre $200.000.
-- =============================================================================
SELECT
    CASE
        WHEN C.renta_cli >= 1000000 THEN 'PREMIUM'
        WHEN C.renta_cli >= 600000  THEN 'ALTA'
        WHEN C.renta_cli >= 300000  THEN 'MEDIA'
        ELSE 'BAJA'
    END                                                           AS "CLASIFICACION RENTA",
    COUNT(*)                                                      AS "CANTIDAD CLIENTES",
    TO_CHAR(ROUND(AVG(C.renta_cli)),
            'FM$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')    AS "PROMEDIO RENTA",
    -- COUNT(columna) ignora los nulos: 0 => ningún cliente del grupo tiene celular
    CASE
        WHEN COUNT(C.celular_cli) = 0 THEN 'Clientes sin Teléfono'
        ELSE 'Clientes con Teléfono'
    END                                                           AS "TELEFONO"
FROM cliente C
GROUP BY CASE
             WHEN C.renta_cli >= 1000000 THEN 'PREMIUM'
             WHEN C.renta_cli >= 600000  THEN 'ALTA'
             WHEN C.renta_cli >= 300000  THEN 'MEDIA'
             ELSE 'BAJA'
         END
HAVING AVG(C.renta_cli) > 200000
ORDER BY AVG(C.renta_cli) DESC;

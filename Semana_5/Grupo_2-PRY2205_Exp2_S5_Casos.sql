-- =============================================================================
-- PRY2205 | Semana 5 | Actividad formativa: Subconsultas
-- Caso FinanCorp - Gestión de clientes y productos financieros
-- Usuario: PRY2205_S5
-- (ejecutar antes PRY2205_Exp2_S5_Script_crea_usuario.sql como ADMIN y
--  PRY2205_Exp2_S5_CreaEsquemaPoblado.sql como PRY2205_S5)
-- =============================================================================

-- =============================================================================
-- CASO 1: Listado de Clientes
-- Clientes trabajadores dependientes cuya profesión u oficio es Contador o
-- Vendedor, inscritos en un año mayor al promedio redondeado de los años de
-- inscripción de todos los clientes (promedio obtenido con subconsulta).
-- Orden: RUT del cliente ascendente.
-- =============================================================================
SELECT
    TO_CHAR(c.numrun, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || LOWER(c.dvrun)                                  AS "RUT Cliente",
    INITCAP(TRIM(c.pnombre) || ' ' || TRIM(c.appaterno))          AS "Nombre Cliente",
    UPPER(po.nombre_prof_ofic)                                    AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY')                    AS "Fecha de Inscripción",
    NVL(c.direccion, 'SIN DIRECCIÓN')                             AS "Dirección Cliente"
FROM cliente c
    JOIN profesion_oficio po ON po.cod_prof_ofic    = c.cod_prof_ofic
    JOIN tipo_cliente     tc ON tc.cod_tipo_cliente = c.cod_tipo_cliente
WHERE UPPER(tc.nombre_tipo_cliente) = 'TRABAJADORES DEPENDIENTES'
  AND UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
  AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
           FROM cliente)
ORDER BY c.numrun ASC;

-- =============================================================================
-- CASO 2: Aumento de crédito
-- RUT y edad de los clientes cuyo cupo disponible para compras es mayor o igual
-- al máximo cupo disponible para compras de las tarjetas solicitadas el año
-- anterior al actual (máximo obtenido con subconsulta). El resultado se
-- almacena en la tabla CLIENTES_CUPOS_COMPRA, creada a partir de la consulta.
-- Orden: edad ascendente.
-- =============================================================================
-- Si la tabla ya existe (re-ejecución), eliminarla antes:
-- DROP TABLE clientes_cupos_compra;
CREATE TABLE clientes_cupos_compra AS
SELECT
    CONCAT(CONCAT(TO_CHAR(c.numrun), '-'), UPPER(c.dvrun))        AS rut_cliente,
    EXTRACT(YEAR FROM SYSDATE)
        - EXTRACT(YEAR FROM c.fecha_nacimiento)                   AS edad,
    TO_CHAR(tj.cupo_disp_compra, '$9G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')                      AS cupo_disponible_compra,
    UPPER(tc.nombre_tipo_cliente)                                 AS tipo_cliente
FROM cliente c
    JOIN tarjeta_cliente tj ON tj.numrun           = c.numrun
    JOIN tipo_cliente    tc ON tc.cod_tipo_cliente = c.cod_tipo_cliente
WHERE tj.cupo_disp_compra >=
        (SELECT MAX(t2.cupo_disp_compra)
           FROM tarjeta_cliente t2
          WHERE EXTRACT(YEAR FROM t2.fecha_solic_tarjeta) =
                EXTRACT(YEAR FROM SYSDATE) - 1)
ORDER BY edad ASC;

SELECT * FROM clientes_cupos_compra
ORDER BY edad ASC;

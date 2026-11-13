-- =============================================================================
-- PRY2205 | Semana 4 | Actividad formativa: JOINS
-- Caso Conciertos Chile S.A.
-- Usuario: PRY2205_S4
-- (ejecutar antes PRY2205_Exp2_S4_Script_crea_usuario.sql como ADMIN y
--  PRY2205_Exp2_S4_CreaEsquemaPoblado.sql como PRY2205_S4)
-- =============================================================================

-- =============================================================================
-- CASO 1: Listado de Trabajadores
-- Trabajadores con sueldo base entre $650.000 y $3.000.000, con su tipo de
-- trabajador y su ciudad. Orden: ciudad descendente, sueldo base ascendente.
-- =============================================================================
SELECT
    UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno)   AS "Nombre Completo Trabajador",
    TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || UPPER(t.dvrut)                                  AS "RUT Trabajador",
    UPPER(tt.desc_categoria)                                      AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad)                                       AS "Ciudad Trabajador",
    TO_CHAR(t.sueldo_base, '$9G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')                      AS "Sueldo Base"
FROM trabajador t
    JOIN tipo_trabajador tt ON tt.id_categoria = t.id_categoria_t
    JOIN comuna_ciudad   cc ON cc.id_ciudad    = t.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base ASC;

-- =============================================================================
-- CASO 2: Listado de Cajeros
-- Trabajadores con rol CAJERO que han vendido tickets: cantidad de tickets,
-- total vendido y comisión total. Solo se muestran aquellos cuya suma de
-- montos de tickets supera $50.000. Orden: total vendido descendente.
-- =============================================================================
SELECT
    TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || UPPER(t.dvrut)                                  AS "RUT Trabajador",
    INITCAP(t.nombre) || ' ' || UPPER(t.appaterno)                AS "Nombre Trabajador",
    COUNT(tc.nro_ticket)                                          AS "Total Tickets",
    TO_CHAR(SUM(tc.monto_ticket), '$99G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')                      AS "Total Vendido",
    TO_CHAR(SUM(NVL(ct.valor_comision, 0)), '$99G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')                      AS "Comisión Total",
    UPPER(tt.desc_categoria)                                      AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad)                                       AS "Ciudad Trabajador"
FROM trabajador t
    JOIN tipo_trabajador   tt ON tt.id_categoria = t.id_categoria_t
    JOIN comuna_ciudad     cc ON cc.id_ciudad    = t.id_ciudad
    JOIN tickets_concierto tc ON tc.numrut_t     = t.numrut
    LEFT JOIN comisiones_ticket ct ON ct.nro_ticket = tc.nro_ticket   -- un ticket podría no tener comisión
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno,
         tt.desc_categoria, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;

-- =============================================================================
-- CASO 3: Listado de Bonificaciones
-- Por trabajador: año de ingreso, años de antigüedad, cantidad de cargas
-- familiares, isapre, AFP y estado civil vigente.
--   Bono Fonasa     : 1% del sueldo base solo si su sistema de salud es FONASA.
--   Bono Antigüedad : 10% del sueldo con 10 o menos años; 15% con 11 o más.
-- Solo se considera el estado civil sin fecha de término o con fecha de
-- término posterior a la fecha de ejecución (SYSDATE). Orden: RUT ascendente.
-- =============================================================================
SELECT
    TO_CHAR(t.numrut, 'FM99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')   AS "RUT Trabajador",
    INITCAP(t.nombre || ' ' || t.appaterno)                              AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing)                                          AS "Año Ingreso",
    EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)             AS "Años Antigüedad",
    COUNT(af.numrut_carga)                                               AS "Num. Cargas Familiares",
    LPAD(INITCAP(i.nombre_isapre), 12)                                   AS "Nombre Isapre",
    TO_CHAR(t.sueldo_base, '$9G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')                             AS "Sueldo Base",
    CASE
        WHEN UPPER(i.nombre_isapre) = 'FONASA'
            THEN TO_CHAR(ROUND(t.sueldo_base * 0.01), '$9G999G999',
                         'NLS_NUMERIC_CHARACTERS='',.''')
        ELSE LPAD('0', 11)
    END                                                                  AS "Bono Fonasa",
    TO_CHAR(
        ROUND(t.sueldo_base *
              CASE
                  WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing) <= 10 THEN 0.10
                  ELSE 0.15
              END),
        '$9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''')                   AS "Bono Antigüedad",
    INITCAP(a.nombre_afp)                                                AS "Nombre AFP",
    UPPER(ec.desc_estcivil)                                              AS "Estado Civil"
FROM trabajador t
    JOIN isapre       i  ON i.cod_isapre   = t.cod_isapre
    JOIN afp          a  ON a.cod_afp      = t.cod_afp
    JOIN est_civil    e  ON e.numrut_t     = t.numrut
    JOIN estado_civil ec ON ec.id_estcivil = e.id_estcivil_est
    LEFT JOIN asignacion_familiar af ON af.numrut_t = t.numrut           -- incluye trabajadores sin cargas
WHERE e.fecter_estcivil IS NULL
   OR e.fecter_estcivil > SYSDATE
GROUP BY t.numrut, t.nombre, t.appaterno, t.fecing, t.sueldo_base,
         i.nombre_isapre, a.nombre_afp, ec.desc_estcivil
ORDER BY t.numrut ASC;

-- ============================================================
-- PRY2205 - Consulta de Bases de Datos - Semana 2
-- Actividad: Creando consultas utilizando funciones SQL
-- Usuario: PRY2205_S2
-- ============================================================

ALTER SESSION SET NLS_DATE_LANGUAGE = 'SPANISH';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';

-- ------------------------------------------------------------
-- CASO 1: Análisis de Facturas
-- Facturas emitidas el año anterior al año de ejecución
-- ------------------------------------------------------------
SELECT F.NUMFACTURA                                          AS "N° Factura",
       TO_CHAR(F.FECHA, 'DD "de" Month YYYY')                AS "Fecha Emisión",
       LPAD(F.RUTCLIENTE, 10, '0')                           AS "RUT Cliente",
       TO_CHAR(F.NETO, '$99G999G999')                        AS "Monto Neto",
       TO_CHAR(F.IVA,  '$99G999G999')                        AS "Monto Iva",
       TO_CHAR(F.TOTAL, '$99G999G999')                       AS "Total Factura",
       CASE
            WHEN F.TOTAL <= 50000  THEN 'Bajo'
            WHEN F.TOTAL <= 100000 THEN 'Medio'
            ELSE 'Alto'
       END                                                   AS "Categoría Monto",
       CASE F.CODPAGO
            WHEN 1 THEN 'EFECTIVO'
            WHEN 2 THEN 'TARJETA DEBITO'
            WHEN 3 THEN 'TARJETA CREDITO'
            ELSE 'CHEQUE'
       END                                                   AS "Forma de pago"
FROM   FACTURA F
WHERE  EXTRACT(YEAR FROM F.FECHA) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY F.FECHA DESC, F.NETO DESC;

-- ------------------------------------------------------------
-- CASO 2: Clasificación de Clientes
-- Clientes con estado 'A' y crédito mayor a 0
-- ------------------------------------------------------------
SELECT LPAD(C.RUTCLIENTE, 12, '*')                           AS "RUT",
       C.NOMBRE                                              AS "Cliente",
       NVL(TO_CHAR(C.TELEFONO), 'Sin teléfono')              AS "TELÉFONO",
       NVL(TO_CHAR(C.CODCOMUNA), 'Sin comuna')               AS "COMUNA",
       C.ESTADO                                              AS "ESTADO",
       CASE
            WHEN C.SALDO / C.CREDITO < 0.5
                 THEN 'Bueno ('  || TO_CHAR(C.CREDITO - C.SALDO, '$999G999G999') || ')'
            WHEN C.SALDO / C.CREDITO <= 0.8
                 THEN 'Regular (' || TO_CHAR(C.SALDO, '$999G999G999') || ')'
            ELSE 'Crítico'
       END                                                   AS "Estado Crédito",
       NVL(UPPER(SUBSTR(C.MAIL, INSTR(C.MAIL, '@') + 1)),
           'Correo no registrado')                           AS "Dominio Correo"
FROM   CLIENTE C
WHERE  C.ESTADO = 'A'
AND    C.CREDITO > 0
ORDER BY C.NOMBRE ASC;

-- ------------------------------------------------------------
-- CASO 3: Stock de productos
-- Variables de sustitución: TIPOCAMBIO_DOLAR, UMBRAL_BAJO, UMBRAL_ALTO
-- (ejemplo del informe: 950, 40, 60)
-- ------------------------------------------------------------
SELECT P.CODPRODUCTO                                         AS "ID",
       P.DESCRIPCION                                         AS "Descripción de Producto",
       NVL(TO_CHAR(P.VALORCOMPRADOLAR, 'FM999990D99') || ' USD',
           'Sin registro')                                   AS "Compra en USD",
       NVL(TO_CHAR(ROUND(P.VALORCOMPRADOLAR * &TIPOCAMBIO_DOLAR),
                   'FM$999G999G999') || ' PESOS',
           'Sin registro')                                   AS "USD convertido",
       P.TOTALSTOCK                                          AS "Stock",
       CASE
            WHEN P.TOTALSTOCK IS NULL            THEN 'Sin datos'
            WHEN P.TOTALSTOCK <  &UMBRAL_BAJO    THEN '¡ALERTA stock muy bajo!'
            WHEN P.TOTALSTOCK <= &UMBRAL_ALTO    THEN '¡Reabastecer pronto!'
            ELSE 'OK'
       END                                                   AS "Alerta Stock",
       CASE
            WHEN P.TOTALSTOCK > 80
                 THEN TO_CHAR(ROUND(P.VUNITARIO * 0.9), 'FM$999G999G999')
            ELSE 'N/A'
       END                                                   AS "Precio Oferta"
FROM   PRODUCTO P
WHERE  UPPER(P.DESCRIPCION) LIKE '%ZAPATO%'
AND    UPPER(P.PROCEDENCIA) = 'I'
ORDER BY P.CODPRODUCTO DESC;

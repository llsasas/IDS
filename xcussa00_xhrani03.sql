/*
    IDS Projekt 2
    Zadání projektu: č. 26 - Banka

    Autoři: Samuel Čus   (xcussa00)
            Jan Hranička (xhrani03)
*/

 DROP TABLE DISPONOVANI;
 DROP TABLE OPERACE_S_UCTEM;
 DROP TABLE UCET;
 DROP TABLE KLIENT;
 DROP TABLE PRACOVNIK_BANKY;
 DROP SEQUENCE operace_seq;

/*
    Vztah generalizace/specializace jsme implementovali tvorbou dvou různých tabulek: KLIENT a PRACOVNIK_BANKY
    Pro tento způsob jsme se rozhodli, protože práce s těmito tabulkami je velmi odlišná
*/
CREATE TABLE KLIENT (
    ID INT NOT NULL PRIMARY KEY,
    JMENO VARCHAR(31),
    PRIJMENI VARCHAR(63),
    EMAIL VARCHAR(127),
    TELEFONNI_CISLO NUMERIC(9),
    STAT VARCHAR(31),
    MESTO VARCHAR(63),
    ULICE VARCHAR(63),
    CISLO_POPISNE NUMERIC(6),
    PSC NUMERIC(5)
);

CREATE TABLE PRACOVNIK_BANKY (
    ID INT NOT NULL PRIMARY KEY,
    JMENO VARCHAR(31),
    PRIJMENI VARCHAR(63),
    EMAIL VARCHAR(127),
    TELEFONNI_CISLO NUMERIC(9),
    LOGIN VARCHAR(63) NOT NULL,
    HESLO VARCHAR(127)
);

CREATE TABLE UCET (
    CISLO_UCTU INT 
        PRIMARY KEY
        CHECK (MOD(CISLO_UCTU, 11) = 0),
    DATUM_ZALOZENI DATE,
    ZUSTATEK NUMERIC(10),

    VLASTNIK INT NOT NULL,
    FOREIGN KEY (VLASTNIK) REFERENCES KLIENT (ID)
);

CREATE TABLE DISPONOVANI (
    DISPONENT INT NOT NULL,
    CISLO_UCTU INT NOT NULL,

    PRIMARY KEY (DISPONENT, CISLO_UCTU),

    FOREIGN KEY (DISPONENT) REFERENCES KLIENT (ID),
    FOREIGN KEY (CISLO_UCTU) REFERENCES UCET (CISLO_UCTU)
);

CREATE SEQUENCE operace_seq
    START WITH 1
    INCREMENT BY 1;

CREATE TABLE OPERACE_S_UCTEM (
    CISLO_UCTU INT NOT NULL,
    PORADOVE_CISLO INT DEFAULT operace_seq.nextval,
    DATUM DATE,
    TYP VARCHAR(6),
    CASTKA NUMERIC(10),
    MENA VARCHAR(10),
    CILOVY_UCET INT,
    POPIS VARCHAR(1024),

    PROVEDL INT NOT NULL, 
    ZADAL INT NOT NULL,

    PRIMARY KEY (CISLO_UCTU, PORADOVE_CISLO),
    FOREIGN KEY (CISLO_UCTU) REFERENCES UCET (CISLO_UCTU),
    FOREIGN KEY (ZADAL) REFERENCES KLIENT (ID),
    FOREIGN KEY (PROVEDL) REFERENCES PRACOVNIK_BANKY (ID)
);


GRANT ALL ON UCET TO xhrani03;
GRANT ALL ON KLIENT TO xhrani03;
GRANT ALL ON PRACOVNIK_BANKY TO xhrani03;
GRANT ALL ON OPERACE_S_UCTEM TO xhrani03;
GRANT ALL ON operace_seq TO xhrani03;
GRANT ALL ON DISPONOVANI TO xhrani03;

--TRIGGERS



CREATE OR REPLACE TRIGGER prepocitej_zustatek
    AFTER INSERT ON OPERACE_S_UCTEM
    REFERENCING NEW AS NOVY
    FOR EACH ROW
DECLARE
    stara_castka NUMERIC(10)
BEGIN
    SELECT U.ZUSTATEK INTO stara_castka FROM UCET U WHERE U.CISLO_UCTU = :NOVY.CISLO_UCTU;

    IF :NOVY.TYP = 'vklad' THEN
        UPDATE UCET SET ZUSTATEK = stara_castka + :NOVY.CASTKA;
    ELSE
        UPDATE UCET SET ZUSTATEK = stara_castka - :NOVY.CASTKA;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER vloz_datum
    BEFORE INSERT ON UCET
    REFERENCING NEW AS NOVY
    FOR EACH ROW
BEGIN
    IF :NOVY.DATUM_ZALOZENI IS NULL THEN
        :NOVY.DATUM_ZALOZENI := SYSDATE;
    END IF;
END;
/


-- PROCEDURES

-- vypise, kterych operaci nad uctem bzlo provedeno nejvic
CREATE OR REPLACE PROCEDURE operaci_nad_uctem(identifikator_uctu UCET.CISLO_UCTU%TYPE)
AS
    CURSOR typ_kurzor IS SELECT TYP FROM OPERACE_S_UCTEM;
    typ_operace OPERACE_S_UCTEM.TYP%TYPE;
    p_vkladu NUMBER;
    p_vyberu NUMBER;
    p_prevodu NUMBER;
BEGIN

    p_vkladu := 0;
    p_vyberu := 0;
    p_prevodu := 0;

    OPEN typ_kurzor;
    LOOP
    FETCH typ_kurzor INTO typ_operace;
        CASE
            WHEN typ_operace = 'vklad' THEN p_vkladu := p_vkladu + 1;
            WHEN typ_operace = 'vyber' THEN p_vyberu := p_vyberu + 1;
            WHEN typ_operace = 'prevod' THEN p_prevodu := p_prevodu + 1;
        END;
        IF typ_operace = 'vklad' THEN p_vkladu := p_vkladu + 1;
        ELSIF typ_operace = 'vyber' THEN p_vyberu := p_vyberu + 1;
        ELSIF typ_operace = 'prevod' THEN p_prevodu := p_prevodu + 1;
        END IF;
    END LOOP;
    CLOSE typ_kurzor;

    IF p_vkladu = p_vyberu THEN
        IF p_prevodu > p_vkladu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl převod.' );
        ELSIF p_prevodu < p_vkladu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl vklad a výběr.' );
        ELSE
            DBMS_OUTPUT.put_line( 'Všechny operace se provedli stejněkrát.' );
        END IF;

    ELSIF p_vkladu > p_vyberu THEN
        IF p_prevodu > p_vkladu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl převod.' );
        ELSIF p_prevodu < p_vkladu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl vklad.' );
        ELSE
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl vklad a převod.' );
        END IF;

    ELSE
        IF p_prevodu > p_vyberu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl převod.' );
        ELSIF p_prevodu < p_vyberu THEN
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl výběr.' );
        ELSE
            DBMS_OUTPUT.put_line( 'Nejvíckrát se provedl výběr a převod.' );
        END IF;
    END IF;

END;


-- obnos klienta na uctech, ktere vlastni
CREATE OR REPLACE PROCEDURE obnos_klienta(jmeno_klienta IN VARCHAR, prijmeni_klienta IN VARCHAR)
AS
    CURSOR zustatky IS SELECT VLASTNIK, ZUSTATEK FROM UCET;
    id_klienta KLIENT.ID%TYPE;
    id_vlastnika KLIENT.ID%TYPE;
    z UCET.ZUSTATEK%TYPE;
    obnos NUMBER;
BEGIN

    obnos := 0;

    SELECT ID INTO id_klienta FROM KLIENT K WHERE K.JMENO = jmeno_klienta AND K.PRIJMENI = prijmeni_klienta; 

    OPEN zustatky;
    LOOP
    FETCH zustatky INTO id_vlastnika, z;
        EXIT WHEN zustatky%NOTFOUND;

        IF id_vlastnika = id_klienta THEN
            obnos := obnos + z;
        END IF;
    END LOOP;
    CLOSE zustatky;

    DBMS_OUTPUT.put_line(
        jmeno_klienta || ' ' || prijmeni_klienta || ' má na vlastněných účtech ' || obnos || ' peněz'
    );

    EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
        DBMS_OUTPUT.put_line(
            'Klient s identifikatorem ' || id_klienta || ' neexistuje!'
        );
    END;
END;



--DROP TRIGGER prepocitej_zustatek;

-- Vkladani

INSERT INTO PRACOVNIK_BANKY (ID, JMENO, PRIJMENI, LOGIN, EMAIL, HESLO)
    VALUES (100, 'Samuel', 'Cus', 'xcussa00', 'xcussa00@vutbr.cz', 'mnaumnauhafhaf');

INSERT INTO PRACOVNIK_BANKY (ID, JMENO, PRIJMENI, LOGIN, EMAIL, HESLO)
    VALUES (200, 'Jan', 'Hranicka', 'xhrani03', 'xhrani03@vutbr.cz', '1234');

INSERT INTO KLIENT (ID, JMENO, PRIJMENI, EMAIL, STAT, MESTO)
    VALUES (1, 'Albert', 'Plagiator', 'xplagi0b@oznuk.fit', 'CR', 'Brno');

INSERT INTO KLIENT (ID, JMENO, PRIJMENI, EMAIL, STAT, MESTO)
    VALUES (2, 'Jakub', 'Terminator', 'kubik@seznam.cz', 'CR', 'Brno');

INSERT INTO KLIENT (ID, JMENO, PRIJMENI, EMAIL, STAT, MESTO)
    VALUES (42, 'Teodor', 'Gladiator', 'teos@gmail.com', 'CR', 'Praha');

INSERT INTO UCET (CISLO_UCTU, ZUSTATEK, VLASTNIK)
    VALUES (2816, 10, 1);

INSERT INTO UCET (CISLO_UCTU, DATUM_ZALOZENI, ZUSTATEK, VLASTNIK)
    VALUES (111331,TO_DATE('2020-03-24', 'yyyy/mm/dd'), 10000, 2);

INSERT INTO DISPONOVANI (DISPONENT, CISLO_UCTU)
    VALUES (42, 111331);

INSERT INTO OPERACE_S_UCTEM (CISLO_UCTU, DATUM, TYP, CASTKA, MENA, PROVEDL, ZADAL)
    VALUES (2816, TO_DATE('2023-03-26', 'yyyy/mm/dd'), 'vklad', 2000, 'czk', 100, 1);

INSERT INTO OPERACE_S_UCTEM (CISLO_UCTU, DATUM, TYP, CASTKA, MENA, PROVEDL, ZADAL)
    VALUES (111331, TO_DATE('2023-03-26', 'yyyy/mm/dd'), 'vyber', 1000, 'czk', 100, 2);

INSERT INTO OPERACE_S_UCTEM (CISLO_UCTU, DATUM, TYP, CASTKA, MENA, PROVEDL, ZADAL)
    VALUES (111331, TO_DATE('2023-03-26', 'yyyy/mm/dd'), 'vklad', 2000, 'czk', 100, 42);

INSERT INTO OPERACE_S_UCTEM (CISLO_UCTU, DATUM, TYP, CASTKA, MENA, CILOVY_UCET, PROVEDL, ZADAL)
    VALUES (111331, TO_DATE('2023-03-25', 'yyyy/mm/dd'), 'prevod', 100, 'czk', 111111, 200, 42);
    
-- MATERIALIZED VIEW   

CREATE MATERIALIZED VIEW POCET_UCTU_KLIENTA
    AS SELECT K.ID ,K.JMENO, K.PRIJMENI, COUNT(*) AS POCET_UCTU 
    FROM KLIENT K JOIN UCET U ON K.ID = U.VLASTNIK 
    GROUP BY K.ID,K.JMENO, K.PRIJMENI;
    
SELECT * FROM POCET_UCTU_KLIENTA;
    
DROP MATERIALIZED VIEW POCET_UCTU_KLIENTA;
-- Dotazy

-- Kteří klienti mají na účtu zůstatek větší nebo roven 1000?
SELECT K.JMENO, K.PRIJMENI, U.ZUSTATEK
    FROM KLIENT K JOIN UCET U ON K.ID = U.VLASTNIK
    WHERE U.ZUSTATEK >= 1000;
    
    
-- Kterými účty někdo disponuje?
SELECT DISTINCT U.CISLO_UCTU
    FROM UCET U JOIN DISPONOVANI D ON U.CISLO_UCTU = D.CISLO_UCTU;
    
-- Kteří klienti zadali operaci vklad a kteří pracovníci ho provedli
SELECT K.JMENO AS JMENO_KLIENTA, K.PRIJMENI AS PRIJMENI_KLIENTA, P.LOGIN AS LOGIN_PRACOVNIKA
    FROM KLIENT K JOIN OPERACE_S_UCTEM O ON K.ID = O.ZADAL
        JOIN PRACOVNIK_BANKY P ON O.PROVEDL = P.ID
    WHERE TYP = 'vklad';
    
-- Kolik vlastí jednotliví klienti účtů
SELECT K.ID, K.JMENO, K.PRIJMENI, COUNT(U.CISLO_UCTU) AS POCET_UCTU
    FROM KLIENT K JOIN UCET U ON U.VLASTNIK = K.ID
    GROUP BY K.ID, K.JMENO, K.PRIJMENI;
    
-- Na kter�m ze sv�ch ��t� m� klient nejm�n� prost�edk� a jak� je to ��skta? 
SELECT U.CISLO_UCTU,K.JMENO, K.PRIJMENI, MIN(U.ZUSTATEK) AS MINIMALNI_ZUSTATEK
    FROM KLIENT K JOIN UCET U ON U.VLASTNIK = K.ID
        GROUP BY K.JMENO, K.PRIJMENI, U.CISLO_UCTU;
        
-- Kte�� klienti si zalo�ili ��et v roce 2020?
SELECT K.JMENO, K.PRIJMENI 
    FROM Klient K 
        WHERE EXISTS(SELECT * FROM UCET U WHERE TO_CHAR(DATUM_ZALOZENI, 'YYYY')='2020' AND U.VLASTNIK = K.ID);
        
--Kte�� klienti disponuj� n�jak�m ��tem?
SELECT K.JMENO, K.PRIJMENI 
    FROM KLIENT K 
        WHERE K.ID IN (SELECT DISPONENT FROM DISPONOVANI);


DROP TRIGGER vloz_datum;


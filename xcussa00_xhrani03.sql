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

INSERT INTO UCET (CISLO_UCTU, DATUM_ZALOZENI, ZUSTATEK, VLASTNIK)
    VALUES (2816,TO_DATE('2023-03-25', 'yyyy/mm/dd'), 10, 1);

INSERT INTO UCET (CISLO_UCTU, DATUM_ZALOZENI, ZUSTATEK, VLASTNIK)
    VALUES (111331,TO_DATE('2023-03-24', 'yyyy/mm/dd'), 10000, 2);

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
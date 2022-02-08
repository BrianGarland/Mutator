/* Mutator: Configuration */

CREATE OR REPLACE TABLE MTCFG (
    Compile_Program
        FOR COLUMN COMPPGM
        CHAR(10) CCSID 37                   
    ,                                       
    Compile_Library
        FOR COLUMN COMPLIB
        CHAR(10) CCSID 37                   
);

RENAME TABLE MTCFG TO Mutator_Configuration
    FOR SYSTEM NAME MTCFG;            

LABEL ON TABLE MTCFG
    IS 'Mutator: Configuration';                                     
                                                            
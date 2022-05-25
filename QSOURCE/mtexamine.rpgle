**FREE

//
// mtExamine -- Analyze an object
//
// (c)Copyright 2022 Brian J Garland
//


CTL-OPT BNDDIR('DATABIND');
  

DCL-PI MTEXAMINE;
    pLibrary CHAR(10);
    pObject CHAR(10);
    pType CHAR(10);
END-PI;


/INCLUDE mtexamine.rpgle_h


DCL-S Object        CHAR(10);
DCL-S Type          CHAR(10);


EXEC SQL DECLARE MTEXAMINE_C1 INSENSITIVE CURSOR FOR
         SELECT OBJNAME, OBJTYPE
         FROM TABLE(OBJECT_STATISTICS(:pLibrary,:pType,:pObject)) x
         ORDER BY (CASE WHEN OBJTYPE = '*FILE' THEN 1 ELSE 2 END), OBJTYPE, OBJNAME
         FOR READ ONLY;
EXEC SQL OPEN MTEXAMINE_C1;

DOW SQLSTATE < '02000';
    EXEC SQL FETCH NEXT FROM MTEXAMINE_C1 INTO :Object, :Type;
    IF SQLSTATE >= '02000';
        LEAVE;
    ENDIF;

    SELECT; 
        WHEN Type = '*FILE'; 
            DoFile(Object:pLibrary); 
        WHEN Type = '*PGM' OR Type = '*MODULE' OR Type = '*SRVPGM';
            DoProgram(Object:Type:pLibrary);
        OTHER;
            // Ignore any other types    
    ENDSL;

ENDDO;
EXEC SQL CLOSE MTEXAMINE_C1;


*INLR = *ON;
RETURN;



**FREE

CTL-OPT NOMAIN;

/INCLUDE mtexamine.rpgle_h

//
// DoFile - Process a file
//
 
DCL-PROC DoFile EXPORT;
DCL-PI *N INT(20);
    File    CHAR(10);
    Library CHAR(10);
END-PI;

    DCL-S IdentityValue INT(20);


    // Drop old file info
    EXEC SQL DELETE FROM Mutator_File_Fields
             WHERE File IN (SELECT mtfIdentity FROM Mutator_Files
                            WHERE SHORT_TABLE = :File
                              AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_File_Cross_Reference
             WHERE Parent_File IN (SELECT mtfIdentity FROM Mutator_Files
                                   WHERE SHORT_TABLE = :File
                                     AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_File_Cross_Reference
             WHERE Child_File IN (SELECT mtfIdentity FROM Mutator_Files
                                  WHERE SHORT_TABLE = :File
                                    AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_Program_File_Cross_Reference
             WHERE File in (SELECT mtfIdentity FROM Mutator_Files
                            WHERE SHORT_TABLE = :File
                              AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_Files
             WHERE SHORT_TABLE = :File
               AND SHORT_SCHEMA = :Library;

    // File details
    EXEC SQL INSERT INTO Mutator_Files
             OVERRIDING USER VALUE
             SELECT ObjLongSchema, ObjLib, ObjLongName, ObjName, ObjAttribute,
                    Sql_Object_Type, Source_File, Source_Library, Source_Member, 0
             FROM TABLE(Object_Statistics(:Library,'*FILE',:File)) X;
    // Save identity for procedure return value
    EXEC SQL SELECT Identity_Val_Local()
             INTO :IdentityValue FROM SYSIBM/SYSDUMMY1;

    // Related files
    EXEC SQL INSERT INTO Mutator_File_Cross_Reference
             OVERRIDING USER VALUE
             SELECT f1.mtfidentity, f2.mtfidentity, 0
             FROM QSYS/QADBFDEP
             JOIN Mutator_Files f1 ON (dbflib,dbffil) = (f1.short_schema,f1.short_table)
             JOIN Mutator_Files f2 ON (dbfldp,dbffdp) = (f2.short_schema,f2.short_table)
             WHERE (dbffil = :File AND dbflib = :Library)
                OR (dbffdp = :File AND dbfldp = :Library);

    // Fields in the file
    EXEC SQL INSERT INTO Mutator_File_Fields
             OVERRIDING USER VALUE
             SELECT mtfIdentity, Name, sys_CName, ColType, Length, Scale, label, labeltext, 0
             FROM QSYS2/SYSCOLUMNS
             JOIN Mutator_Files ON (sys_DName,sys_TName) = (Short_Schema,Short_Table)
             WHERE SYS_TName = :File AND SYS_DName = :Library;

    RETURN IdentityValue;

END-PROC;


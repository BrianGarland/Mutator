**FREE 

CTL-OPT NOMAIN; 

/INCLUDE mtexamine.rpgle_h

DCL-DS PSDS PSDS;
    ProgramLibrary CHAR(10) POS(81);
END-DS;


//
// DoProgram - Process a program, module, or service program
//

DCL-PROC DoProgram EXPORT;
    DCL-PI *N INT(20);
        Program CHAR(10);
        Type    CHAR(10);
        Library CHAR(10);
    END-PI;

    DCL-S IdentityValue INT(20);


    // Drop old file info
    EXEC SQL DELETE FROM Mutator_Program_File_Cross_Reference
             WHERE Program IN (SELECT mtpIdentity FROM Mutator_Programs
                               WHERE SHORT_PROGRAM = :Program
                                 AND PROGRAM_TYPE = :Type
                                 AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_Program_Fields
             WHERE Program IN (SELECT mtpIdentity FROM Mutator_Programs
                               WHERE SHORT_PROGRAM = :Program
                                 AND PROGRAM_TYPE = :Type
                                 AND SHORT_SCHEMA = :Library);

    EXEC SQL DELETE FROM Mutator_Programs
             WHERE SHORT_PROGRAM = :Program
               AND PROGRAM_TYPE = :Type
               AND SHORT_SCHEMA = :Library;

    // Program details
    EXEC SQL INSERT INTO Mutator_Programs
             OVERRIDING USER VALUE
             SELECT ObjLongSchema, ObjLib, ObjLongName, ObjName, ObjType, ObjAttribute,
                    Source_File, Source_Library, Source_Member, 0
             FROM TABLE(Object_Statistics(:Library,:Type,:Program)) X;
    // Save identity for procedure return value
    EXEC SQL SELECT Identity_Val_Local()
             INTO :IdentityValue FROM SYSIBM/SYSDUMMY1;

    DoProgramFiles(Program:Type:Library:IdentityValue);

    IF Type <> '*SRVPGM';
        DoProgramFields(Program:Type:Library:IdentityValue);
    ENDIF;

    RETURN IdentityValue;

END-PROC;


//
// DoProgramFiles - Get the files used by a program
//
 
DCL-PROC DoProgramFiles;
    DCL-PI *N;
        Program  CHAR(10);
        Type     CHAR(10);
        Library  CHAR(10);
        Identity INT(20);
    END-PI;

    DCL-DS InputDS QUALIFIED;
        FileIdentity    INT(20);
        FileName        CHAR(10);
    END-DS;

    DCL-DS InputNI QUALIFIED;
        NullInds INT(5) DIM(2);
    END-DS;

    DCL-DS Mutator_Program_File_Cross_ReferenceDS EXTNAME('MTPGMFIL') ALIAS QUALIFIED INZ;
    END-DS;

    system('DSPPGMREF PGM(' + %TRIM(Library) + '/' + %TRIM(Program) + ') '
          + 'OUTPUT(*OUTFILE) OBJTYPE(' + %TRIM(Type) + ') '
          + 'OUTFILE(QTEMP/MTPGMREF) OUTMBR(*FIRST *REPLACE)');

    EXEC SQL DECLARE MTEXAMINE_DoProgramFiles_C1 INSENSITIVE CURSOR FOR
             SELECT DISTINCT f.mtfidentity, whfnam
             FROM QTEMP/MTPGMREF 
             LEFT OUTER JOIN Mutator_Files f ON (whlib,whfnam) = (f.short_schema,f.short_table)
             WHERE whotyp = '*FILE'
             FOR READ ONLY;
    EXEC SQL OPEN MTEXAMINE_DoProgramFiles_C1;

    DOW SQLSTATE < '02000';
        EXEC SQL FETCH NEXT FROM MTEXAMINE_DoProgramFiles_C1 INTO :InputDS :InputNI.NullInds;
        IF SQLSTATE >= '02000';
            LEAVE;
        ENDIF;

        Mutator_Program_File_Cross_ReferenceDS.Program = Identity;
        IF InputDS.FileIdentity = 0;
            Mutator_Program_File_Cross_ReferenceDS.File = DoFile(InputDS.FileName:Library);
        ELSE;
            Mutator_Program_File_Cross_ReferenceDS.File = InputDS.FileIdentity;
        ENDIF;

        EXEC SQL INSERT INTO Mutator_Program_File_Cross_Reference
                 OVERRIDING USER VALUE
                 VALUES(:Mutator_Program_File_Cross_ReferenceDS);

    ENDDO;
    EXEC SQL CLOSE MTEXAMINE_DoProgramFiles_C1;

    RETURN;

END-PROC;
 

// 
// DoProgramFields - Get the fields used by a program
//
 

// ****************** Compile listing cross reference layout *****************
//
//                          C r o s s   R e f e r e n c e
//      File and Record References:
//         File              Device             References (D=Defined)
//           Record
//  ** need an example of this info
//
//      Global Field References:
//         Field             Attributes         References (D=Defined M=Modified)
//  ** if the field name is short enough
//12222222 33333333333333333 4444444444             5555555     5555555     5555555     5555555
//  ** for long field names
//12222222 333333333333333333333333333333...
//                           4444444444             5555555     5555555     5555555     5555555
//  ** sub fields in a qualifed DS are indented two spaces
//  ** this can continue on for nested DSs
//
//      Field References for subprocedure XXXXXXXXXXXXXXXXXXX
//         Field             Attributes         References (D=Defined M=Modified)
//  ** same field level row layout as Global Field References
//
//      Indicator References:
//         Indicator                            References (D=Defined M=Modified)
//  ** need an example of this info
//
//       * * * * *   E N D   O F   C R O S S   R E F E R E N C E   * * * * *
//
// ****************** Compile listing cross reference layout *****************
 
DCL-PROC DoProgramFields;
    DCL-PI *N;
        Program  CHAR(10);
        Type     CHAR(10);
        Library  CHAR(10);
        Identity INT(20);
    END-PI;

    DCL-F MTCOMPILE DISK(132) EXTFILE('QTEMP/MTCOMPILE') USROPN;              

    DCL-PR Compile EXTPGM(CompilePgm);
        Program  CHAR(10);
        Type     CHAR(10);
        Library  CHAR(10);
        SrcLib   CHAR(10);
        SrcFile  CHAR(10);
        SrcMbr   CHAR(10);
    END-PR;

    DCL-DS InputDS LEN(132);
        iStar          CHAR(1)   POS(1);
        iMsgID         CHAR(7)   POS(2);
        iSectionHeader CHAR(28)  POS(7);
        iXrefEnd       CHAR(68)  POS(8);
        iDataStructure CHAR(17)  POS(9);
        iFieldShort    CHAR(17)  POS(10);
        iFieldLong     CHAR(123) POS(10);
        iAttribute3    CHAR(3)   POS(27);
        iXrefStart     CHAR(30)  POS(27);
        iAttribute10   CHAR(10)  POS(28);
        iProcName      CHAR(92)  POS(41);
        iDSName        CHAR(30)  POS(41);
        iReferences    CHAR(51)  POS(48);
    END-DS;

    DCL-DS OutputFieldDS EXTNAME('MTPGMFLD') ALIAS QUALIFIED INZ;
    END-DS;

    DCL-DS OutputDataStructureDS EXTNAME('MTPGMDS') ALIAS QUALIFIED INZ;
    END-DS;

    DCL-S CompilePgm    CHAR(21);
    DCL-S DataStructure CHAR(100) DIM(10) STATIC;
    DCL-S DoingXref     IND INZ(*OFF);
    DCL-S GlobalSection IND INZ(*OFF);
    DCL-S I             UNS(5);
    DCL-S Indent        UNS(5);
    DCL-S Pos           UNS(5);
    DCL-S isQualified   IND;
    DCL-S ReadCount     UNS(5) INZ(0);
    DCL-S SaveName      CHAR(100);
    DCL-S Section       UNS(5) INZ(0);
    DCL-S ShortOrLong   CHAR(1);
    DCL-S SrcFile       CHAR(10);
    DCL-S SrcLib        CHAR(10);
    DCL-S SrcMbr        CHAR(10);


    OutputFieldDS.Program = Identity;
    OutputDataStructureDS.Program = Identity;

    EXEC SQL SELECT Source_Library, Source_File, Source_Member
             INTO :SrcLib, :SrcFile, :SrcMbr
             FROM Mutator_Programs
             WHERE mtpIdentity = :Identity;

    EXEC SQL SELECT TRIM(Compile_Library)||'/'||TRIM(Compile_Program)
             INTO :CompilePgm 
             FROM Mutator_Configuration
             FETCH FIRST ROW ONLY;

    // If no exit program found then we cannot do the field cross reference
    IF SQLSTATE >= '02000' OR CompilePgm = *BLANKS;
        RETURN;
    ENDIF;

    // Do the compile and if it fails, exit
    CALLP(E) Compile(Program:Type:Library:SrcLib:SrcFile:SrcMbr);
    IF %ERROR;
        RETURN;
    ENDIF;

    // Put the Mutator library back in the library list just in case the compile program changed it
    system('ADDLIBLE LIB(' + %TRIM(ProgramLibrary) + ') POSITION(*FIRST)');

    system('CRTPF FILE(QTEMP/MTCOMPILE) RCDLEN(132) SIZE(*NOMAX)');
    system('CLRPFM QTEMP/MTCOMPILE');
    system('CPYSPLF FILE(' + Program + ') TOFILE(QTEMP/MTCOMPILE) SPLNBR(*LAST)');

    OPEN MTCOMPILE;                
    READ MTCOMPILE InputDS;        
    ReadCount += 1;                
                               
    DOW NOT %EOF;                  

        // Figure out if we are in the cross reference section of the spooled file

        IF iXrefStart = 'C r o s s   R e f e r e n c e';
            DoingXref = *ON;
        ENDIF;

        IF iXrefEnd = '* * * * *   E N D   O F   C R O S S   R E F E R E N C E   * * * * *';
            DoingXref = *OFF;
        ENDIF;

        // If we are in the cross reference section we need to do something with the data 

        IF DoingXref;

            // Figure out which part of the cross reference we are in 
            SELECT;
                WHEN iSectionHeader = 'File and Record References:';
                    Section = 1;
                WHEN iSectionHeader = 'Global Field References:';
                    Section = 2;
                WHEN iSectionHeader = 'Indicator References:';
                    Section = 3;
            ENDSL;

            // Process logic for each section 
            SELECT;
                WHEN Section = 1;
                    // Nothing to save here, using DSPPGMREF to get this info
                WHEN Section = 2;
                    EXSR SaveGlobal;
                WHEN Section = 3;
                    // No need to save indicators    
            ENDSL;

        ELSE;

            // Before the cross reference section we need to catch any externally 
            // described data structures
            EXSR ExternalDS;

        ENDIF;

        READ MTCOMPILE InputDS;        
        ReadCount += 1;                
    ENDDO;

    CLOSE MTCOMPILE;        

    RETURN;

    //-------------------------
    BEGSR SaveGlobal;
    //-------------------------

        IF iSectionHeader = 'Field References for sub';
            OutputFieldDS.Procedure = iProcName;
        ENDIF;

        IF iAttribute3 = ' A('
            or iAttribute3 = ' B('
            or iAttribute3 = ' F('
            or iAttribute3 = ' G('
            or iAttribute3 = ' I('
            or iAttribute3 = ' N('
            or iAttribute3 = ' P('
            or iAttribute3 = ' S('
            or iAttribute3 = ' D('
            or iAttribute3 = ' T('
            or iAttribute3 = ' U('
            or iAttribute3 = ' Z('
            or iAttribute3 = ' *('
            or iAttribute3 = ' DS'
            or iAttribute3 = ' CO';

            SaveName = *BLANKS;
            IF iFieldShort <> *BLANKS;
                ShortOrLong = 'S';
                EXSR GetFieldAttrs;
            ELSE;
                READP MTCOMPILE InputDS;
                DOW NOT %EOF;
                    Pos = %SCAN('...':iFieldLong);
                    IF Pos > 0;
                        ShortOrLong = 'L';
                        EXSR GetFieldAttrs;
                        LEAVE;
                    ENDIF;
                    READP MTCOMPILE InputDS;
                ENDDO;
                CHAIN readcount MTCOMPILE InputDS;
            ENDIF;

            IF SaveName <> *BLANKS;
                IF isQualified;
                    OutputFieldDS.Field = %TRIMR(DataStructure(Indent)) + '.' + SaveName;
                ELSE;
                    OutputFieldDS.Field = SaveName;
                ENDIF;

                IF iAttribute3 = ' DS';
                    DataStructure(Indent+1) = SaveName;
                ELSEIF NOT(isQualified);
                    DataStructure(Indent+1) = *BLANK;
                ENDIF;

                IF iMsgID <> 'RNF7031';

                    OutputFieldDS.Attribute = iAttribute10;

                    FOR i = 1 TO 4;
                        OutputFieldDS.Reference = %SUBST(iReferences:(i-1)*12+1:12);
                        IF OutputFieldDS.Reference <> *BLANKS;
                            EXEC SQL INSERT INTO Mutator_Program_Fields
                                     OVERRIDING USER VALUE
                                     VALUES(:OutputFieldDS);
                        ENDIF;
                    ENDFOR;

                ENDIF;

            ENDIF;

        ENDIF;

    ENDSR;

    //-------------------------
    BEGSR GetFieldAttrs;
    //-------------------------

        Indent = 0;
        FOR i = 1 TO 20;
            IF %SUBST(iFieldShort:i:1) <> ' ';
                Indent = (i-1)/2;
                LEAVE;
            ENDIF;
        ENDFOR;

        isQualified = (Indent <> 0);

        IF isQualified;
        ENDIF;

        IF ShortOrLong = 'S';
            SaveName = %TRIM(iFieldShort);
        ELSE;
            SaveName = %TRIM(%SCANRPL('...':'   ':iFieldLong));
        ENDIF;

    ENDSR;

    //-------------------------
    BEGSR ExternalDS;
    //-------------------------

        IF iDataStructure = '* Data structure';
            OutputDataStructureDS.DataStructure = iDSName;
        ENDIF;

        IF iDataStructure = '* External format';
            OutputDataStructureDS.File = iDSName;
            Pos = %SCAN(':':OutputDataStructureDS.File);
            IF Pos <> 0;
                OutputDataStructureDS.File = %SUBST(OutputDataStructureDS.File:1:Pos-1);
            ENDIF;     
            EXEC SQL INSERT INTO Mutator_Program_DataStructures
                        OVERRIDING USER VALUE
                        VALUES(:OutputDataStructureDS);
        ENDIF;

    ENDSR;

END-PROC;
//****//
 

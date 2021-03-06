/* Mutator: File/File Cross Reference */

CREATE OR REPLACE TABLE MTFILFIL (                                          
    Parent_File                                      
        FOR COLUMN PARENT            
        BIGINT NOT NULL                                          
        CONSTRAINT MTFILFIL_C1 REFERENCES MTFIL(mtfIdentity)      
        ON DELETE RESTRICT ON UPDATE RESTRICT                    
    ,                                                            
    Child_File   
        FOR COLUMN CHILD                                                
        BIGINT NOT NULL                                          
        CONSTRAINT MTFILFIL_C2 REFERENCES MTFIL(mtfIdentity)      
        ON DELETE RESTRICT ON UPDATE RESTRICT                    
    ,                                                            
    mtffIdentity                                 
        FOR COLUMN IDENTITY                    
        BIGINT GENERATED BY DEFAULT AS IDENTITY                  
        CONSTRAINT PK_MTFILFIL PRIMARY KEY                       
    );                                                           
        
RENAME TABLE MTFILFIL TO Mutator_File_Cross_Reference
    FOR SYSTEM NAME MTFILFIL;            

LABEL ON TABLE MTFILFIL                 
    IS 'Mutator: File/File Cross Reference';              
                                        
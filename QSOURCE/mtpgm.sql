/* Mutator: Programs */

CREATE OR REPLACE TABLE MTPGM (                    
    Long_Schema                            
        VARCHAR(128) CCSID 37              
    ,                                      
    Short_Schema                           
        CHAR(10) CCSID 37                  
    ,                                      
    Long_Program                           
        VARCHAR(128) CCSID 37              
    ,                                      
    Short_Program                          
        CHAR(10) CCSID 37                  
    ,                                      
    Program_Type                           
        VARCHAR(10) CCSID 37               
    ,                                      
    Program_Attribute                      
        VARCHAR(10) CCSID 37               
    ,                                      
    Source_File                                  
        VARCHAR(10) CCSID 37                     
    ,                                            
    Source_Library                               
        VARCHAR(10) CCSID 37                     
    ,                                            
    Source_Member                                
        VARCHAR(10) CCSID 37                     
    ,                                            
    mtpIdentity                                     
        BIGINT GENERATED BY DEFAULT AS IDENTITY  
        CONSTRAINT PK_MTPGM PRIMARY KEY         
    );                                           
                                                 
LABEL ON TABLE MTPGM
    IS 'Mutator: Programs';                        
                                                                                            
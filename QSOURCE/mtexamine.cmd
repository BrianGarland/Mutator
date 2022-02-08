/* mtExamine -- Analyze an object */

      CMD        PROMPT('Analyze an object')                        
      PARM       KWD(LIB) TYPE(*NAME) LEN(10) MIN(1) +              
                   PROMPT('Object library')                         
      PARM       KWD(OBJ) TYPE(*NAME) LEN(10) MIN(1) +              
                   SPCVAL((*ALL *ALL)) PROMPT('Object name')                                 
      PARM       KWD(TYPE) TYPE(*CHAR) LEN(10) MIN(1) +             
                   RSTD(*YES) VALUES(*ALL *ALRTBL *AUTL *BNDDIR +        
                   *CHGFMT *CLD *CLS *CMD *CRQD *CSI *CSPMAP +      
                   *CSPRBL *DTAARA *FCT *FILE *FNTRSC +             
                   *FNTTBL *FORMDF *FTR *GSS *JOBD *JOBQ +          
                   *LOCALE *MEDDFN *MENU *MGTCOL *MODULE +          
                   *MSGF *MSGQ *M36CFG *NODGRP *NODL *OUTQ +        
                   *OVL *PAGDFN *PAGSEG *PDG *PGM *PNLGRP +         
                   *PRDAVL *PRDDFN *PRDLOD *PSFCFG *QMFORM +        
                   *QMQRY *QRYDFN *SBSD *SCHIDX *SRVPGM +           
                   *SSND *TBL *USRIDX *USRSPC *VLDL *WSCST) +       
                   PROMPT('Object type')                            

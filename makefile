NAME=Mutator: Field Expansion 
BIN_LIB=MUTATOR
DBGVIEW=*SOURCE
SRC_FLR=QSOURCE
TGTRLS=V7R3M0
SHELL=/QOpenSys/usr/bin/qsh

#----------

all: $(BIN_LIB).lib mtcfg.sql mtfilfil.sql mtfilfld.sql mtpgmfil.sql mtpgmfld.sql mtpgmds.sql mtexamine.pgm mtexamine.cmd
	@echo "Built all"

mtfilfil.sql: mtfil.sql

mtfilfld.sql: mtfil.sql

mtpgmfil.sql: mtfil.sql mtpgm.sql 

mtpgmfld.sql: mtpgm.sql

mtpgmds.sql: mtpgm.sql

mtexamine.pgm: mtexamine.rpgle mtdofile.rpgle mtdopgm.rpgle

#----------

%.lib:
	-system -qi "CRTLIB LIB($(BIN_LIB)) TEXT('$(NAME)')"
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) MBR(*NONE) RCDLEN(132)"
	@touch $@

%.sql:
	liblist -a $(BIN_LIB);\
	system "RUNSQLSTM  SRCSTMF('$(SRC_FLR)/$*.sql') COMMIT(*NONE) NAMING(*SYS) DFTRDBCOL($(BIN_LIB)) TGTRLS($(TGTRLS))"
	@touch $@

%.cmd:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSOURCE) MBR(*NONE) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('$(SRC_FLR)/$*.cmd') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTCMD CMD($(BIN_LIB)/$*) PGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QSOURCE) SRCMBR($*) TEXT('$(NAME)') REPLACE(*YES)"
	@touch $@

%.rpgle:
	liblist -a $(BIN_LIB);\
	system "CRTSQLRPGI OBJ($(BIN_LIB)/$*) SRCSTMF('$(SRC_FLR)/$*.rpgle') INCDIR('$(SRC_FLR)') COMMIT(*NONE) RDB(*LOCAL) OBJTYPE(*MODULE) TEXT('$(NAME)') TGTRLS($(TGTRLS)) CLOSQLCSR(*ENDMOD) DLYPRP(*YES) GENLVL(11) REPLACE(*YES) DBGVIEW($(DBGVIEW)) COMPILEOPT('OPTION(*NODEBUGIO) INCDIR($(SRC_FLR))')"
	@touch $@

%.pgm:
	liblist -a $(BIN_LIB);\
	system "CRTPGM PGM($(BIN_LIB)/$*) ENTMOD($(BIN_LIB)/$*) MODULE(($(BIN_LIB)/*ALL)) TEXT('$(NAME)') REPLACE(*YES) TGTRLS($(TGTRLS))"
	@touch $@

%.rpgle_h:
	# No create command for headers
	@touch $(@F)

#----------

# clean up makefiule objects and library objects - use before commit or after successful "all"
commit:
	-system -qi "DLTF FILE($(BIN_LIB)/QSOURCE)"
	-system -qi "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"
	rm -f *.lib *.rpgle_h *.sql *.dspf *.rpgle *.pgm *.cmd

# drop all objects for a full rebuild
clean:
	system "CLRLIB $(BIN_LIB)"
	rm -f *.lib *.rpgle_h *.sql *.dspf *.rpgle *.pgm *.cmd

# erase all built objects
erase:
	-system -qi "DLTLIB LIB($(BIN_LIB))"	
	rm -f *.lib *.rpgle_h *.sql *.dspf *.rpgle *.pgm *.cmd

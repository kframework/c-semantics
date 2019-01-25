# CIL_BASE = ../cil
# CIL_PLATFORM ?= $(firstword $(shell ls $(CIL_BASE)/obj))
# no warnings
OCAMLOPT_FLAGS = -w a -warn-error a 
# all warnings
#OCAMLOPT_FLAGS = -w A -warn-error A

# CIL = $(CIL_BASE)/obj/$(CIL_PLATFORM)

OCAML_COMPILE = ocamlfind ocamlopt -package camomile $(OCAMLOPT_FLAGS) -c

OCAML_LEX = ocamllex
OCAML_YACC = ocamlyacc
OCAML_LINK = ocamlfind ocamlopt -package camomile -linkpkg $(OCAMLOPT_FLAGS)

# these are partially ordered by inclusion.  don't know how to avoid manually ordering these
MODULES = errormsg.cmx longarray.cmx growArray.cmx escape.cmx cabshelper.cmx whitetrack.cmx cprint.cmx lexerhack.cmx cabs.cmx clexer.cmx cparser.cmx frontc.cmx xmlPrinter.cmx cabsDriver.cmx

#IOXML = ioxml/ioXML.cmx ioxml/pa_ioXML.cmo
.PHONY: all cleanOnMakefileChange clean 
#ioxml
all: cparser$(EXEEXT)

# $(IOXML): ioxml/ioXML.ml ioxml/ioXML.mli ioxml/pa_ioXML.ml
# make -C ioxml all

# xmlPrinter.ml: cabs.ml $(IOXML)
# camlp5o ioxml/pa_ioXML.cmo pr_o.cmo -sep "\n\n" cabs.ml > xmlPrinter.tmp
# sed -i '2 i open Cabs' xmlPrinter.tmp
# mv xmlPrinter.tmp xmlPrinter.ml

clexer.ml: clexer.mll
	@$(OCAML_LEX) clexer.mll

cparser.ml cparser.mli: cparser.mly cabs.cmx cabshelper.cmx
	@$(OCAML_YACC) cparser.mly

lexerhack.cmx lexerhack.cmi: errormsg.cmx
whitetrack.cmx whitetrack.cmi: cabs.cmx cabshelper.cmx
escape.cmx escape.cmi: whitetrack.cmx
cprint.cmx cprint.cmi: escape.cmx cabs.cmx
longarray.cmx longarray.cmi: errormsg.cmx
growArray.cmx growArray.cmi: errormsg.cmx longarray.cmx
cabshelper.cmx cabshelper.cmi: errormsg.cmx growArray.cmx cabs.cmx
cparser.cmx: cabs.cmx cabshelper.cmx lexerhack.cmx cprint.cmx cparser.cmi
cabsDriver.cmx cabsDriver.cmi: cparser.cmx frontc.cmx clexer.cmx xmlPrinter.cmx
frontc.cmx frontc.cmi: errormsg.cmx whitetrack.cmx cprint.cmx clexer.cmx
clexer.cmx clexer.cmi: lexerhack.cmx cparser.cmx cprint.cmx cabshelper.cmx
xmlPrinter.cmx xmlPrinter.cmi: cabs.cmx escape.cmx
%.cmx: %.ml 
	@$(OCAML_COMPILE) $*.ml
	
cparser.cmi: cparser.mli cabs.cmx clexer.ml
	@$(OCAML_COMPILE) cparser.mli
	
cabsDriver.cmx cabsDriver.cmi: xmlPrinter.cmx

EXEEXT=

cparser$(EXEEXT): $(MODULES)
	$(OCAML_LINK) -o $@ str.cmxa nums.cmxa $^
	@-strip cparser
#ioXML.cmx 

clean:
	rm -f *.cmi *.cmx *.o *.mli *.cil cparser.ml clexer.ml *.preprocessed cparser.exe cparser *.stackdump
#make -C ioxml clean

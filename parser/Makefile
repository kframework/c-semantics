.PHONY: default
default: cparser

# This makefile does not need to be re-built.
# See https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
Makefile: ;

# no warnings
OCAMLOPT_FLAGS := -w a -warn-error a 

OCAML_COMPILE := ocamlfind ocamlopt -package camomile $(OCAMLOPT_FLAGS) -c

OCAML_LEX := ocamllex
OCAML_YACC := ocamlyacc
OCAML_LINK := ocamlfind ocamlopt -package camomile -linkpkg $(OCAMLOPT_FLAGS)

clexer.ml: clexer.mll
	@$(OCAML_LEX) clexer.mll

cparser.ml cparser.mli: cparser.mly cabs.cmx cabshelper.cmx
	@$(OCAML_YACC) cparser.mly

lexerhack.cmx lexerhack.cmi: errormsg.cmx
whitetrack.cmx whitetrack.cmi: cabs.cmx cabshelper.cmx
escape.cmx escape.cmi: whitetrack.cmx
longarray.cmx longarray.cmi: errormsg.cmx
growArray.cmx growArray.cmi: errormsg.cmx longarray.cmx
cabshelper.cmx cabshelper.cmi: errormsg.cmx growArray.cmx cabs.cmx
cparser.cmx: cabs.cmx cabshelper.cmx lexerhack.cmx cparser.cmi
cabsDriver.cmx cabsDriver.cmi: cparser.cmx frontc.cmx clexer.cmx kPrinter.cmx
frontc.cmx frontc.cmi: errormsg.cmx whitetrack.cmx clexer.cmx
clexer.cmx clexer.cmi: lexerhack.cmx cparser.cmx cabshelper.cmx
kPrinter.cmx kPrinter.cmi: cabs.cmx escape.cmx

%.cmx: %.ml 
	@$(OCAML_COMPILE) $*.ml
	
cparser.cmi: cparser.mli cabs.cmx clexer.ml
	@$(OCAML_COMPILE) cparser.mli
	
cabsDriver.cmx cabsDriver.cmi: kPrinter.cmx

# these are partially ordered by inclusion.  don't know how to avoid manually ordering these
cparser: errormsg.cmx \
         longarray.cmx \
         growArray.cmx \
         escape.cmx \
         cabshelper.cmx \
         whitetrack.cmx \
         lexerhack.cmx \
         cabs.cmx \
         clexer.cmx \
         cparser.cmx \
         frontc.cmx \
         kPrinter.cmx \
         cabsDriver.cmx
	$(OCAML_LINK) -o $@ str.cmxa $^
	@-strip cparser

.PHONY: clean
clean:
	-rm -f *.cmi *.cmx *.o *.mli *.cil cparser.ml clexer.ml *.preprocessed cparser *.stackdump

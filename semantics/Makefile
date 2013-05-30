SCRIPTS_DIR = ../scripts
INSERT_LINE = $(SCRIPTS_DIR)/insert.sh
APPEND_LINE = $(SCRIPTS_DIR)/append.sh
FIRST_LINE_SCRIPT = $(SCRIPTS_DIR)/getFirstLine.pl

K_MAUDE = $(K_BASE)/bin/kompile
K_PRELUDE = $(K_BASE)/bin/maude/lib/k-prelude
K_SOCKETS = $(K_BASE)/bin/maude/lib/socket
K_TCP = $(K_BASE)/bin/maude/lib/TCPSupport
# chathhorn
#K_PL_BUILTINS = $(K_BASE)/maude/lib/pl-builtins
K_PL_BUILTINS = $(K_BASE)/bin/maude/lib/builtins
K_PL_MODEL_CHECKER = $(K_BASE)/bin/maude/lib/k-model-checker
K_PL_META_LEVEL = $(K_BASE)/bin/maude/lib/pl-meta-level
K_LATEX_STYLE = $(K_BASE)/include/latex/k.sty


K_BASE_FILES = $(K_PRELUDE).maude $(K_SOCKETS).maude $(K_PL_BUILTINS).maude $(K_PL_MODEL_CHECKER).maude $(K_PL_META_LEVEL).maude
K_FILES = $(K_BASE_FILES) $(K_MAUDE)

#COMPILE_C = perl -d:DProf $(K_MAUDE) c.k -u -language C

#chathhorn
#COMPILE_C = $(K_MAUDE) c.k -u -language C -anywhere "anywhere" -transition "interpRule"
COMPILE_C = $(K_MAUDE) -v c.k -l C -transition "interpRule"

#chathhorn
#COMPILE_C_ND = $(K_MAUDE) c.k -u -language C -anywhere "anywhere" -transition "observable computational" -superheat "ndheat" -supercool "ndlocal"
COMPILE_C_ND = $(K_MAUDE) c.k -l C -transition "observable computational" -superheat "ndheat" -supercool "ndlocal"
#chathhorn
#COMPILE_C_ND_THREAD = $(K_MAUDE) c.k -u -language C -anywhere "anywhere" -transition "observable computational"
COMPILE_C_ND_THREAD = $(K_MAUDE) c.k -l C -transition "observable computational"
#-lib maudeLib/common-c-builtins.maude

COMMON_C_FILES = c-syntax.k \
common-c-syntax.k common-c-helpers.k common-c-configuration.k common-c-expressions.k common-c-semantics.k common-c-statements.k common-c-declarations.k common-c-typing.k
DYNAMIC_C_FILES = c.k dynamic-c-semantics.k dynamic-c-configuration.k dynamic-c-expressions.k dynamic-c-errors.k dynamic-c-statements.k dynamic-c-conversions.k dynamic-c-typing.k dynamic-c-declarations.k dynamic-c-memory.k dynamic-c-standard-lib.k

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out *.tex *.log *.aux
K_CLEAN_FILES = *.maude .k kcompile_* \
c-compiled.maude.tmp.bak c-compiled.maude.0 c-compiled.maude.1 c-compiled.maude.1.bak c-compiled-nd.maude.0 c-compiled-nd.maude.1 c-compiled-nd.maude.1.bak c-compiled-nd.maude.bak static-c.k.bak c-compiled.maude \
duplicateLabels.txt 

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

check-vars:
ifeq ($(K_BASE),)
	@echo "ERROR: Please set K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export K_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif

temp-c-syntax.tex: PDF_FILES = common-c-syntax
temp-c-statements.tex: PDF_FILES = common-c-statements dynamic-c-statements
temp-c-expressions.tex: PDF_FILES = common-c-expressions dynamic-c-expressions
temp-c-typing.tex: PDF_FILES = common-c-typing dynamic-c-typing
temp-c-declarations.tex: PDF_FILES = common-c-declarations dynamic-c-declarations
temp-c-memory.tex: PDF_FILES = dynamic-c-memory
temp-c-library.tex: PDF_FILES = dynamic-c-standard-lib
temp-c-errors.tex: PDF_FILES = dynamic-c-errors
temp-c-misc.tex: PDF_FILES = common-c-semantics common-c-helpers dynamic-c-semantics
temp-c-%.tex: PDF_MODULES = `grep -o '^module.* is' $(addsuffix .k,$(PDF_FILES)) | grep -o ' .* '`
temp-c-%.tex: check-vars $(K_MAUDE) c.k $(addsuffix .k,$(PDF_FILES))
	@echo "Creating latex..."
	$(K_MAUDE) c.k -l C -package-options "style=bubble,magicTight" -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out

%.tex: PDF_FILES ?= $*
%.tex: temp-c-%.tex Makefile
	@echo "Modifying latex..."
	@cp $< $@.temp
	@perl -i -pe 's|\\documentclass{article}|\\documentclass[landscape]{article}|' $@.temp
# get rid of page breaks
	@perl -i -pe 's|\\newpage||' $@.temp
	@perl -i -pe 's|}mybracket|}\\mybracket|' $@.temp
	@perl -i -pe 's|\\mathrel{}||g' $@.temp
# include my custom style file
	@perl -i -pe 's|\\begin{document}|\\input{semantics.sty}\n\\begin{document}|' $@.temp
# get rid of the name attributes so they don't show up twice
	@perl -i -pe 's/(\\(?:kdefine|krule){([a-zA-Z0-9-]+)}.*)\\kattribute{\2}[ ]?/\1\3/' $@.temp
# get rid of structural annotations
	@perl -i -pe 's/\\kattribute{structural}[ ]?//' $@.temp
# get rid of klabel annotations
	@perl -i -pe 's/\\kattribute{klabel\([a-zA-Z0-9-]+\)}[ ]?//' $@.temp
# fix double quotes
	@perl -i -pe "s/ ' '/''/g" $@.temp	
	@perl -i -pe "s/{([^}]+)}_{([^}]+)}' '/{\1''}_{\2}/g" $@.temp	
# remove extraneous spaces at end of attributes
	@perl -i -pe 's/(\\kattribute{[a-zA-Z-()]+})[ ]?}/\1}/' $@.temp
	@mv $@.temp $@

%.pdf: %.tex $(K_LATEX_STYLE) semantics.sty
	@echo "Compiling latex..."
	@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
#@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
	@mv temp-c-$*.pdf $@
	@echo "Done."

configuration.pdf: custom-configuration.tex.orig
	cp custom-configuration.tex.orig custom-configuration.tex
	pdflatex custom-configuration.tex

pdf: syntax.pdf configuration.pdf statements.pdf expressions.pdf typing.pdf declarations.pdf memory.pdf library.pdf errors.pdf misc.pdf


c-compiled.maude.0: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition..."
	@$(COMPILE_C)
	@mv c-compiled.maude c-compiled.maude.0

c-compiled.maude.tmp: FIRST_LINE=`perl $(FIRST_LINE_SCRIPT) c-compiled.maude.0`
c-compiled.maude.tmp: c-compiled.maude.0 maudeLib/modelcheck.maude Makefile
	@cp c-compiled.maude.0 c-compiled.maude.1
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled.maude.1 "load maudeLib/common-c-builtins"
	@$(APPEND_LINE) c-compiled.maude.1 "load maudeLib/modelcheck"
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled.maude.1 "load $(K_PL_META_LEVEL)"
	@cp c-compiled.maude.1 c-compiled.maude.tmp
	@echo "Done".

c-compiled.maude: c-compiled.maude.tmp
# does not get all labels, but will hopefully find duplicates :(
	@sed -n 's/^ \(eq\|ceq\|rl\|crl\) .* label \([^ ][^ ]*\) .*\(superheated\).*$$/\2:\3/p' c-compiled.maude.tmp | sort | uniq -d > duplicateLabels.txt
	@if [ -s duplicateLabels.txt ]; then echo "Error: there are duplicate labels in the semantics.  This could cause profiling to give inaccurate results."; cat duplicateLabels.txt; exit 1; fi
	@mv c-compiled.maude.tmp c-compiled.maude

c-total.maude: check-vars c-compiled.maude $(K_BASE_FILES) $(K_TCP).maude Makefile
	@echo "c-compiled.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@

c-compiled-nd.maude.0: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with nondeterminism..."
	@$(COMPILE_C_ND)
	@mv c-compiled.maude c-compiled-nd.maude.0
	
c-compiled-nd.maude: FIRST_LINE=`perl $(FIRST_LINE_SCRIPT) c-compiled-nd.maude.0`
c-compiled-nd.maude: check-vars c-compiled-nd.maude.0 $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE) Makefile
	@cp c-compiled-nd.maude.0 c-compiled-nd.maude.1
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd.maude.1 "load maudeLib/common-c-builtins"
	@$(APPEND_LINE) c-compiled-nd.maude.1 "load maudeLib/modelcheck"
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd.maude.1 "load $(K_PL_META_LEVEL)"
	@cp c-compiled-nd.maude.1 c-compiled-nd.maude
	@echo "Done".
	
c-total-nd.maude: check-vars c-compiled-nd.maude $(K_BASE_FILES) $(K_TCP).maude Makefile
	@echo "c-compiled-nd.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@

	
c-compiled-nd-thread.maude.0: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with thread-nondeterminism..."
	@$(COMPILE_C_ND_THREAD)
	@mv c-compiled.maude c-compiled-nd-thread.maude.0
	
c-compiled-nd-thread.maude: FIRST_LINE=`perl $(FIRST_LINE_SCRIPT) c-compiled-nd-thread.maude.0`
c-compiled-nd-thread.maude: check-vars c-compiled-nd-thread.maude.0 $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE) Makefile
	@cp c-compiled-nd-thread.maude.0 c-compiled-nd-thread.maude.1
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd-thread.maude.1 "load maudeLib/common-c-builtins"
	@$(APPEND_LINE) c-compiled-nd-thread.maude.1 "load maudeLib/modelcheck"
	@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd-thread.maude.1 "load $(K_PL_META_LEVEL)"
	@cp c-compiled-nd-thread.maude.1 c-compiled-nd-thread.maude
	@echo "Done".
	
c-total-nd-thread.maude: check-vars c-compiled-nd-thread.maude $(K_BASE_FILES) $(K_TCP).maude Makefile
	@echo "c-compiled-nd-thread.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@
	


semantics: c-total.maude c-total-nd.maude c-total-nd-thread.maude

fast: c-total.maude
	@cp c-total.maude c-total-nd.maude
	@cp c-total.maude c-total-nd-thread.maude

nd: c-total-nd.maude
	@cp c-total-nd.maude c-total.maude
	@cp c-total-nd.maude c-total-nd-thread.maude

thread: c-total-nd-thread.maude
	@cp c-total-nd-thread.maude c-total.maude
	@cp c-total-nd-thread.maude c-total-nd.maude

clean:
	rm -rf $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp

force: ;

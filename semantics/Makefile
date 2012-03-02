SCRIPTS_DIR = ../scripts
INSERT_LINE = $(SCRIPTS_DIR)/insert.sh
APPEND_LINE = $(SCRIPTS_DIR)/append.sh
FIRST_LINE_SCRIPT = $(SCRIPTS_DIR)/getFirstLine.pl

K_MAUDE = $(K_BASE)/core/kompile
K_PRELUDE = $(K_BASE)/core/maude/lib/k-prelude
K_SOCKETS = $(K_BASE)/core/maude/lib/socket
K_TCP = $(K_BASE)/core/maude/lib/TCPSupport
K-PL-BUILTINS = $(K_BASE)/core/maude/lib/pl-builtins
K_PL_MODEL_CHECKER = $(K_BASE)/core/maude/lib/k-model-checker
K_PL_META_LEVEL = $(K_BASE)/core/maude/lib/pl-meta-level


K_BASE_FILES = $(K_PRELUDE).maude $(K_SOCKETS).maude $(K_TCP).maude $(K-PL-BUILTINS).maude $(K_PL_MODEL_CHECKER).maude $(K_PL_META_LEVEL).maude
K_FILES = $(K_BASE_FILES) $(K_MAUDE)

#COMPILE_C = perl -d:DProf $(K_MAUDE) c.k -u -language C
COMPILE_C = $(K_MAUDE) c.k -u -language C -anywhere "anywhere" -transition "interpRule"
# -lib maudeLib/common-c-builtins.maude
# -transition "computational"
COMPILE_C_ND = $(K_MAUDE) c.k -u -language C -anywhere "anywhere" -transition "computational" -superheat "ndheat" -supercool "ndlocal"
#-lib maudeLib/common-c-builtins.maude

COMMON_C_FILES = c-syntax.k \
common-c-syntax.k common-c-helpers.k common-c-configuration.k common-c-expressions.k common-c-semantics.k common-c-statements.k common-c-declarations.k common-c-typing.k
DYNAMIC_C_FILES = c.k dynamic-c-semantics.k dynamic-c-configuration.k dynamic-c-expressions.k dynamic-c-errors.k dynamic-c-statements.k dynamic-c-conversions.k dynamic-c-typing.k dynamic-c-declarations.k dynamic-c-memory.k dynamic-c-standard-lib.k dynamic-c-ltl.k

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out *.tex *.log *.aux
K_CLEAN_FILES = *.maude .k kcompile_* \
c-compiled.maude.tmp.bak c-compiled.maude.0 c-compiled.maude.1 c-compiled.maude.1.bak c-compiled-nd.maude.0 c-compiled-nd.maude.1 c-compiled-nd.maude.1.bak c-compiled-nd.maude.bak static-c.k.bak \
duplicateLabels.txt 

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

pdf: common-pdf-modules
#c-expressions.pdf


check-vars:
ifeq ($(K_BASE),)
	@echo "ERROR: Please set K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export K_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif

# k-includes.k: check-vars Makefile
# @echo > k-includes.k
#@echo "load $(K_PRELUDE)" >> k-includes.k
#@echo "load $(K_SOCKETS)" >> k-includes.k

%.tex: PDF_MODULES=`grep -o '^kmod.* is' $*.k | grep -o ' .* '`
%.tex: check-vars $(K_MAUDE) c.k %.k Makefile
	@rm -f temp-c-$*.tex
	@echo "Creating latex..."
	$(K_MAUDE) c.k -l C -style mm -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out
	@sed -i 's|}mybracket|}\\mybracket|' temp-c-$*.tex
	@sed -i 's|\\begin{document}|\\input{semantics.sty}\n\\begin{document}|' temp-c-$*.tex
# @sed -i 's|\\begin{kdefinition}||' temp-c-$*.tex
# @sed -i 's|\\end{kdefinition}||' temp-c-$*.tex
	@mv temp-c-$*.tex $@

%.pdf: %.tex semantics.sty
	@echo "Compiling latex..."
	@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
	@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
	@mv temp-c-$*.pdf $@
	@echo "Done."

all.tex: PDF_FILES=\
common-c-syntax.k \
common-c-configuration.k \
dynamic-c-configuration.k \
common-c-helpers.k \
common-c-statements.k \
dynamic-c-statements.k \
common-c-expressions.k \
dynamic-c-expressions.k \
common-c-declarations.k \
dynamic-c-declarations.k \
common-c-typing.k \
dynamic-c-typing.k \
dynamic-c-conversions.k \
dynamic-c-memory.k \
dynamic-c-standard-lib.k \
common-c-semantics.k \
dynamic-c-semantics.k \
c.k
all.tex: PDF_MODULES=`grep -o '^kmod.* is' $(PDF_FILES) | grep -o ' .* '`
all.tex:
	@rm -f temp-c-$*.tex
	@echo "Creating latex..."
	$(K_MAUDE) c.k -l C -style mm -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out
#@sed -i 's|}mybracket|}\\mybracket|' temp-c-$*.tex
#@sed -i 's|\\begin{document}|\\input{semantics.sty}\n\\begin{document}|' temp-c-$*.tex
	@mv temp-c-$*.tex $@
	
	

	
common-pdf-modules: \
common-c-syntax.pdf \
common-c-configuration.pdf \
dynamic-c-configuration.pdf \
common-c-helpers.pdf \
common-c-statements.pdf \
dynamic-c-statements.pdf \
common-c-expressions.pdf \
dynamic-c-expressions.pdf \
common-c-declarations.pdf \
dynamic-c-declarations.pdf \
common-c-typing.pdf \
dynamic-c-typing.pdf \
dynamic-c-conversions.pdf \
dynamic-c-memory.pdf \
dynamic-c-standard-lib.pdf \
common-c-semantics.pdf \
dynamic-c-semantics.pdf \
c.pdf
# c-syntax.pdf
#


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
#@$(INSERT_LINE) 2 c-compiled.maude.1 "load $(K_PL_MODEL_CHECKER)"
#@$(INSERT_LINE) 2 c-compiled.maude.1 "load $(K_PL_META_LEVEL)"
#@$(INSERT_LINE) $(FIRST_LINE) c-compiled.maude.1 "load maudeLib/TCPSupport" 
	@cp c-compiled.maude.1 c-compiled.maude.tmp
	@echo "Done".

c-compiled.maude: c-compiled.maude.tmp
	@grep -o '^ \(eq\|ceq\|rl\|crl\) .* label [^ ][^ ]* ' c-compiled.maude.tmp | grep -o ' label [^ ][^ ]*' | grep -o '[^ ]*$$' | sort | uniq -d > duplicateLabels.txt
	@if [ -s duplicateLabels.txt ]; then echo "Error: there are duplicate labels in the semantics.  This could cause profiling to give inaccurate results."; cat duplicateLabels.txt; exit 1; fi
	@mv c-compiled.maude.tmp c-compiled.maude

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
#@$(APPEND_LINE) c-compiled-nd.maude.1 "load maudeLib/modelcheck"
#@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd.maude.1 "load $(K_PL_META_LEVEL)"
#@$(INSERT_LINE) 2 c-compiled-nd.maude "load $(K_PL_MODEL_CHECKER)"
#@$(INSERT_LINE) 3 c-compiled-nd.maude "load $(K_SOCKETS)"
#@$(INSERT_LINE) $(FIRST_LINE) c-compiled-nd.maude.1 "load maudeLib/TCPSupport"
	@cp c-compiled-nd.maude.1 c-compiled-nd.maude
	@echo "Done".

c-total.maude: check-vars c-compiled.maude $(K_BASE_FILES) Makefile
	@echo "c-compiled.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@

c-total-nd.maude: check-vars c-compiled-nd.maude $(K_BASE_FILES) Makefile
	@echo "c-compiled-nd.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@

semantics: c-total.maude c-total-nd.maude

fast-nd: c-total.maude
	@cp c-total.maude c-total-nd.maude

fast-normal: c-total-nd.maude
	@cp c-total-nd.maude c-total.maude

fast: c-total.maude fast-nd

nd: c-total-nd.maude fast-normal

clean:
	rm -rf $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp

force: ;

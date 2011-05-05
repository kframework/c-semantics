#K_MAUDE_BASE ?= ..
K_COMPILE_BASE = tools/kompile.pl
SCRIPTS_DIR = ../scripts
INSERT_LINE = $(SCRIPTS_DIR)/insert.sh

K_MAUDE = $(K_MAUDE_BASE)/$(K_COMPILE_BASE)
K_PRELUDE = $(K_MAUDE_BASE)/k-prelude
K_SOCKETS = $(K_MAUDE_BASE)/socket
K-PL-BUILTINS = $(K_MAUDE_BASE)/pl-builtins
K_PL_MODEL_CHECKER = $(K_MAUDE_BASE)/k-model-checker

K_BASE_FILES = $(K_PRELUDE).maude $(K_SOCKETS).maude $(K-PL-BUILTINS).maude $(K_PL_MODEL_CHECKER).maude

COMPILE_C = $(K_MAUDE) c.k -u -language C
COMPILE_C_ND = $(K_MAUDE) c.k -nd -u -language C
COMPILE_STATIC_C = $(K_MAUDE) static-c.k -u -language C



ALL_K_FILES = common-c-syntax.k common-c-sized-operations.k common-c-helpers.k common-c-errors.k common-c-configuration.k common-c-semantics.k common-c-standard-lib.k common-c-expressions.k common-c-memory.k common-c-statements.k common-c-conversions.k common-c-typing.k common-c-declarations.k \
dynamic-c-semantics.k dynamic-c-configuration.k maudeLib/TCPSupport.maude

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out *.tex *.log *.aux
K_CLEAN_FILES = *.maude kcompile_* c-compiled.maude.bak c-compiled.maude.tmp.bak c-compiled-nd.maude.bak duplicateLabels.txt k-includes.k

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

pdf: common-pdf-modules
#c-expressions.pdf

k-includes.k:
	@echo > k-includes.k
	@echo "load $(K_PRELUDE)" >> k-includes.k
	@echo "load $(K_SOCKETS)" >> k-includes.k

c.k: k-includes.k

%.tex: PDF_MODULES=`grep -o '^kmod.* is' $*.k | grep -o ' .* '`
%.tex: $(K_MAUDE) c.k k-includes.k %.k Makefile
	@rm -f temp-c-$*.tex
	@echo "Creating latex..."
	@$(K_MAUDE) c.k -l C -style mm -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out
	@sed -i 's|}mybracket|}\\mybracket|' temp-c-$*.tex
	@sed -i 's|\\begin{document}|\\input{semantics.sty}\n\\geometry{papersize={14in,8.5in},textwidth=13.75in,textheight=7.7in}\\begin{document}|' temp-c-$*.tex
	@mv temp-c-$*.tex $@
	
%.pdf: %.tex semantics.sty
	@echo "Compiling latex..."
	@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
	@mv temp-c-$*.pdf $@
	@echo "Done."
	
# this is used to start all of the common files
common-pdf-modules: common-c-syntax.pdf dynamic-c-semantics.k common-c-semantics.pdf common-c-standard-lib.pdf common-c-expressions.pdf common-c-memory.pdf common-c-statements.pdf common-c-conversions.pdf common-c-typing.pdf common-c-declarations.pdf common-c-helpers.pdf common-c-errors.pdf 
	
c-compiled.maude.tmp: c.k k-includes.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition..."
#@echo "executing \"$(K_MAUDE) c.k -u -language C\""
	@if time &> /dev/null; then time -p $(COMPILE_C); else $(COMPILE_C); fi
	@mv c-compiled.maude c-compiled.maude.tmp
	@$(INSERT_LINE) 2 c-compiled.maude.tmp "load $(K_PL_MODEL_CHECKER)"
	@$(INSERT_LINE) 3 c-compiled.maude.tmp "load $(K_SOCKETS)"
	@$(INSERT_LINE) 4 c-compiled.maude.tmp "load maudeLib/TCPSupport"
	@echo "Done".

c-compiled.maude: c-compiled.maude.tmp
	@grep -o '^ \(eq\|ceq\|rl\|crl\) .* label [^ ][^ ]* ' c-compiled.maude.tmp | grep -o ' label [^ ][^ ]*' | grep -o '[^ ]*$$' | sort | uniq -d > duplicateLabels.txt
	@if [ -s duplicateLabels.txt ]; then echo "Error: there are duplicate labels in the semantics.  This could cause profiling to give inaccurate results."; cat duplicateLabels.txt; exit 1; fi
	@mv c-compiled.maude.tmp c-compiled.maude
	
c-compiled-nd.maude: c.k k-includes.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with nondeterminism..."
	@if time &> /dev/null; then time -p $(COMPILE_C_ND); else $(COMPILE_C_ND); fi
	@mv c-compiled.maude c-compiled-nd.maude
	@$(INSERT_LINE) 2 c-compiled-nd.maude "load $(K_PL_MODEL_CHECKER)"
	@$(INSERT_LINE) 3 c-compiled-nd.maude "load $(K_SOCKETS)"
	@$(INSERT_LINE) 4 c-compiled-nd.maude "load maudeLib/TCPSupport"
	@echo "Done".

static-c-compiled.maude: c-syntax.k static-c.k k-includes.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES) $(INSERT_LINE) static-c-semantics.k static-c-configuration.k
	@echo "Compiling the static C definition..."
	@if time &> /dev/null; then time -p $(COMPILE_STATIC_C); else $(COMPILE_STATIC_C); fi
	@echo "Done".

	
static-c-total.maude: static-c-compiled.maude $(K_BASE_FILES) Makefile
	@echo "static-c-compiled.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@
	
c-total.maude: c-compiled.maude $(K_BASE_FILES) Makefile
	@echo "c-compiled.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@
	
c-total-nd.maude: c-compiled-nd.maude $(K_BASE_FILES) Makefile
	@echo "c-compiled-nd.maude" | perl $(SCRIPTS_DIR)/slurpFrontEnd.pl > $@

semantics: c-total.maude c-total-nd.maude

fast-nd: c-total.maude
	@cp c-total.maude c-total-nd.maude

fast-normal: c-total-nd.maude
	@cp c-total-nd.maude c-total.maude

semantics-fast: c-total.maude static-c-total.maude fast-nd

semantics-nd: c-total-nd.maude static-c-total.maude fast-normal

clean:
	rm -f $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp 

force: ;

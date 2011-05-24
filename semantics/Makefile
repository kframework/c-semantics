SCRIPTS_DIR = ../scripts
INSERT_LINE = $(SCRIPTS_DIR)/insert.sh

C_K_BASE ?= $(K_BASE)

K_MAUDE = $(C_K_BASE)/core/kompile
K_PRELUDE = $(C_K_BASE)/core/maude/lib/k-prelude
K_SOCKETS = $(C_K_BASE)/core/maude/lib/socket
K-PL-BUILTINS = $(C_K_BASE)/core/maude/lib/pl-builtins
K_PL_MODEL_CHECKER = $(C_K_BASE)/core/maude/lib/k-model-checker

K_BASE_FILES = $(K_PRELUDE).maude $(K_SOCKETS).maude $(K-PL-BUILTINS).maude $(K_PL_MODEL_CHECKER).maude
K_FILES = $(K_BASE_FILES) $(K_MAUDE)

COMPILE_C = K_BASE=$(C_K_BASE) $(K_MAUDE) c.k -u -language C
COMPILE_C_ND = K_BASE=$(C_K_BASE) $(K_MAUDE) c.k -nd -u -language C


COMMON_C_FILES = c-syntax.k \
common-c-syntax.k common-c-helpers.k common-c-configuration.k common-c-expressions.k common-c-semantics.k common-c-statements.k common-c-declarations.k common-c-typing.k
DYNAMIC_C_FILES = c.k dynamic-c-semantics.k dynamic-c-configuration.k dynamic-c-expressions.k dynamic-c-errors.k dynamic-c-statements.k dynamic-c-conversions.k dynamic-c-typing.k dynamic-c-declarations.k dynamic-c-memory.k dynamic-c-standard-lib.k
ALL_K_FILES = $(COMMON_C_FILES) $(DYNAMIC_C_FILES) maudeLib/TCPSupport.maude

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out *.tex *.log *.aux
K_CLEAN_FILES = *.maude kcompile_* \
c-compiled.maude.tmp.bak c-compiled-nd.maude.bak static-c.k.bak \
duplicateLabels.txt

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

pdf: common-pdf-modules
#c-expressions.pdf


check-vars:
ifeq ($(C_K_BASE),)
	@echo "ERROR: Please set K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export K_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif

# k-includes.k: check-vars Makefile
# @echo > k-includes.k
#@echo "load $(K_PRELUDE)" >> k-includes.k
#@echo "load $(K_SOCKETS)" >> k-includes.k

c.k: k-includes.k

%.tex: PDF_MODULES=`grep -o '^kmod.* is' $*.k | grep -o ' .* '`
%.tex: check-vars $(K_MAUDE) c.k k-includes.k %.k Makefile
	@rm -f temp-c-$*.tex
	@echo "Creating latex..."
	@K_BASE=$(C_K_BASE) $(K_MAUDE) c.k -l C -style bb -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out
	@sed -i 's|}mybracket|}\\mybracket|' temp-c-$*.tex
	@sed -i 's|\\begin{document}|\\input{semantics.sty}\n\\begin{document}|' temp-c-$*.tex
#\\geometry{papersize={14in,8.5in},textwidth=13.75in,textheight=7.7in}
	@mv temp-c-$*.tex $@

%.pdf: %.tex semantics.sty
	@echo "Compiling latex..."
	@if ! pdflatex -halt-on-error -interaction=nonstopmode -jobname=temp-c-$* $* 1> temp.pdflatex.out; then cat temp.pdflatex.out; false; fi
	@mv temp-c-$*.pdf $@
	@echo "Done."

# this is used to start all of the common files
common-pdf-modules: common-c-syntax.pdf dynamic-c-semantics.k common-c-semantics.pdf common-c-standard-lib.pdf common-c-expressions.pdf common-c-memory.pdf common-c-statements.pdf common-c-conversions.pdf common-c-typing.pdf common-c-declarations.pdf common-c-helpers.pdf common-c-errors.pdf

c-compiled.maude.tmp: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE) Makefile
	@echo "Compiling the C definition..."
	@$(COMPILE_C)
	@mv c-compiled.maude c-compiled.maude.tmp
#@$(INSERT_LINE) 2 c-compiled.maude.tmp "load $(K_PL_MODEL_CHECKER)"
#@$(INSERT_LINE) 3 c-compiled.maude.tmp "load $(K_SOCKETS)"
	@$(INSERT_LINE) 2 c-compiled.maude.tmp "load maudeLib/TCPSupport"
	@echo "Done".

c-compiled.maude: c-compiled.maude.tmp
	@grep -o '^ \(eq\|ceq\|rl\|crl\) .* label [^ ][^ ]* ' c-compiled.maude.tmp | grep -o ' label [^ ][^ ]*' | grep -o '[^ ]*$$' | sort | uniq -d > duplicateLabels.txt
	@if [ -s duplicateLabels.txt ]; then echo "Error: there are duplicate labels in the semantics.  This could cause profiling to give inaccurate results."; cat duplicateLabels.txt; exit 1; fi
	@mv c-compiled.maude.tmp c-compiled.maude

c-compiled-nd.maude: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE) Makefile
	@echo "Compiling the C definition with nondeterminism..."
	@$(COMPILE_C_ND)
	@mv c-compiled.maude c-compiled-nd.maude
#@$(INSERT_LINE) 2 c-compiled-nd.maude "load $(K_PL_MODEL_CHECKER)"
#@$(INSERT_LINE) 3 c-compiled-nd.maude "load $(K_SOCKETS)"
	@$(INSERT_LINE) 2 c-compiled-nd.maude "load maudeLib/TCPSupport"
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
	rm -f $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp

force: ;

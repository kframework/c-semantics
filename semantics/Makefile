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

ALL_K_FILES = common-c-syntax.k common-c-sized-operations.k common-c-helpers.k common-c-configuration.k common-c-semantics.k common-c-standard-lib.k common-c-expressions.k common-c-memory.k common-c-statements.k common-c-conversions.k common-c-typing.k common-c-declarations.k \
dynamic-c-semantics.k dynamic-c-configuration.k maudeLib/TCPSupport.maude

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.aux temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out
K_CLEAN_FILES = *.maude kcompile_* c-syntax.k c.k c-compiled.maude.bak duplicateLabels.txt

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

pdf: common-pdf-modules
#c-expressions.pdf

%.tex: PDF_MODULES=`grep -o '^kmod.* is' $*.k | grep -o ' .* '`
%.tex: $(K_MAUDE) c.k %.k
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

# pdf-dynamic-c: PDF_FILES=dynamic-c-semantics.k
# pdf-dynamic-c: PDF_MODULES=`grep -o '^kmod.* is' $(PDF_FILES)`
# pdf-dynamic-c: dynamic-c-semantics.k

# make 
	
# this is used to start all of the common files
common-pdf-modules: dynamic-c-configuration.pdf dynamic-c-semantics.pdf common-c-statements.pdf common-c-expressions.pdf common-c-memory.pdf
	
c-syntax.k: Makefile
	@printf "`cat c-syntax.template`" > c-syntax.k	
	
c.k: c-syntax.k c-maude.template Makefile
	@printf "`cat c-maude.template`" "load $(K_PRELUDE)" "load $(K_SOCKETS)" dynamic-c-configuration dynamic-c-semantics DYNAMIC-C-SEMANTICS > c.k
	
c-compiled.maude.tmp: c.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES)
	@echo "Compiling the C definition..."
#@echo "executing \"$(K_MAUDE) c.k -u -language C\""
	@$(K_MAUDE) c.k -u -language C
	@mv c-compiled.maude c-compiled.maude.tmp
	@echo "Done".

c-compiled.maude: c-compiled.maude.tmp
	@grep -o '^ \(eq\|ceq\|rl\|crl\) .* label [^ ][^ ]* ' c-compiled.maude.tmp | grep -o ' label [^ ][^ ]*' | grep -o '[^ ]*$$' | sort | uniq -d > duplicateLabels.txt
	@if [ -s duplicateLabels.txt ]; then echo "Error: there are duplicate labels in the semantics.  This could cause profiling to give inaccurate results."; cat duplicateLabels.txt; exit 1; fi
	@mv c-compiled.maude.tmp c-compiled.maude
	
libraryRules.txt: common-c-standard-lib.k Makefile
	@grep -o 'rule \[[^] ][^] ]*\]:' common-c-standard-lib.k | grep -o '\[[^] ][^] ]*\]' | grep -o '[^][][^][]*' | sort | uniq > libraryRules.txt
	
lint: c.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES)
	@echo "Checking the C definition..."
	@time ($(K_MAUDE) c.k -u -lint -language C)
	@rm -f c-compiled.maude
	@echo "Done".
	
c-total.maude: c-compiled.maude $(K_BASE_FILES) Makefile
#@sed -i '2 i load $(K_PL_MODEL_CHECKER)' c-compiled.maude
	@$(INSERT_LINE) 2 c-compiled.maude "load $(K_PL_MODEL_CHECKER)"
	@$(INSERT_LINE) 3 c-compiled.maude "load $(K_SOCKETS)"
	@$(INSERT_LINE) 4 c-compiled.maude "load maudeLib/TCPSupport"
	@echo | cat c-compiled.maude c-syntax.maude - common-c-configuration.maude | perl $(SCRIPTS_DIR)/slurp.pl ./ > c-total.maude

semantics: c-total.maude libraryRules.txt

clean:
	rm -f $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp 

force: ;

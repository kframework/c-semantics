#K_MAUDE_BASE ?= ..
K_COMPILE_BASE = tools/kompile.pl
SCRIPTS_DIR = ../scripts

K_MAUDE = $(K_MAUDE_BASE)/$(K_COMPILE_BASE)
K_PRELUDE = $(K_MAUDE_BASE)/k-prelude
K-PL-BUILTINS = $(K_MAUDE_BASE)/pl-builtins
K_PL_MODEL_CHECKER = $(K_MAUDE_BASE)/k-model-checker

ADDITIONAL_SYNTAX = "including MATCH-C-SYNTAX ."

ALL_K_FILES = common-c-syntax.k common-c-configuration.k common-c-semantics.k common-c-standard-lib.k common-c-expressions.k common-c-memory.k common-c-statements.k common-c-conversions.k common-c-typing.k common-c-declarations.k \
match-c-syntax.k match-c-semantics.k match-c-configuration.k \
dynamic-c-semantics.k dynamic-c-configuration.k

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.aux temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out
K_CLEAN_FILES = *.maude kcompile_* c-syntax.k c.k

.PHONY: all clean force match semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

pdf: common-pdf-modules
#c-expressions.pdf

# these are fake in order to set the modules correctly
common-c-%-fake: PDF_MODULES=`grep -o '^kmod.* is' common-c-$*.k | grep -o ' .* '`
common-c-%-fake: c-%.pdf
	@true

# this is used to start all of the common files
common-pdf-modules: common-c-statements-fake common-c-expressions-fake common-c-memory-fake

c-%.pdf: c.k $(ALL_K_FILES) Makefile
	@rm -f temp-c-$*.tex
	@echo "Creating latex..."
	@$(K_MAUDE) c.k -l C -style bb -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out
	@sed -i 's|}mybracket|}\\mybracket|' temp-c-$*.tex
	@sed -i 's|\\begin{document}|\\geometry{papersize={17in,11in},textwidth=16.75in,textheight=10in}\\begin{document}|' temp-c-$*.tex
	@echo "Compiling latex..."
	@pdflatex temp-c-$*.tex 1> temp.pdflatex.out
	@mv temp-c-$*.pdf $@
	@echo "Done."
	
c-syntax.k: Makefile
	@printf "`cat c-syntax.template`" $(ADDITIONAL_SYNTAX) > c-syntax.k	
	
c.k: c-syntax.k c-maude.template Makefile
	@printf "`cat c-maude.template`" $(K_PRELUDE) dynamic-c-configuration dynamic-c-semantics DYNAMIC-C-SEMANTICS > c.k
	
c-compiled.maude: c.k $(K_MAUDE_BASE)/k-prelude.maude $(K_MAUDE) $(ALL_K_FILES)
	@echo "Compiling the C definition..."
	@time ($(K_MAUDE) c.k -u -language C)
	@echo "Done".
	
c-total.maude: c-compiled.maude $(K_PRELUDE).maude $(K-PL-BUILTINS).maude $(K_PL_MODEL_CHECKER).maude Makefile
#@sed -i '2 i load $(K_PL_MODEL_CHECKER)' c-compiled.maude
#@sed -i'' -e '2i\
#load $(K_PL_MODEL_CHECKER)' c-compiled.maude
#echo adds a newline
	@echo | cat c-compiled.maude c-syntax.maude - common-c-configuration.maude | perl $(SCRIPTS_DIR)/slurp.pl ./ > c-total.maude

semantics: c-total.maude

clean:
	rm -f $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES) program-*-compiled.maude.tmp

force: ;

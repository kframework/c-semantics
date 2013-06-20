SCRIPTS_DIR = ../scripts
INSERT_LINE = $(SCRIPTS_DIR)/insert.sh
APPEND_LINE = $(SCRIPTS_DIR)/append.sh
FIRST_LINE_SCRIPT = $(SCRIPTS_DIR)/getFirstLine.pl

KOMPILE = $(C_K_BASE)/bin/kompile

K_LATEX_STYLE = $(C_K_BASE)/include/latex/k.sty

KOMPILE_C = $(KOMPILE) c.k -w -v -l C -transition "interpRule"

KOMPILE_C_ND = $(KOMPILE) c.k -o "c-kompiled-nd" -w -v -l C -transition "observable computational" -superheat "ndheat" -supercool "ndlocal"
KOMPILE_C_ND_THREAD = $(KOMPILE) c.k -o "c-kompiled-nd-thread" -w -v -l C -transition "observable computational"

COMMON_C_FILES = c-syntax.k \
common-c-syntax.k common-c-helpers.k c-configuration.k common-c-expressions.k common-c-semantics.k common-c-statements.k common-c-declarations.k common-c-typing.k
DYNAMIC_C_FILES = c.k dynamic-c-semantics.k dynamic-c-expressions.k dynamic-c-errors.k dynamic-c-statements.k dynamic-c-conversions.k dynamic-c-typing.k dynamic-c-declarations.k dynamic-c-memory.k dynamic-c-standard-lib.k

LATEX_CLEAN_FILES = temp-c-*.tex temp-c-*.log temp.pdflatex.out *.pdf temp.kpdf.out *.tex *.log *.aux
K_CLEAN_FILES = *.maude .k c-kompiled kcompile_* static-c.k.bak duplicateLabels.txt 

.PHONY: all clean force semantics pdf common-pdf-modules common-c-%-fake

.SECONDARY:

all: semantics

check-vars:
ifeq ($(C_K_BASE),)
	@echo "ERROR: Please set C_K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export C_K_BASE=/path/to/k/framework', and then rerun 'make'"
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
temp-c-%.tex: check-vars $(KOMPILE) c.k $(addsuffix .k,$(PDF_FILES))
	@echo "Creating latex..."
	$(KOMPILE) c.k -l C -package-options "style=bubble,magicTight" -latex $(PDF_MODULES) -output temp-c-$* 1> temp.kpdf.out

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

c-kompiled/main.maude: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition..."
	@$(KOMPILE_C)

c-kompiled-nd/main.maude: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with nondeterminism..."
	@$(KOMPILE_C_ND)

c-kompiled-nd-thread/main.maude: check-vars $(K_FILES) $(COMMON_C_FILES) $(DYNAMIC_C_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with thread-nondeterminism..."
	@$(KOMPILE_C_ND_THREAD)

semantics: fast nd thread

fast: c-kompiled/main.maude

nd: c-kompiled-nd/main.maude

thread: c-kompiled-nd-thread/main.maude

clean:
	rm -rf $(LATEX_CLEAN_FILES) $(K_CLEAN_FILES)

force: ;

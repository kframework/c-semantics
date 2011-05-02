SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
#svnversion
define TEST_C_PROGRAM
#include <stdio.h> 
int main(void) {printf("x");}

endef

# this should be defined by the user
# K_MAUDE_BASE ?= .


#OUTPUT_FILTER_DIR = $(K_MAUDE_BASE)/tools/OutputFilter
#OUTPUT_FILTER ?= $(OUTPUT_FILTER_DIR)/filterOutput
#FILTER = $(SEMANTICS_DIR)/outputFilter.yml
#VPATH = programs

FILES_TO_DIST = \
	$(SEMANTICS_DIR)/c-total.maude \
	$(SEMANTICS_DIR)/c-total-nd.maude \
	$(wildcard $(SCRIPTS_DIR)/*.sql) \
	$(SCRIPTS_DIR)/accessProfiling.pl \
	$(SCRIPTS_DIR)/link.pl \
	$(SCRIPTS_DIR)/slurp.pl \
	$(SCRIPTS_DIR)/wrapper.pl \
	$(SCRIPTS_DIR)/compile.pl \
	$(SCRIPTS_DIR)/compileProgram.sh \
	$(SCRIPTS_DIR)/xmlToK.pl \
	$(SCRIPTS_DIR)/graphSearch.pl \
	$(SCRIPTS_DIR)/programRunner.sh \
	$(SCRIPTS_DIR)/fileserver.pl \
	$(SCRIPTS_DIR)/analyzeProfile.pl \
	$(PARSER_DIR)/cparser \
	$(wildcard $(SEMANTICS_DIR)/includes/*) \
	$(wildcard $(SEMANTICS_DIR)/lib/*)
	
.PHONY: all clean run test force cparser maude-fragments build-all dynamic match fix semantics gcc-output benchmark dist fast-test dist-make check-input

all: WHICH_SEMANTICS="semantics"
all: dist

fast: WHICH_SEMANTICS="semantics-fast"
fast: dist

nd: WHICH_SEMANTICS="semantics-nd"
nd: dist


check-vars: 
ifeq ($(K_MAUDE_BASE),)
	@echo "Error: Please set K_MAUDE_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\"
	@exit 1
endif
	@echo Looking for maude...
	@echo | maude > /dev/null
	@echo Found.

dist: check-vars $(DIST_DIR)/dist.done

pdf: check-vars
	@make -C $(SEMANTICS_DIR) pdf

export TEST_C_PROGRAM
$(DIST_DIR)/dist.done: check-vars Makefile cparser semantics $(FILES_TO_DIST)
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/includes
	@mkdir -p $(DIST_DIR)/lib
	@cp $(FILES_TO_DIST) $(DIST_DIR)
	@mv $(DIST_DIR)/*.h $(DIST_DIR)/includes
	@mv $(DIST_DIR)/clib.c $(DIST_DIR)/lib
	@mv $(DIST_DIR)/compile.pl $(DIST_DIR)/kcc
	@echo "Compiling the standard library..."
	@$(DIST_DIR)/kcc -c -o $(DIST_DIR)/lib/clib.o $(DIST_DIR)/lib/clib.c
	@echo "Done."
	@echo "Testing kcc..."
	@echo "$$TEST_C_PROGRAM" > $(DIST_DIR)/tmpSemanticCalibration.c
	@echo -n "x" > $(DIST_DIR)/tmpSemanticCalibration.expectedOut
#cat $(DIST_DIR)/tmpSemanticCalibration.c
	@$(DIST_DIR)/kcc -s -o $(DIST_DIR)/tmpSemanticCalibration.out $(DIST_DIR)/tmpSemanticCalibration.c
	@$(DIST_DIR)/tmpSemanticCalibration.out > $(DIST_DIR)/tmpSemanticCalibration.txt || if [ "$$?" ]; then true; else echo "There was a problem with the test.  I expected a return value 0, but got $$?"; false; fi
	@echo "Return value is correct."
#@|| if [ $$? ]; then true else echo "There was a problem with the test.  I expected a return value 0, but got $$?"; false
	@if diff $(DIST_DIR)/tmpSemanticCalibration.txt $(DIST_DIR)/tmpSemanticCalibration.expectedOut &> /dev/null; then true; else echo "There was a problem with the test.  I expected \"x\", but I got \"`cat $(DIST_DIR)/tmpSemanticCalibration.txt`\""; false; fi
	@echo "Output is correct."
	@echo "Done."
	@echo "Calibrating the semantic profiler..."
# done so that an empty file gets copied by the analyzeProfile.pl wrapper
	@mv maudeProfileDBfile.sqlite maudeProfileDBfile.sqlite.calibration.bak &> /dev/null || true
	@echo > maudeProfileDBfile.sqlite
	@perl $(SCRIPTS_DIR)/initializeProfiler.pl $(SEMANTICS_DIR)/c-compiled.maude
# @PROFILE=1 PROFILE_CALIBRATION=1 $(DIST_DIR)/tmpSemanticCalibration.out &> /dev/null
	@mv maudeProfileDBfile.sqlite $(DIST_DIR)/maudeProfileDBfile.calibration.sqlite
	@mv maudeProfileDBfile.sqlite.calibration.bak maudeProfileDBfile.sqlite &> /dev/null || true
	@echo "Done."
	@echo "Reticulating splines..."
# heheh
	@echo "Done."
	@echo "Cleaning up..."
	@rm $(DIST_DIR)/tmpSemanticCalibration.c
	@rm $(DIST_DIR)/tmpSemanticCalibration.out
	@rm $(DIST_DIR)/tmpSemanticCalibration.txt
	@rm $(DIST_DIR)/tmpSemanticCalibration.expectedOut
	@echo "Done."
	@touch $(DIST_DIR)/dist.done

test: dist
	@make -C tests
	
force: ;

cparser:
	@make -C $(PARSER_DIR)
	@-strip $(PARSER)

semantics: check-vars
#@rm -f $(SEMANTICS_DIR)/c-total-nd.maude
	@make $(WHICH_SEMANTICS) -C $(SEMANTICS_DIR)

clean:
	make -C $(PARSER_DIR) clean
	make -C $(SEMANTICS_DIR) clean
	make -C gcc-test clean
	make -C tests clean
	rm -rf $(DIST_DIR)
	rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre

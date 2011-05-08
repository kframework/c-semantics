SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
#svnversion


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
	$(SCRIPTS_DIR)/programRunner.pl \
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
	@echo "ERROR: Please set K_MAUDE_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export K_MAUDE_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif
	@if ! gcc -v &> /dev/null; then echo "ERROR: You don't seem to have gcc installed.  You need to install this before continuing"; false; fi
#@if ! gcc-4 -v &> /dev/null; then echo "WARNING: You don't seem to have gcc-4 installed, which will probably prevent you from installing certain perl modules.  Continuing anyway..."; fi
	@echo Looking for maude...
	@echo | maude > /dev/null
	@echo Found.
	@echo "Checking for perl modules..."
	@perl $(SCRIPTS_DIR)/checkForModules.pl
	@echo "Found."

dist: check-vars $(DIST_DIR)/dist.done

pdf: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) pdf

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
	@perl $(SCRIPTS_DIR)/testInstall.pl $(DIST_DIR)/kcc $(DIST_DIR)/testProgram.c $(DIST_DIR)/testProgram.compiled
	@echo "Done."
	@echo "Calibrating the semantic profiler..."
# done so that an empty file gets copied by the analyzeProfile.pl wrapper
	@mv maudeProfileDBfile.sqlite maudeProfileDBfile.sqlite.calibration.bak &> /dev/null || true
	@touch maudeProfileDBfile.sqlite
	@perl $(SCRIPTS_DIR)/initializeProfiler.pl $(SEMANTICS_DIR)/c-compiled.maude
	@mv maudeProfileDBfile.sqlite $(DIST_DIR)/maudeProfileDBfile.calibration.sqlite
	@mv maudeProfileDBfile.sqlite.calibration.bak maudeProfileDBfile.sqlite &> /dev/null || true
	@echo "Done."
	@echo "Cleaning up..."
	@rm -f $(DIST_DIR)/testProgram.c
	@rm -f $(DIST_DIR)/testProgram.compiled
	@echo "Done."
	@touch $(DIST_DIR)/dist.done

test: dist
	@$(MAKE) -C tests
	
force: ;

cparser:
	@$(MAKE) -C $(PARSER_DIR)
	@-strip $(PARSER)

semantics: check-vars
#@rm -f $(SEMANTICS_DIR)/c-total-nd.maude
	@$(MAKE) $(WHICH_SEMANTICS) -C $(SEMANTICS_DIR)

clean:
	$(MAKE) -C $(PARSER_DIR) clean
	$(MAKE) -C $(SEMANTICS_DIR) clean
	$(MAKE) -C gcc-test clean
	$(MAKE) -C tests clean
	rm -rf $(DIST_DIR)
	rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre

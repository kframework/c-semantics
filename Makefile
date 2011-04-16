SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist

# this should be defined by the user
# K_MAUDE_BASE ?= .


OUTPUT_FILTER_DIR = $(K_MAUDE_BASE)/tools/OutputFilter
OUTPUT_FILTER ?= $(OUTPUT_FILTER_DIR)/filterOutput
FILTER = $(SEMANTICS_DIR)/outputFilter.yml
#VPATH = programs

FILES_TO_DIST = \
	$(SEMANTICS_DIR)/c-total.maude \
	$(wildcard $(SCRIPTS_DIR)/*.sql) \
	$(SCRIPTS_DIR)/accessProfiling.pl \
	$(SCRIPTS_DIR)/link.pl \
	$(SCRIPTS_DIR)/slurp.pl \
	$(SCRIPTS_DIR)/wrapper.pl \
	$(SCRIPTS_DIR)/compile.sh \
	$(SCRIPTS_DIR)/compileProgram.sh \
	$(SCRIPTS_DIR)/xmlToK.pl \
	$(SCRIPTS_DIR)/graphSearch.pl \
	$(SCRIPTS_DIR)/programRunner.sh \
	$(SCRIPTS_DIR)/fileserver.pl \
	$(SCRIPTS_DIR)/analyzeProfile.pl \
	$(SCRIPTS_DIR)/printProfileData.pl \
	$(PARSER_DIR)/cparser \
	$(wildcard $(SEMANTICS_DIR)/includes/*) \
	$(wildcard $(SEMANTICS_DIR)/lib/*)
	
.PHONY: all clean run test force cparser maude-fragments build-all dynamic match fix semantics gcc-output benchmark dist fast-test dist-make check-input

all: dist

check-vars: 
ifeq ($(K_MAUDE_BASE),)
	@echo "Error: Please set K_MAUDE_BASE to the full path of your K installation."
	@exit 1
endif

dist: check-vars $(DIST_DIR)/dist.done

filter: $(OUTPUT_FILTER)

pdf: check-vars
	@make -C $(SEMANTICS_DIR) pdf

$(OUTPUT_FILTER): check-vars $(wildcard $(OUTPUT_FILTER_DIR)/*.hs)
	@make -C $(OUTPUT_FILTER_DIR)
	@strip $(OUTPUT_FILTER)
#@if [ `which strip 2> /dev/null` ]; then strip $(OUTPUT_FILTER); fi
#@if [ `which gzexe 2> /dev/null` ]; then gzexe $(OUTPUT_FILTER); fi
#@rm -f $(OUTPUT_FILTER_DIR)/filterOutput~

$(DIST_DIR)/dist.done: check-vars Makefile filter cparser semantics $(FILES_TO_DIST)
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/includes
	@mkdir -p $(DIST_DIR)/lib
	@cp $(FILES_TO_DIST) $(DIST_DIR)
	@cp $(OUTPUT_FILTER) $(DIST_DIR)
	@cp $(FILTER) $(DIST_DIR)
	@mv $(DIST_DIR)/*.h $(DIST_DIR)/includes
	@mv $(DIST_DIR)/clib.c $(DIST_DIR)/lib
#@ln -s -f compile.sh $(DIST_DIR)/kcc
	@mv $(DIST_DIR)/compile.sh $(DIST_DIR)/kcc
	@echo "Compiling the standard library..."
	@$(DIST_DIR)/kcc -c -o $(DIST_DIR)/lib/clib.o $(DIST_DIR)/lib/clib.c
	@echo "Done."
	@echo "Testing kcc..."
	@echo "int main(void) {}" > $(DIST_DIR)/tmpSemanticCalibration.c
	@$(DIST_DIR)/kcc -s -o $(DIST_DIR)/tmpSemanticCalibration.out $(DIST_DIR)/tmpSemanticCalibration.c
	@$(DIST_DIR)/tmpSemanticCalibration.out
	@echo "Done."
	@echo "Calibrating the semantic profiler..."
# done so that an empty file gets copied by the analyzeProfile.pl wrapper
	@echo > $(DIST_DIR)/maudeProfileDBfile.calibration.sqlite
	@mv maudeProfileDBfile.sqlite maudeProfileDBfile.sqlite.calibration.bak &> /dev/null || true
	@perl $(SCRIPTS_DIR)/initializeProfiler.pl $(SEMANTICS_DIR)/c-compiled.maude
	@PROFILE=1 PROFILE_CALIBRATION=1 $(DIST_DIR)/tmpSemanticCalibration.out &> /dev/null
	@mv maudeProfileDBfile.sqlite $(DIST_DIR)/maudeProfileDBfile.calibration.sqlite
	@mv maudeProfileDBfile.sqlite.calibration.bak maudeProfileDBfile.sqlite &> /dev/null || true
	@echo "Done."
	@echo "Reticulating splines..."
# heheh
	@echo "Done."
	@echo "Cleaning up..."
	@rm $(DIST_DIR)/tmpSemanticCalibration.c
	@rm $(DIST_DIR)/tmpSemanticCalibration.out
	@echo "Done."
	@touch $(DIST_DIR)/dist.done

test: dist
	@make -C tests
	
force: ;

cparser:
	@make -C $(PARSER_DIR)
	@strip $(PARSER)

semantics: check-vars
	@make -C $(SEMANTICS_DIR) semantics

benchmark: profile.csv

profile.csv: profile.log
	perl analyzeProfile.pl > profile.csv

clean:
	make -C $(PARSER_DIR) clean
	make -C $(SEMANTICS_DIR) clean
	make -C gcc-test clean
	make -C tests clean
	rm -rf $(DIST_DIR)
	rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out

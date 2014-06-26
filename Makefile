SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
LIBC_DIR = libc
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/query-kcc-prof \
	$(SCRIPTS_DIR)/analyzeProfile.pl \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/xml-to-k \
	$(SCRIPTS_DIR)/program-runner \
	$(PARSER_DIR)/cparser \
	$(wildcard $(LIBC_DIR)/includes/*) \

.PHONY: default check-vars semantics clean

default: dist

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR): $(FILES_TO_DIST) semantics | check-vars
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/includes
	@mkdir -p $(DIST_DIR)/lib
	@cp $(FILES_TO_DIST) $(DIST_DIR)
	@cp -r $(SEMANTICS_DIR)/c11-translation-kompiled $(DIST_DIR)
	@cp -r $(SEMANTICS_DIR)/c11-kompiled $(DIST_DIR)
	@cp -r $(SEMANTICS_DIR)/c11-nd-kompiled $(DIST_DIR)
	@cp -r $(SEMANTICS_DIR)/c11-nd-thread-kompiled $(DIST_DIR)
	@mv $(DIST_DIR)/*.h $(DIST_DIR)/includes
	@echo "Translating the standard library..."
	@$(DIST_DIR)/kcc -d -clib -o $(DIST_DIR)/lib/libc.o $(wildcard $(LIBC_DIR)/src/*.c)
	@echo "Done."
	@echo "Testing kcc..."
	@perl $(SCRIPTS_DIR)/testInstall.pl $(DIST_DIR)/kcc $(DIST_DIR)/testProgram.c $(DIST_DIR)/testProgram.compiled
	@echo "Done."
	@echo "Calibrating the semantic profiler..."
# done so that an empty file gets copied by the analyzeProfile.pl wrapper
	@mv kccProfileDB.sqlite kccProfileDB.sqlite.calibration.bak > /dev/null 2>&1 || true
	@touch kccProfileDB.sqlite
	@perl $(SCRIPTS_DIR)/initializeProfiler.pl $(DIST_DIR)/c11-kompiled/base.maude
	@mv kccProfileDB.sqlite $(DIST_DIR)/kccProfileDB.calibration.sqlite
	@mv kccProfileDB.sqlite.calibration.bak kccProfileDB.sqlite > /dev/null 2>&1 || true
	@echo "Done."
	@echo "Cleaning up..."
	@rm -f $(DIST_DIR)/testProgram.c
	@rm -f $(DIST_DIR)/testProgram.compiled
	@touch $(DIST_DIR)
	@echo "Done."

parser/cparser:
	@echo "Building the C parser..."
	@$(MAKE) -C $(PARSER_DIR)

semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) all

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	@-rm -rf $(DIST_DIR)
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre

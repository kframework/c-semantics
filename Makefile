SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
PROFILE = default-profile
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = 
PASS_TESTS_DIR = tests/unit-pass
FAIL_TESTS_DIR = tests/unit-fail
FAIL_COMPILE_TESTS_DIR = tests/unit-fail-compilation

EXTENSION = cmx

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/kcc-switch \
	$(SCRIPTS_DIR)/xml-to-k \
	$(SCRIPTS_DIR)/program-runner \
	$(SCRIPTS_DIR)/histogram-csv \
	$(PARSER_DIR)/cparser \

.PHONY: default check-vars semantics clean fast translation-semantics execution-semantics $(DIST_DIR) $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions-common.k $(SEMANTICS_DIR)/extensions-translation.k $(SEMANTICS_DIR)/extensions-execution.k test-build pass fail fail-compile

default: dist

fast: $(DIST_DIR)/$(PROFILE)/lib/libc.so $(DIST_DIR)/$(PROFILE)/c11-kompiled/c11-kompiled/def.$(EXTENSION)

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then if ! clang -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc or clang installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/kcc $(DIST_DIR)/$(PROFILE)/pp: $(FILES_TO_DIST) $(wildcard $(PROFILE)/include/*) $(PROFILE)/pp | check-vars
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > $(DIST_DIR)/current-profile
	@cp $(PROFILE)/pp $(DIST_DIR)/$(PROFILE)
	@cp -r $(PROFILE)/include $(DIST_DIR)/$(PROFILE)
	@cp -p $(FILES_TO_DIST) $(DIST_DIR)
	@cp -p $(SCRIPTS_DIR)/kcc $(DIST_DIR)/kclang

$(DIST_DIR)/$(PROFILE)/c11-kompiled/c11-kompiled/def.$(EXTENSION): $(DIST_DIR)/kcc $(DIST_DIR)/$(PROFILE)/pp execution-semantics
	@cp -p -r $(SEMANTICS_DIR)/c11-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/def.$(EXTENSION): $(DIST_DIR)/kcc $(DIST_DIR)/$(PROFILE)/pp translation-semantics
	@cp -p -r $(SEMANTICS_DIR)/c11-translation-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/def.$(EXTENSION): semantics
	@cp -r $(SEMANTICS_DIR)/c11-nd-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.$(EXTENSION): semantics
	@cp -r $(SEMANTICS_DIR)/c11-nd-thread-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/lib/libc.so: $(DIST_DIR)/$(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/def.$(EXTENSION) $(wildcard $(PROFILE)/src/*) $(DIST_DIR)/kcc
	@echo "Translating the standard library... ($(PROFILE))"
	$(DIST_DIR)/kcc -s -shared -o $(DIST_DIR)/$(PROFILE)/lib/libc.so $(wildcard $(PROFILE)/src/*.c) $(KCCFLAGS) -I $(PROFILE)/src/
	@echo "Done."

$(DIST_DIR): test-build $(DIST_DIR)/$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/def.$(EXTENSION) $(DIST_DIR)/$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.$(EXTENSION)

test-build: fast
	@echo "Testing kcc..."
	printf "#include <stdio.h>\nint main(void) {printf(\"x\"); return 42;}\n" | $(DIST_DIR)/kcc - -o $(DIST_DIR)/testProgram.compiled
	$(DIST_DIR)/testProgram.compiled 2> /dev/null > $(DIST_DIR)/testProgram.out; test $$? -eq 42
	grep x $(DIST_DIR)/testProgram.out > /dev/null
	@echo "Done."
	@echo "Cleaning up..."
	@rm -f $(DIST_DIR)/testProgram.compiled
	@rm -f $(DIST_DIR)/testProgram.out
	@echo "Done."

parser/cparser:
	@echo "Building the C parser..."
	@$(MAKE) -C $(PARSER_DIR)

translation-semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions-common.k $(SEMANTICS_DIR)/extensions-translation.k
	@$(MAKE) -C $(SEMANTICS_DIR) translation

execution-semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions-common.k $(SEMANTICS_DIR)/extensions-execution.k
	@$(MAKE) -C $(SEMANTICS_DIR) execution

$(SEMANTICS_DIR)/settings.k:
	@diff $(PROFILE)/semantics/settings.k $(SEMANTICS_DIR)/settings.k > /dev/null 2>&1 || cp $(PROFILE)/semantics/settings.k $(SEMANTICS_DIR)

$(SEMANTICS_DIR)/extensions-common.k:
	@diff $(PROFILE)/semantics/extensions-common.k $(SEMANTICS_DIR)/extensions-common.k > /dev/null 2>&1 || cp $(PROFILE)/semantics/extensions-common.k $(SEMANTICS_DIR)
$(SEMANTICS_DIR)/extensions-translation.k:
	@diff $(PROFILE)/semantics/extensions-translation.k $(SEMANTICS_DIR)/extensions-translation.k > /dev/null 2>&1 || cp $(PROFILE)/semantics/extensions-translation.k $(SEMANTICS_DIR)
$(SEMANTICS_DIR)/extensions-execution.k:
	@diff $(PROFILE)/semantics/extensions-execution.k $(SEMANTICS_DIR)/extensions-execution.k > /dev/null 2>&1 || cp $(PROFILE)/semantics/extensions-execution.k $(SEMANTICS_DIR)

semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions-common.k $(SEMANTICS_DIR)/extensions-translation.k $(SEMANTICS_DIR)/extensions-execution.k
	@$(MAKE) -C $(SEMANTICS_DIR) all

check:	pass fail fail-compile

pass:	fast
	@$(MAKE) -C $(PASS_TESTS_DIR) comparison

fail:	fast
	@$(MAKE) -C $(FAIL_TESTS_DIR) comparison

fail-compile:	fast
	@$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) comparison

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	-$(MAKE) -C $(PASS_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) clean
	@-rm -rf $(DIST_DIR)
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions-common.k $(SEMANTICS_DIR)/extensions-translation.k $(SEMANTICS_DIR)/extensions-execution.k

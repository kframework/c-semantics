SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
export PROFILE_DIR = $(shell pwd)/x86-gcc-limited-libc
export PROFILE=$(shell basename $(PROFILE_DIR))
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = 
PASS_TESTS_DIR = tests/unit-pass
FAIL_TESTS_DIR = tests/unit-fail
FAIL_COMPILE_TESTS_DIR = tests/unit-fail-compilation

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/ignored-flags \
	$(SCRIPTS_DIR)/xml-to-k \
	$(SCRIPTS_DIR)/program-runner \
	$(SCRIPTS_DIR)/histogram-csv \
	$(PARSER_DIR)/cparser \
        LICENSE \
        licenses

.PHONY: default check-vars semantics clean fast translation-semantics execution-semantics $(DIST_DIR) test-build pass fail fail-compile

default: dist

fast: $(DIST_DIR)/$(PROFILE)/lib/libc.so $(DIST_DIR)/$(PROFILE)/c11-kompiled/c11-kompiled/timestamp

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then if ! clang -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc or clang installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/kcc: $(FILES_TO_DIST) $(wildcard $(PROFILE_DIR)/include/*) $(PROFILE_DIR)/pp | check-vars
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > $(DIST_DIR)/current-profile
	@printf "%s" $(PROFILE) > $(DIST_DIR)/default-profile
	@cp -Lp $(PROFILE_DIR)/pp $(DIST_DIR)/$(PROFILE)
	@cp -RLp $(PROFILE_DIR)/include $(DIST_DIR)/$(PROFILE)
	@cp -RLp $(PROFILE_DIR)/src $(DIST_DIR)/$(PROFILE)
	@cp -RLp $(FILES_TO_DIST) $(DIST_DIR)
	@cp -p $(SCRIPTS_DIR)/kcc $(DIST_DIR)/kclang

$(DIST_DIR)/$(PROFILE)/c11-kompiled/c11-kompiled/timestamp: $(DIST_DIR)/kcc execution-semantics
	@cp -p -RL $(SEMANTICS_DIR)/$(PROFILE)/c11-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/timestamp: $(DIST_DIR)/kcc translation-semantics
	@cp -p -RL $(SEMANTICS_DIR)/$(PROFILE)/c11-translation-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp: semantics
	@cp -RL $(SEMANTICS_DIR)/$(PROFILE)/c11-nd-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp: semantics
	@cp -RL $(SEMANTICS_DIR)/$(PROFILE)/c11-nd-thread-kompiled $(DIST_DIR)/$(PROFILE)

$(DIST_DIR)/$(PROFILE)/lib/libc.so: $(DIST_DIR)/$(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/timestamp $(wildcard $(PROFILE_DIR)/src/*) $(DIST_DIR)/kcc
	@echo "Translating the standard library... ($(PROFILE_DIR))"
	$(DIST_DIR)/kcc -nodefaultlibs -shared -o $(DIST_DIR)/$(PROFILE)/lib/libc.so $(wildcard $(PROFILE_DIR)/src/*.c) $(KCCFLAGS) -I $(PROFILE_DIR)/src/
	@echo "Done."

$(DIST_DIR): test-build $(DIST_DIR)/$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp $(DIST_DIR)/$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp

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

translation-semantics: check-vars 
	@$(MAKE) -C $(SEMANTICS_DIR) translation

execution-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) execution

semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) all

check:	pass fail fail-compile

pass:	test-build
	@$(MAKE) -C $(PASS_TESTS_DIR) comparison

fail:	test-build
	@$(MAKE) -C $(FAIL_TESTS_DIR) comparison

fail-compile:	test-build
	@$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) comparison

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	-$(MAKE) -C $(PASS_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) clean
	@-rm -rf $(DIST_DIR)
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre 

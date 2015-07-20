SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
LIBC_DIR = libc
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = 
PASS_TESTS_DIR = tests/unit-pass
FAIL_TESTS_DIR = tests/unit-fail
FAIL_COMPILE_TESTS_DIR = tests/unit-fail-compilation

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/xml-to-k \
	$(SCRIPTS_DIR)/program-runner \
	$(PARSER_DIR)/cparser \

.PHONY: default check-vars semantics clean fast translation-semantics execution-semantics $(DIST_DIR) $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions.k test-build pass fail fail-compile

default: dist

fast: $(DIST_DIR)/lib/libc.so $(DIST_DIR)/c11-kompiled/c11-kompiled/def.cmx

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then if ! clang -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc or clang installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/kcc: $(FILES_TO_DIST) $(wildcard $(LIBC_DIR)/includes/*) | check-vars
	@mkdir -p $(DIST_DIR)
	@mkdir -p $(DIST_DIR)/lib
	@cp -r $(LIBC_DIR)/includes $(DIST_DIR)
	@cp -p $(FILES_TO_DIST) $(DIST_DIR)
	@cp -p $(SCRIPTS_DIR)/kcc $(DIST_DIR)/kclang

$(DIST_DIR)/c11-kompiled/c11-kompiled/def.cmx: $(DIST_DIR)/kcc execution-semantics
	@cp -p -r $(SEMANTICS_DIR)/c11-kompiled $(DIST_DIR)

$(DIST_DIR)/c11-translation-kompiled/c11-translation-kompiled/def.cmx: $(DIST_DIR)/kcc translation-semantics
	@cp -p -r $(SEMANTICS_DIR)/c11-translation-kompiled $(DIST_DIR)

$(DIST_DIR)/c11-nd-kompiled/c11-nd-kompiled/def.cmx: semantics
	@cp -r $(SEMANTICS_DIR)/c11-nd-kompiled $(DIST_DIR)

$(DIST_DIR)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.cmx: semantics
	@cp -r $(SEMANTICS_DIR)/c11-nd-thread-kompiled $(DIST_DIR)

$(DIST_DIR)/lib/libc.so: $(DIST_DIR)/c11-translation-kompiled/c11-translation-kompiled/def.cmx $(wildcard $(LIBC_DIR)/src/*) $(SCRIPTS_DIR)/kcc
	@echo "Translating the standard library... ($(LIBC_DIR))"
	$(DIST_DIR)/kcc -s -shared -o $(DIST_DIR)/lib/libc.so $(wildcard $(LIBC_DIR)/src/*.c) $(KCCFLAGS) -I $(LIBC_DIR)/src/
	@echo "Done."

$(DIST_DIR): test-build $(DIST_DIR)/c11-nd-kompiled/c11-nd-kompiled/def.cmx $(DIST_DIR)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.cmx

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

translation-semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions.k
	@$(MAKE) -C $(SEMANTICS_DIR) translation

execution-semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions.k
	@$(MAKE) -C $(SEMANTICS_DIR) execution

$(SEMANTICS_DIR)/settings.k:
	@diff $(LIBC_DIR)/semantics/settings.k $(SEMANTICS_DIR)/settings.k > /dev/null 2>&1 || cp $(LIBC_DIR)/semantics/settings.k $(SEMANTICS_DIR)

$(SEMANTICS_DIR)/extensions.k:
	@diff $(LIBC_DIR)/semantics/extensions.k $(SEMANTICS_DIR)/extensions.k > /dev/null 2>&1 || cp $(LIBC_DIR)/semantics/extensions.k $(SEMANTICS_DIR)

semantics: check-vars $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions.k
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
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre $(SEMANTICS_DIR)/settings.k $(SEMANTICS_DIR)/extensions.k

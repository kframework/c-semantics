SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
CPPPARSER_DIR = clang-tools
export PROFILE_DIR = $(shell pwd)/x86-gcc-limited-libc
export PROFILE = $(shell basename $(PROFILE_DIR))
export SUBPROFILE_DIRS =
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = 
PASS_TESTS_DIR = tests/unit-pass
FAIL_TESTS_DIR = tests/unit-fail
FAIL_COMPILE_TESTS_DIR = tests/unit-fail-compilation

FILES_TO_DIST = \
	$(SCRIPTS_DIR)/kcc \
	$(SCRIPTS_DIR)/k++ \
	$(SCRIPTS_DIR)/kranlib \
	$(SCRIPTS_DIR)/merge-kcc-obj \
	$(SCRIPTS_DIR)/split-kcc-obj \
	$(SCRIPTS_DIR)/make-trampolines \
	$(SCRIPTS_DIR)/make-symbols \
	$(SCRIPTS_DIR)/gccsymdump \
	$(SCRIPTS_DIR)/globalize-syms \
	$(SCRIPTS_DIR)/ignored-flags \
	$(SCRIPTS_DIR)/program-runner \
	$(SCRIPTS_DIR)/histogram-csv \
	$(PARSER_DIR)/cparser \
	$(CPPPARSER_DIR)/clang-kast \
	$(CPPPARSER_DIR)/call-sites \
	$(SCRIPTS_DIR)/cdecl-3.6/src/cdecl \
	LICENSE \
	licenses

PERL_MODULES = \
	$(SCRIPTS_DIR)/RV_Kcc/Opts.pm \
	$(SCRIPTS_DIR)/RV_Kcc/Files.pm \
	$(SCRIPTS_DIR)/RV_Kcc/Shell.pm

DIST_PROFILES = $(DIST_DIR)/profiles
LIBC_SO = $(DIST_PROFILES)/$(PROFILE)/lib/libc.so
LIBSTDCXX_SO = $(DIST_PROFILES)/$(PROFILE)/lib/libstdc++.so

define timestamp_of
    $(DIST_PROFILES)/$(PROFILE)/$(1)-kompiled/$(1)-kompiled/timestamp
endef

.PHONY: default check-vars semantics clean fast cpp-semantics translation-semantics execution-semantics test-build pass fail fail-compile parser/cparser $(CPPPARSER_DIR)/clang-kast $(PROFILE)-native-server

default: test-build

fast: $(LIBC_SO) $(LIBSTDCXX_SO) $(call timestamp_of,c11-cpp14)

check-vars:
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then if ! clang -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc or clang installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi fi
	@if ! kompile --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have kompile installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! krun --version > /dev/null 2>&1; then echo "ERROR: You don't seem to have krun installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/writelong: $(SCRIPTS_DIR)/writelong.c
	@mkdir -p $(DIST_DIR)
	@$(CC) $(SCRIPTS_DIR)/writelong.c -o $(DIST_DIR)/writelong

$(DIST_DIR)/kcc: $(SCRIPTS_DIR)/getopt.pl $(PERL_MODULES) $(DIST_DIR)/writelong $(FILES_TO_DIST)
	mkdir -p $(DIST_DIR)/RV_Kcc
	cp -RLp $(FILES_TO_DIST) $(DIST_DIR)
	cp -RLp $(PERL_MODULES) $(DIST_DIR)/RV_Kcc
	rm -f $(DIST_DIR)/RV_Kcc/Opts.pm
	cat $(SCRIPTS_DIR)/RV_Kcc/Opts.pm | perl $(SCRIPTS_DIR)/getopt.pl > $(DIST_DIR)/RV_Kcc/Opts.pm
	cp -p $(DIST_DIR)/kcc $(DIST_DIR)/kclang

.PHONY: pack
.INTERMEDIATE: $(DIST_DIR)/kcc.packed $(DIST_DIR)/packlists $(DIST_DIR)/fatpacker.trace
pack: $(DIST_DIR)/kcc
	cd $(DIST_DIR) && fatpack trace kcc
	cd $(DIST_DIR) && fatpack packlists-for `cat fatpacker.trace` >packlists
	cat $(DIST_DIR)/packlists
	cd $(DIST_DIR) && fatpack tree `cat packlists`
	cp -rf $(DIST_DIR)/RV_Kcc $(DIST_DIR)/fatlib
	cd $(DIST_DIR) && fatpack file kcc > kcc.packed
	chmod --reference=$(DIST_DIR)/kcc $(DIST_DIR)/kcc.packed
	mv -f $(DIST_DIR)/kcc.packed $(DIST_DIR)/kcc
	cp -pf $(DIST_DIR)/kcc $(DIST_DIR)/kclang
	rm -rf $(DIST_DIR)/fatlib
	rm -rf $(DIST_DIR)/RV_Kcc

$(DIST_PROFILES)/$(PROFILE): $(DIST_DIR)/kcc $(wildcard $(PROFILE_DIR)/include/* $(PROFILE_DIR)/pp $(PROFILE_DIR)/cpp-pp) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/include/*) $(d)/pp $(d)/cpp-pp) $(PROFILE)-native-server | check-vars
	@mkdir -p $(DIST_PROFILES)/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > $(DIST_DIR)/current-profile
	@printf "%s" $(PROFILE) > $(DIST_DIR)/default-profile
	@cp -Lp $(PROFILE_DIR)/pp $(DIST_PROFILES)/$(PROFILE)
	@-cp -Lp $(PROFILE_DIR)/cpp-pp $(DIST_PROFILES)/$(PROFILE)
	@cp -RLp $(PROFILE_DIR)/include $(DIST_PROFILES)/$(PROFILE)
	@cp -RLp $(PROFILE_DIR)/src $(DIST_PROFILES)/$(PROFILE)
	@if [ -d "$(PROFILE_DIR)/native" ]; then cp -RLp $(PROFILE_DIR)/native $(DIST_PROFILES)/$(PROFILE); fi
	@cp -RLp $(PROFILE_DIR)/compiler-src $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		mkdir -p $(DIST_PROFILES)/$(shell basename $(d))/lib)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -Lp $(d)/pp $(DIST_PROFILES)/$(shell basename $(d)))
	@-$(foreach d,$(SUBPROFILE_DIRS), \
		cp -Lp $(d)/cpp-pp $(DIST_PROFILES)/$(shell basename $(d)))
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(d)/include $(DIST_PROFILES)/$(shell basename $(d)))
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(d)/src $(DIST_PROFILES)/$(shell basename $(d)))
	@$(foreach d,$(SUBPROFILE_DIRS), \
		if [ -d "$(d)/native" ]; then cp -RLp $(d)/native $(DIST_PROFILES)/$(shell basename $(d)); fi)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(d)/compiler-src $(DIST_PROFILES)/$(shell basename $(d)))

$(PROFILE_DIR)/cpp-pp:

$(call timestamp_of,c11-cpp14): execution-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/build/$(PROFILE)/c11-cpp14-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/build/$(PROFILE)/c11-cpp14-kompiled $(DIST_PROFILES)/$(shell basename $(d)))

$(call timestamp_of,c11-translation): translation-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/build/$(PROFILE)/c11-translation-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/build/$(PROFILE)/c11-translation-kompiled $(DIST_PROFILES)/$(shell basename $(d)))

$(call timestamp_of,cpp14-translation): cpp-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/build/$(PROFILE)/cpp14-translation-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/build/$(PROFILE)/cpp14-translation-kompiled $(DIST_PROFILES)/$(shell basename $(d)))

$(LIBSTDCXX_SO): $(call timestamp_of,cpp14-translation) $(wildcard $(PROFILE_DIR)/compiler-src/*.C) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/compiler-src/*)) $(DIST_PROFILES)/$(PROFILE)
	@echo "$(PROFILE): Translating the C++ standard library..."
	@cd $(PROFILE_DIR)/compiler-src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(PROFILE) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(LIBSTDCXX_SO) *.C $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/compiler-src && \
		$(shell pwd)/$(DIST_DIR)/kcc --use-profile $(shell basename $(d)) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(DIST_PROFILES)/$(shell basename $(d))/lib/libstdc++.so *.C $(KCCFLAGS) -I .)
	@echo "$(PROFILE): Done translating the C++ standard library."

$(LIBC_SO): $(call timestamp_of,cpp14-translation) $(call timestamp_of,c11-translation) $(wildcard $(PROFILE_DIR)/native/*.c) $(wildcard $(PROFILE_DIR)/src/*.c) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/native/*.c)) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/src/*.c)) $(DIST_PROFILES)/$(PROFILE)
	@echo "$(PROFILE): Translating the C standard library..."
	@if [ -d "$(PROFILE_DIR)/native" ]; \
		then cd $(PROFILE_DIR)/native && $(CC) -c *.c -I . && cd $(PROFILE_DIR)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(PROFILE) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(LIBC_SO) *.c $(PROFILE_DIR)/native/*.o $(KCCFLAGS) -I .; \
		else cd $(PROFILE_DIR)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(PROFILE) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(LIBC_SO) *.c $(KCCFLAGS) -I .; fi
	@$(foreach d,$(SUBPROFILE_DIRS), \
		if [ -d "$(d)/native" ]; \
			then cd $(d)/native && $(CC) -c *.c -I . && cd $(d)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(shell basename $(d)) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(DIST_PROFILES)/$(shell basename $(d))/lib/libc.so *.c $(d)/native/*.o $(KCCFLAGS) -I .; \
			else cd $(d)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(shell basename $(d)) -nodefaultlibs -Xbuiltins -fno-native-compilation -fnative-binary -shared -o $(shell pwd)/$(DIST_PROFILES)/$(shell basename $(d))/lib/libc.so *.c $(KCCFLAGS) -I .; fi)
	@echo "$(PROFILE): Done translating the C standard library."

$(PROFILE)-native-server: $(DIST_PROFILES)/$(PROFILE)/native-server/main.o $(DIST_PROFILES)/$(PROFILE)/native-server/server.c $(DIST_PROFILES)/$(PROFILE)/native-server/platform.o $(DIST_PROFILES)/$(PROFILE)/native-server/platform.h $(DIST_PROFILES)/$(PROFILE)/native-server/server.h

$(DIST_PROFILES)/$(PROFILE)/native-server/main.o: native-server/main.c native-server/server.h
	mkdir -p $(dir $@)
	gcc -c $< -o $@ -Wall -Wextra -pedantic -Werror -g
$(DIST_PROFILES)/$(PROFILE)/native-server/%.h: native-server/%.h
	mkdir -p $(dir $@)
	cp -RLp $< $@
$(DIST_PROFILES)/$(PROFILE)/native-server/server.c: native-server/server.c
	mkdir -p $(dir $@)
	cp -RLp $< $@
$(DIST_PROFILES)/$(PROFILE)/native-server/platform.o: $(PROFILE_DIR)/native-server/platform.c native-server/platform.h
	mkdir -p $(dir $@)
	gcc -c $< -o $@ -Wall -Wextra -pedantic -Werror -I native-server -g

test-build: fast
	@echo "Testing kcc..."
	printf "#include <stdio.h>\nint main(void) {printf(\"x\"); return 42;}\n" | $(DIST_DIR)/kcc --use-profile $(PROFILE) -x c - -o $(DIST_DIR)/testProgram.compiled
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

$(CPPPARSER_DIR)/call-sites: $(CPPPARSER_DIR)/clang-kast

$(CPPPARSER_DIR)/clang-kast: $(CPPPARSER_DIR)/Makefile
	@echo "Building the C++ parser..."
	@$(MAKE) -C $(CPPPARSER_DIR)

$(CPPPARSER_DIR)/Makefile:
	@cd $(CPPPARSER_DIR) && cmake .

scripts/cdecl-%/src/cdecl: scripts/cdecl-%.tar.gz
	flock -n $< sh -c 'cd scripts && tar xvf cdecl-$*.tar.gz && cd cdecl-$* && ./configure --without-readline && $(MAKE)' || true

translation-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) translation

execution-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) execution

cpp-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) cpp

semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) all

check:	pass fail fail-compile

pass:	test-build
	@$(MAKE) -C $(PASS_TESTS_DIR) c-comparison

fail:	test-build
	@$(MAKE) -C $(FAIL_TESTS_DIR) c-comparison

fail-compile:	test-build
	@$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) c-comparison

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(CPPPARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	-$(MAKE) -C $(PASS_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) clean
	@-rm -rf $(DIST_DIR)
	@-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre 

BUILD_DIR = $(CURDIR)/.build
K_SUBMODULE = $(BUILD_DIR)/k
export K_OPTS := -Xmx8g -Xss32m
export K_BIN ?= $(K_SUBMODULE)/k-distribution/target/release/k/bin
export KOMPILE = $(K_BIN)/kompile -O2
export KDEP = $(K_BIN)/kdep

SEMANTICS_DIR = semantics
SCRIPTS_DIR = scripts
PARSER_DIR = parser
CPPPARSER_DIR = clang-tools
export PROFILE_DIR = $(shell pwd)/profiles/x86-gcc-limited-libc
export PROFILE = $(shell basename $(PROFILE_DIR))
export SUBPROFILE_DIRS =
TESTS_DIR = tests
PARSER = $(PARSER_DIR)/cparser
DIST_DIR = dist
KCCFLAGS = -D_POSIX_C_SOURCE=200809 -nodefaultlibs -fno-native-compilation
CFLAGS = -std=gnu11 -Wall -Wextra -Werror -pedantic
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

PROFILE_FILES = include src compiler-src native pp cpp-pp cc cxx
PROFILE_FILE_DEPS = $(foreach f, $(PROFILE_FILES), $(PROFILE_DIR)/$(f))
SUBPROFILE_FILE_DEPS = $(foreach d, $(SUBPROFILE_DIRS), $(foreach f, $(PROFILE_FILES), $(d)/$(f)))

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

.PHONY: default check-vars semantics clean stdlibs deps cpp-semantics translation-semantics execution-semantics test-build pass fail fail-compile parser/cparser $(CPPPARSER_DIR)/clang-kast $(PROFILE)-native

default: test-build

deps: $(K_BIN)/kompile

$(K_BIN)/kompile:
	@echo "== submodule: $@"
	git submodule update --init -- $(K_SUBMODULE)
	cd $(K_SUBMODULE) \
		&& mvn package -q -DskipTests -U
	touch $(K_SUBMODULE)/make.timestamp

check-vars: deps
	@if ! ocaml -version > /dev/null 2>&1; then echo "ERROR: You don't seem to have ocaml installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi
	@if ! gcc -v > /dev/null 2>&1; then if ! clang -v > /dev/null 2>&1; then echo "ERROR: You don't seem to have gcc or clang installed.  You need to install this before continuing.  Please see INSTALL.md for more information."; false; fi fi
	@perl $(SCRIPTS_DIR)/checkForModules.pl

$(DIST_DIR)/writelong: $(SCRIPTS_DIR)/writelong.c
	@mkdir -p $(DIST_DIR)
	@gcc $(CFLAGS) $(SCRIPTS_DIR)/writelong.c -o $(DIST_DIR)/writelong

$(DIST_DIR)/kcc: $(SCRIPTS_DIR)/getopt.pl $(PERL_MODULES) $(DIST_DIR)/writelong $(FILES_TO_DIST)
	mkdir -p $(DIST_DIR)/RV_Kcc
	cp -RLp $(FILES_TO_DIST) $(DIST_DIR)
	cp -RLp $(PERL_MODULES) $(DIST_DIR)/RV_Kcc
	rm -f $(DIST_DIR)/RV_Kcc/Opts.pm
	cat $(SCRIPTS_DIR)/RV_Kcc/Opts.pm | perl $(SCRIPTS_DIR)/getopt.pl > $(DIST_DIR)/RV_Kcc/Opts.pm
	cp -p $(DIST_DIR)/kcc $(DIST_DIR)/kclang

.PHONY: pack
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
	rm -rf $(DIST_DIR)/fatlib $(DIST_DIR)/RV_Kcc $(DIST_DIR)/packlists $(DIST_DIR)/fatpacker.trace

$(DIST_PROFILES)/$(PROFILE): $(DIST_DIR)/kcc $(PROFILE_FILE_DEPS) $(SUBPROFILE_FILE_DEPS) $(PROFILE)-native | check-vars
	@mkdir -p $(DIST_PROFILES)/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > $(DIST_DIR)/current-profile
	@printf "%s" $(PROFILE) > $(DIST_DIR)/default-profile
	@-$(foreach f, $(PROFILE_FILE_DEPS), \
		cp -RLp $(f) $(DIST_PROFILES)/$(PROFILE);)
	@$(foreach d, $(SUBPROFILE_DIRS), \
		mkdir -p $(DIST_PROFILES)/$(shell basename $(d))/lib;)
	@-$(foreach d, $(SUBPROFILE_DIRS), $(foreach f, $(PROFILE_FILES), \
		cp -RLp $(d)/$(f) $(DIST_PROFILES)/$(shell basename $(d))/$(f);))
	@-$(foreach d, $(SUBPROFILE_DIRS), \
		cp -RLp $(DIST_PROFILES)/$(PROFILE)/native/* $(DIST_PROFILES)/$(shell basename $(d))/native;)

$(call timestamp_of,c11-cpp14): execution-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-cpp14-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-cpp14-kompiled $(DIST_PROFILES)/$(shell basename $(d));)

$(call timestamp_of,c11-cpp14-linking): linking-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-cpp14-linking-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-cpp14-linking-kompiled $(DIST_PROFILES)/$(shell basename $(d));)

$(call timestamp_of,c11-translation): translation-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-translation-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/.build/$(PROFILE)/c11-translation-kompiled $(DIST_PROFILES)/$(shell basename $(d));)

$(call timestamp_of,cpp14-translation): cpp-semantics $(DIST_PROFILES)/$(PROFILE)
	@cp -p -RL $(SEMANTICS_DIR)/.build/$(PROFILE)/cpp14-translation-kompiled $(DIST_PROFILES)/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_DIR)/.build/$(PROFILE)/cpp14-translation-kompiled $(DIST_PROFILES)/$(shell basename $(d));)

$(LIBSTDCXX_SO): $(call timestamp_of,c11-cpp14-linking) $(call timestamp_of,cpp14-translation) $(wildcard $(PROFILE_DIR)/compiler-src/*.C) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/compiler-src/*)) $(DIST_PROFILES)/$(PROFILE)
	@echo "$(PROFILE): Translating the C++ standard library..."
	@cd $(PROFILE_DIR)/compiler-src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(PROFILE) -shared -o $(shell pwd)/$(LIBSTDCXX_SO) *.C $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/compiler-src && \
		$(shell pwd)/$(DIST_DIR)/kcc --use-profile $(shell basename $(d)) -shared -o $(shell pwd)/$(DIST_PROFILES)/$(shell basename $(d))/lib/libstdc++.so *.C $(KCCFLAGS) -I .;)
	@echo "$(PROFILE): Done translating the C++ standard library."

$(LIBC_SO): $(call timestamp_of,c11-cpp14-linking) $(call timestamp_of,c11-translation) $(wildcard $(PROFILE_DIR)/src/*.c) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/src/*.c)) $(DIST_PROFILES)/$(PROFILE)
	@echo "$(PROFILE): Translating the C standard library..."
	@cd $(PROFILE_DIR)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(PROFILE) -shared -o $(shell pwd)/$(LIBC_SO) *.c $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/src && $(shell pwd)/$(DIST_DIR)/kcc --use-profile $(shell basename $(d)) -shared -o $(shell pwd)/$(DIST_PROFILES)/$(shell basename $(d))/lib/libc.so *.c $(KCCFLAGS) -I .)
	@echo "$(PROFILE): Done translating the C standard library."

$(PROFILE)-native: $(DIST_PROFILES)/$(PROFILE)/native/main.o $(DIST_PROFILES)/$(PROFILE)/native/server.c $(DIST_PROFILES)/$(PROFILE)/native/builtins.o $(DIST_PROFILES)/$(PROFILE)/native/platform.o $(DIST_PROFILES)/$(PROFILE)/native/platform.h $(DIST_PROFILES)/$(PROFILE)/native/server.h

$(DIST_PROFILES)/$(PROFILE)/native/main.o: native-server/main.c native-server/server.h
	mkdir -p $(dir $@)
	gcc $(CFLAGS) -c $< -o $@  -g
$(DIST_PROFILES)/$(PROFILE)/native/%.h: native-server/%.h
	mkdir -p $(dir $@)
	cp -RLp $< $@
$(DIST_PROFILES)/$(PROFILE)/native/server.c: native-server/server.c
	mkdir -p $(dir $@)
	cp -RLp $< $@
$(DIST_PROFILES)/$(PROFILE)/native/%.o: $(PROFILE_DIR)/native/%.c $(wildcard native-server/*.h)
	mkdir -p $(dir $@)
	gcc $(CFLAGS) -c $< -o $@ -I native-server

stdlibs: $(LIBC_SO) $(LIBSTDCXX_SO) $(call timestamp_of,c11-cpp14)

test-build: stdlibs
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

$(SCRIPTS_DIR)/cdecl-%/src/cdecl: $(SCRIPTS_DIR)/cdecl-%.tar.gz
	flock -w 120 $< sh -c 'cd scripts && tar xvf cdecl-$*.tar.gz && cd cdecl-$* && ./configure --without-readline && $(MAKE)' || true

translation-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) translation

linking-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) linking

execution-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) execution

cpp-semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) cpp

semantics: check-vars
	@$(MAKE) -C $(SEMANTICS_DIR) all

check:	pass fail fail-compile

pass:	test-build
	@$(MAKE) -C $(PASS_TESTS_DIR) comparison

fail:	test-build
	@$(MAKE) -C $(FAIL_TESTS_DIR) comparison

fail-compile:	test-build
	@$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) comparison

os-check:	test-build
	@$(MAKE) -C $(PASS_TESTS_DIR) os-comparison

clean:
	-$(MAKE) -C $(PARSER_DIR) clean
	-$(MAKE) -C $(CPPPARSER_DIR) clean
	-$(MAKE) -C $(SEMANTICS_DIR) clean
	-$(MAKE) -C $(TESTS_DIR) clean
	-$(MAKE) -C $(PASS_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_TESTS_DIR) clean
	-$(MAKE) -C $(FAIL_COMPILE_TESTS_DIR) clean
	-rm -f $(K_SUBMODULE)/make.timestamp
	-rm -rf $(DIST_DIR)
	-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre 

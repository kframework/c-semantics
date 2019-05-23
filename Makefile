# Irrespective of where this is invoked from.
C_SEMANTICS_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))


# Default values.
_K_ROOT := $(C_SEMANTICS_ROOT)/.build/k
_PROFILE_DIR := $(C_SEMANTICS_ROOT)/profiles/x86-gcc-limited-libc

# Overridable by the environment.
K_ROOT ?= $(_K_ROOT)
export PROFILE_DIR ?= $(_PROFILE_DIR)
SUBPROFILE_DIRS ?= 

# Protected from the environment.
export K_OPTS := -Xmx8g -Xss32m
export K_DISTRIBUTION := $(K_ROOT)/k-distribution/target/release/k
export K_BIN := $(K_DISTRIBUTION)/bin
export KOMPILE := $(K_BIN)/kompile -O2
export KDEP := $(K_BIN)/kdep
export PROFILE := $(notdir $(PROFILE_DIR))

KCCFLAGS := -D_POSIX_C_SOURCE=200809 -nodefaultlibs -fno-native-compilation
CFLAGS := -std=gnu11 -Wall -Wextra -Werror -pedantic
CC := $(PROFILE_DIR)/cc


FILES_TO_DIST = \
	scripts/kcc \
	scripts/k++ \
	scripts/kranlib \
	scripts/merge-kcc-obj \
	scripts/split-kcc-obj \
	scripts/make-trampolines \
	scripts/make-symbols \
	scripts/gccsymdump \
	scripts/globalize-syms \
	scripts/ignored-flags \
	scripts/program-runner \
	scripts/histogram-csv \
	parser/cparser \
	clang-tools/clang-kast \
	clang-tools/call-sites \
	scripts/cdecl-3.6/src/cdecl \
	$(K_DISTRIBUTION) \
	LICENSE \
	licenses


PROFILE_FILES := include src compiler-src native pp cpp-pp cc cxx
PROFILE_FILE_DEPS := $(foreach f, $(PROFILE_FILES), $(PROFILE_DIR)/$(f))
SUBPROFILE_FILE_DEPS := $(foreach d, $(SUBPROFILE_DIRS), $(foreach f, $(PROFILE_FILES), $(d)/$(f)))

PERL_MODULES = \
	scripts/RV_Kcc/Opts.pm \
	scripts/RV_Kcc/Files.pm \
	scripts/RV_Kcc/Shell.pm

LIBC_SO = dist/profiles/$(PROFILE)/lib/libc.so
LIBSTDCXX_SO = dist/profiles/$(PROFILE)/lib/libstdc++.so

define timestamp_of
    dist/profiles/$(PROFILE)/$(1)-kompiled/$(1)-kompiled/timestamp
endef

.PHONY: default check-vars semantics clean stdlibs c-cpp-semantics test-build pass fail fail-compile parser/cparser clang-tools/clang-kast $(PROFILE)-native

default: test-build

$(K_ROOT)/pom.xml:
	@echo "== submodule: $@"
	git submodule update --init -- $(K_ROOT)

$(K_DISTRIBUTION): $(K_ROOT)/pom.xml
	cd $(K_ROOT) \
		&& mvn package -q -Dhaskell.backend.skip -Dllvm.backend.skip -DskipTests -U

$(K_BIN)/kompile: $(K_DISTRIBUTION)

ocaml-deps: $(K_ROOT)/pom.xml
	$(K_ROOT)/k-distribution/src/main/scripts/bin/k-configure-opam-dev

check-vars: $(K_BIN)/kompile check-ocaml check-cc check-perl

check-ocaml:
	@ocaml -version > /dev/null 2>&1 || { \
		echo "ERROR: Missing OCaml installation. Please see INSTALL.md for more information." \
		&& false; \
	}	

check-cc:
	@$(CC) -v > /dev/null 2>&1 || \
		clang -v > /dev/null 2>&1 || { \
			echo "ERROR: Missing GCC/Clang installation. Please see INSTALL.md for more information." \
			&& false; \
		}

check-perl:
	@perl scripts/checkForModules.pl

dist/writelong: scripts/writelong.c
	@mkdir -p dist
	@$(CC) $(CFLAGS) scripts/writelong.c -o dist/writelong

dist/extract-references: scripts/extract-references.cpp
	@mkdir -p dist
	@echo Building $@
	@$(CXX) -std=c++17 $< -lstdc++fs -o $@

dist/kcc: scripts/getopt.pl $(PERL_MODULES) dist/writelong $(FILES_TO_DIST)
	mkdir -p dist/RV_Kcc
	cp -RLp $(FILES_TO_DIST) dist
	cp -RLp $(PERL_MODULES) dist/RV_Kcc
	rm -f dist/RV_Kcc/Opts.pm
	cat scripts/RV_Kcc/Opts.pm | perl scripts/getopt.pl > dist/RV_Kcc/Opts.pm
	cp -p dist/kcc dist/kclang

.PHONY: pack
pack: dist/kcc
	cd dist && fatpack trace kcc
	cd dist && fatpack packlists-for `cat fatpacker.trace` >packlists
	cat dist/packlists
	cd dist && fatpack tree `cat packlists`
	cp -rf dist/RV_Kcc dist/fatlib
	cd dist && fatpack file kcc > kcc.packed
	chmod --reference=dist/kcc dist/kcc.packed
	mv -f dist/kcc.packed dist/kcc
	cp -pf dist/kcc dist/kclang
	rm -rf dist/fatlib dist/RV_Kcc dist/packlists dist/fatpacker.trace

dist/profiles/$(PROFILE): dist/kcc $(PROFILE_FILE_DEPS) $(SUBPROFILE_FILE_DEPS) $(PROFILE)-native | check-vars
	@mkdir -p dist/profiles/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > dist/current-profile
	@printf "%s" $(PROFILE) > dist/default-profile
	@-$(foreach f, $(PROFILE_FILE_DEPS), \
		cp -RLp $(f) dist/profiles/$(PROFILE);)
	@$(foreach d, $(SUBPROFILE_DIRS), \
		mkdir -p dist/profiles/$(shell basename $(d))/lib;)
	@-$(foreach d, $(SUBPROFILE_DIRS), $(foreach f, $(PROFILE_FILES), \
		cp -RLp $(d)/$(f) dist/profiles/$(shell basename $(d))/$(f);))
	@-$(foreach d, $(SUBPROFILE_DIRS), \
		cp -RLp dist/profiles/$(PROFILE)/native/* dist/profiles/$(shell basename $(d))/native;)

.SECONDEXPANSION:
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*)
# the % sign matches to '$(NAME)-kompiled/$(NAME)',
# e.g. to 'c-cpp-kompiled/c-cpp'
#dist/profiles/$(PROFILE)/c-cpp-kompiled/c-cpp-kompiled/timestamp
dist/profiles/$(PROFILE)/%-kompiled/timestamp: dist/profiles/$(PROFILE) $$(notdir $$*)-semantics
	$(eval NAME := $(notdir $*))
	@echo "Distributing $(NAME)"
	@cp -p -RL semantics/.build/$(PROFILE)/$(NAME)-kompiled dist/profiles/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp semantics/.build/$(PROFILE)/$(NAME)-kompiled dist/profiles/$(shell basename $(d));)

$(LIBSTDCXX_SO): $(call timestamp_of,c-cpp-linking) $(call timestamp_of,cpp-translation) $(wildcard $(PROFILE_DIR)/compiler-src/*.C) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/compiler-src/*)) dist/profiles/$(PROFILE)
	@echo "$(PROFILE): Translating the C++ standard library..."
	@cd $(PROFILE_DIR)/compiler-src && $(shell pwd)/dist/kcc --use-profile $(PROFILE) -shared -o $(shell pwd)/$@ *.C $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/compiler-src && \
		$(shell pwd)/dist/kcc --use-profile $(shell basename $(d)) -shared -o $(shell pwd)/dist/profiles/$(shell basename $(d))/lib/libstdc++.so *.C $(KCCFLAGS) -I .;)
	@echo "$(PROFILE): Done translating the C++ standard library."

$(LIBC_SO): $(call timestamp_of,c-cpp-linking) $(call timestamp_of,c-translation) $(wildcard $(PROFILE_DIR)/src/*.c) $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/src/*.c)) dist/profiles/$(PROFILE)
	@echo "$(PROFILE): Translating the C standard library..."
	@cd $(PROFILE_DIR)/src && $(shell pwd)/dist/kcc --use-profile $(PROFILE) -shared -o $(shell pwd)/$@ *.c $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/src && $(shell pwd)/dist/kcc --use-profile $(shell basename $(d)) -shared -o $(shell pwd)/dist/profiles/$(shell basename $(d))/lib/libc.so *.c $(KCCFLAGS) -I .)
	@echo "$(PROFILE): Done translating the C standard library."

$(PROFILE)-native: dist/profiles/$(PROFILE)/native/main.o dist/profiles/$(PROFILE)/native/server.c dist/profiles/$(PROFILE)/native/builtins.o dist/profiles/$(PROFILE)/native/platform.o dist/profiles/$(PROFILE)/native/platform.h dist/profiles/$(PROFILE)/native/server.h

dist/profiles/$(PROFILE)/native/main.o: native-server/main.c native-server/server.h
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@  -g
dist/profiles/$(PROFILE)/native/%.h: native-server/%.h
	mkdir -p $(dir $@)
	cp -RLp $< $@
dist/profiles/$(PROFILE)/native/server.c: native-server/server.c
	mkdir -p $(dir $@)
	cp -RLp $< $@
dist/profiles/$(PROFILE)/native/%.o: $(PROFILE_DIR)/native/%.c $(wildcard native-server/*.h)
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@ -I native-server

stdlibs: $(LIBC_SO) $(LIBSTDCXX_SO) $(call timestamp_of,c-cpp)

test-build: stdlibs
	@echo "Testing kcc..."
	printf "#include <stdio.h>\nint main(void) {printf(\"x\"); return 42;}\n" | dist/kcc --use-profile $(PROFILE) -x c - -o dist/testProgram.compiled
	dist/testProgram.compiled 2> /dev/null > dist/testProgram.out; test $$? -eq 42
	grep x dist/testProgram.out > /dev/null
	@echo "Done."
	@echo "Cleaning up..."
	@rm -f dist/testProgram.compiled
	@rm -f dist/testProgram.out
	@echo "Done."

parser/cparser:
	@echo "Building the C parser..."
	@$(MAKE) -C parser

clang-tools/call-sites: clang-tools/clang-kast

clang-tools/clang-kast: clang-tools/Makefile
	@echo "Building the C++ parser..."
	@$(MAKE) -C clang-tools

clang-tools/Makefile:
	@cd clang-tools && cmake .

scripts/cdecl-%/src/cdecl: scripts/cdecl-%.tar.gz
	flock -w 120 $< sh -c 'cd scripts && tar xvf cdecl-$*.tar.gz && cd cdecl-$* && ./configure --without-readline && $(MAKE)' || true

# compatability targets
# TODO: remove when not used in rv-match build
.PHONY: c-translation-semantics
c-translation-semantics: c-translation-semantics
.PHONY: cpp-translation-semantics
cpp-translation-semantics: cpp-translation-semantics
.PHONY: linking-semantics
linking-semantics: c-cpp-linking-semantics
.PHONY: execution-semantics
execution-semantics: c-cpp-semantics

XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)
.PHONY: $(XYZ_SEMANTICS)
$(XYZ_SEMANTICS): check-vars
	@$(MAKE) -C semantics $@

semantics: check-vars
	@$(MAKE) -C semantics all

check: pass fail fail-compile

pass:	test-build
	@$(MAKE) -C tests/unit-pass comparison

fail:	test-build
	@$(MAKE) -C tests/unit-fail comparison

fail-compile:	test-build
	@$(MAKE) -C tests/unit-fail-compilation comparison

clean:
	-$(MAKE) -C parser clean
	-$(MAKE) -C clang-tools clean
	-$(MAKE) -C semantics clean
	-$(MAKE) -C tests clean
	-$(MAKE) -C tests/unit-pass clean
	-$(MAKE) -C tests/unit-fail clean
	-$(MAKE) -C tests/unit-fail-compilation clean
	-rm -f $(K_ROOT)/make.timestamp
	-rm -rf dist
	-rm -f ./*.tmp ./*.log ./*.cil ./*-gen.maude ./*.gen.maude ./*.pre.gen ./*.prepre.gen ./a.out ./*.kdump ./*.pre.pre 

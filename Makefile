ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

export K_BIN ?= $(ROOT)/.build/k/k-distribution/target/release/k/bin

export K_OPTS := -Xmx8g -Xss32m
export KOMPILE := $(K_BIN)/kompile -O2
export KDEP := $(K_BIN)/kdep

export PROFILE_DIR := $(ROOT)/profiles/x86-gcc-limited-libc

PROFILE := $(shell basename $(PROFILE_DIR))
SUBPROFILE_DIRS :=

# Absolute paths.
OUTPUT_DIR := $(ROOT)/build
SEMANTICS_OUTPUT_DIR := $(OUTPUT_DIR)/semantics/$(PROFILE)

KCCFLAGS := -D_POSIX_C_SOURCE=200809 -nodefaultlibs -fno-native-compilation
CFLAGS := -std=gnu11 -Wall -Wextra -Werror -pedantic
CXXFLAGS := -std=c++17

K_DIST := $(realpath $(K_BIN)/..)

CLANG_TOOLS_BUILD_DIR := $(OUTPUT_DIR)/clang-tools
CLANG_TOOLS_BIN := $(CLANG_TOOLS_BUILD_DIR)/bin

FILES_TO_DIST := \
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
	$(CLANG_TOOLS_BIN)/clang-kast \
	$(CLANG_TOOLS_BIN)/call-sites \
	scripts/cdecl-3.6/src/cdecl \
	$(K_DIST) \
	LICENSE \
	licenses

PROFILE_FILES := include src compiler-src native pp cpp-pp cc cxx
PROFILE_FILE_DEPS := $(foreach f, $(PROFILE_FILES), $(PROFILE_DIR)/$(f))
SUBPROFILE_FILE_DEPS := $(foreach d, $(SUBPROFILE_DIRS), \
                          $(foreach f, $(PROFILE_FILES), $(d)/$(f)))
CC := $(PROFILE_DIR)/cc

PERL_MODULES_DIR := scripts/RV_Kcc
PERL_MODULES := $(wildcard $(PERL_MODULES_DIR)/*.pm)

LIBC_SO := $(OUTPUT_DIR)/profiles/$(PROFILE)/lib/libc.so
LIBSTDCXX_SO := $(OUTPUT_DIR)/profiles/$(PROFILE)/lib/libstdc++.so

define timestamp_of
    $(OUTPUT_DIR)/profiles/$(PROFILE)/$(1)-kompiled/$(1)-kompiled/timestamp
endef


.PHONY: default
default: test-build

.PHONY: check-deps
check-deps: | check-ocaml check-cc check-perl check-k

.PHONY: check-ocaml
check-ocaml:
	@ocaml -version > /dev/null 2>&1 || { \
		echo "ERROR: Missing OCaml installation. Please see INSTALL.md for more information." \
		&& false; \
	}

.PHONY: check-cc
check-cc:
	@$(CC) -v > /dev/null 2>&1 || \
		clang -v > /dev/null 2>&1 || { \
			echo "ERROR: Missing GCC/Clang installation. Please see INSTALL.md for more information." \
			&& false; \
		}

.PHONY: check-perl
check-perl:
	@perl scripts/checkForModules.pl


.PHONY: check-k
check-k:
	@$(K_BIN)/kompile --version > /dev/null 2>&1 || { \
		echo "ERROR: Missing K installation. Please see INSTALL.md for more information." \
		&& false; \
	}

$(OUTPUT_DIR)/writelong: scripts/writelong.c
	@mkdir -p $(OUTPUT_DIR)
	@$(CC) $(CFLAGS) scripts/writelong.c -o $(OUTPUT_DIR)/writelong

$(OUTPUT_DIR)/extract-references: scripts/extract-references.cpp
	@mkdir -p $(OUTPUT_DIR)
	$(info Building $@)
	@$(CXX) $(CXXFLAGS) $< -lstdc++fs -o $@

$(OUTPUT_DIR)/kcc: scripts/getopt.pl $(PERL_MODULES) $(OUTPUT_DIR)/writelong $(FILES_TO_DIST)
	mkdir -p $(OUTPUT_DIR)/RV_Kcc
	cp -RLp $(FILES_TO_DIST) $(OUTPUT_DIR)
	cp -RLp $(PERL_MODULES) $(OUTPUT_DIR)/RV_Kcc
	cat scripts/RV_Kcc/Opts.pm | perl scripts/getopt.pl > $(OUTPUT_DIR)/RV_Kcc/Opts.pm
	ln -s $(realpath $(OUTPUT_DIR))/kcc $(realpath $(OUTPUT_DIR))/kclang

.PHONY: pack
pack: $(OUTPUT_DIR)/kcc
	cd $(OUTPUT_DIR) && fatpack trace kcc
	cd $(OUTPUT_DIR) && fatpack packlists-for `cat fatpacker.trace` >packlists
	cat $(OUTPUT_DIR)/packlists
	cd $(OUTPUT_DIR) && fatpack tree `cat packlists`
	cp -rf $(OUTPUT_DIR)/RV_Kcc $(OUTPUT_DIR)/fatlib
	cd $(OUTPUT_DIR) && fatpack file kcc > kcc.packed
	chmod --reference=$(OUTPUT_DIR)/kcc $(OUTPUT_DIR)/kcc.packed
	mv -f $(OUTPUT_DIR)/kcc.packed $(OUTPUT_DIR)/kcc
	cp -pf $(OUTPUT_DIR)/kcc $(OUTPUT_DIR)/kclang
	rm -rf $(OUTPUT_DIR)/fatlib $(OUTPUT_DIR)/RV_Kcc $(OUTPUT_DIR)/packlists $(OUTPUT_DIR)/fatpacker.trace

$(OUTPUT_DIR)/profiles/$(PROFILE): $(OUTPUT_DIR)/kcc $(PROFILE_FILE_DEPS) $(SUBPROFILE_FILE_DEPS) $(PROFILE)-native | check-deps
	@mkdir -p $(OUTPUT_DIR)/profiles/$(PROFILE)/lib
	@printf "%s" $(PROFILE) > $(OUTPUT_DIR)/current-profile
	@printf "%s" $(PROFILE) > $(OUTPUT_DIR)/default-profile
	@-$(foreach f, $(PROFILE_FILE_DEPS), \
		cp -RLp $(f) $(OUTPUT_DIR)/profiles/$(PROFILE);)
	@$(foreach d, $(SUBPROFILE_DIRS), \
		mkdir -p $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib;)
	@-$(foreach d, $(SUBPROFILE_DIRS), \
			$(foreach f, $(PROFILE_FILES), \
				cp -RLp $(d)/$(f) \
				$(OUTPUT_DIR)/profiles/$(shell basename $(d))/$(f);))
	@-$(foreach d, $(SUBPROFILE_DIRS), \
				cp -RLp $(OUTPUT_DIR)/profiles/$(PROFILE)/native/* \
				$(OUTPUT_DIR)/profiles/$(shell basename $(d))/native;)


$(LIBSTDCXX_SO): $(call timestamp_of,c-cpp-linking) \
                 $(call timestamp_of,cpp-translation) \
                 $(wildcard $(PROFILE_DIR)/compiler-src/*.C) \
                 $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/compiler-src/*)) \
                 $(OUTPUT_DIR)/profiles/$(PROFILE)
	$(info $(PROFILE): Translating the C++ standard library...)
	@cd $(PROFILE_DIR)/compiler-src && \
		$(OUTPUT_DIR)/kcc --use-profile $(PROFILE) \
				-shared -o $@ *.C \
				$(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/compiler-src && \
			$(OUTPUT_DIR)/kcc --use-profile $(shell basename $(d)) \
				-shared -o $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib/libstdc++.so \
				*.C $(KCCFLAGS) -I .;)
	$(info $(PROFILE): Done translating the C++ standard library.)


$(LIBC_SO): $(call timestamp_of,c-cpp-linking) \
	          $(call timestamp_of,c-translation) \
	          $(wildcard $(PROFILE_DIR)/src/*.c) \
	          $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/src/*.c)) \
            $(OUTPUT_DIR)/profiles/$(PROFILE)
	$(info $(PROFILE): Translating the C standard library...)
	@cd $(PROFILE_DIR)/src && \
		$(OUTPUT_DIR)/kcc --use-profile $(PROFILE) -shared -o $@ *.c $(KCCFLAGS) -I .
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cd $(d)/src && \
			$(OUTPUT_DIR)/kcc --use-profile $(shell basename $(d)) \
				-shared -o $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib/libc.so \
				*.c $(KCCFLAGS) -I .)
	$(info $(PROFILE): Done translating the C standard library.)


.PHONY: $(PROFILE)-native
$(PROFILE)-native: $(OUTPUT_DIR)/profiles/$(PROFILE)/native/main.o \
                   $(OUTPUT_DIR)/profiles/$(PROFILE)/native/server.c \
                   $(OUTPUT_DIR)/profiles/$(PROFILE)/native/builtins.o \
                   $(OUTPUT_DIR)/profiles/$(PROFILE)/native/platform.o \
                   $(OUTPUT_DIR)/profiles/$(PROFILE)/native/platform.h \
                   $(OUTPUT_DIR)/profiles/$(PROFILE)/native/server.h


$(OUTPUT_DIR)/profiles/$(PROFILE)/native/main.o: native-server/main.c native-server/server.h
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@  -g

$(OUTPUT_DIR)/profiles/$(PROFILE)/native/%.h: native-server/%.h
	mkdir -p $(dir $@)
	cp -RLp $< $@

$(OUTPUT_DIR)/profiles/$(PROFILE)/native/server.c: native-server/server.c
	mkdir -p $(dir $@)
	cp -RLp $< $@

$(OUTPUT_DIR)/profiles/$(PROFILE)/native/%.o: $(PROFILE_DIR)/native/%.c \
                                              $(wildcard native-server/*.h)
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@ -I native-server


.PHONY: test-build
test-build: $(LIBC_SO) \
            $(LIBSTDCXX_SO) \
            $(call timestamp_of,c-cpp)

.PHONY: parser/cparser
parser/cparser:
	$(info Building the C parser...)
	@$(MAKE) -C parser

$(CLANG_TOOLS_BIN)/%: $(CLANG_TOOLS_BUILD_DIR)/Makefile
	@$(MAKE) -C $(CLANG_TOOLS_BUILD_DIR) $*

$(CLANG_TOOLS_BUILD_DIR)/Makefile: clang-tools/CMakeLists.txt
	@mkdir -p $(CLANG_TOOLS_BUILD_DIR)
	@cd $(CLANG_TOOLS_BUILD_DIR) \
		&& test -f Makefile || cmake $(ROOT)/clang-tools

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

.PHONY: semantics
semantics: | check-deps
	@$(MAKE) -C semantics all

.PHONY: check
check: | pass fail fail-compile

.PHONY: pass
pass:	| test-build
	@$(MAKE) -C tests/unit-pass comparison

.PHONY: fail
fail:	| test-build
	@$(MAKE) -C tests/unit-fail comparison

.PHONY: fail-compile
fail-compile:	| test-build
	@$(MAKE) -C tests/unit-fail-compilation comparison


# Intended as a simple test to verify the build.  If you invoke from the
# command line, do not forget to pass `OUTPUT_DIR=<dir>` if you specified one
# during the build.
.PHONY: simple-build-test
simple-build-test:
	$(info Testing kcc...)
	printf "#include <stdio.h>\nint main(void) { printf(\"x\"); return 42; }" \
		| $(OUTPUT_DIR)/kcc --use-profile $(PROFILE) -x c - -o $(OUTPUT_DIR)/testProgram.compiled
	$(OUTPUT_DIR)/testProgram.compiled 2> /dev/null > $(OUTPUT_DIR)/testProgram.out; \
		test $$? -eq 42
	grep x $(OUTPUT_DIR)/testProgram.out > /dev/null 2>&1
	$(info Done.)
	$(info Cleaning up...)
	@rm -f $(OUTPUT_DIR)/testProgram.compiled
	@rm -f $(OUTPUT_DIR)/testProgram.out
	$(info Done.)



.PHONY: clean
clean:
	-$(MAKE) -C parser clean
	-rm -rf $(CLANG_TOOLS_BUILD_DIR)
	-$(MAKE) -C semantics clean
	-$(MAKE) -C tests clean
	-$(MAKE) -C tests/unit-pass clean
	-$(MAKE) -C tests/unit-fail clean
	-$(MAKE) -C tests/unit-fail-compilation clean
	-rm -rf $(OUTPUT_DIR) \
					./*.tmp ./*.log ./*.cil ./*-gen.maude \
					./*.gen.maude ./*.pre.gen ./*.prepre.gen \
					./a.out ./*.kdump ./*.pre.pre 


XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)
.PHONY: $(XYZ_SEMANTICS)

# Move this to the end so that .SECONDEXPANSION does not
# affect the rest of the rules.
.SECONDEXPANSION:
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*) | check-deps
	@$(MAKE) -C semantics $@ OUTPUT_DIR=$(SEMANTICS_OUTPUT_DIR)

# the % sign matches '$(NAME)-kompiled/$(NAME)',
# e.g., c-cpp-kompiled/c-cpp'
$(OUTPUT_DIR)/profiles/$(PROFILE)/%-kompiled/timestamp: $(OUTPUT_DIR)/profiles/$(PROFILE) \
                                                        $$(notdir $$*)-semantics
	$(eval NAME := $(notdir $*))
	$(info Distributing $(NAME))
	@cp -p -RL $(SEMANTICS_OUTPUT_DIR)/$(NAME)-kompiled $(OUTPUT_DIR)/profiles/$(PROFILE)
	@$(foreach d,$(SUBPROFILE_DIRS), \
		cp -RLp $(SEMANTICS_OUTPUT_DIR)/$(NAME)-kompiled $(OUTPUT_DIR)/profiles/$(shell basename $(d));)

ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

export K_BIN ?= $(ROOT)/.build/k/k-distribution/target/release/k/bin

export KOMPILE := $(K_BIN)/kompile
export KDEP := $(K_BIN)/kdep

# Appending to whatever the environment provided.
K_OPTS += -Xmx8g
K_OPTS += -Xss32m
export K_OPTS

PROFILE_DIR := $(ROOT)/profiles/x86-gcc-limited-libc
PROFILE := $(shell basename $(PROFILE_DIR))
SUBPROFILE_DIRS :=

# Default build directory.
# Intended for overriding by the user, see below.
BUILD_DIR := dist

# Build directory used internally.
# `abspath` because the directory does not exist yet.
OUTPUT_DIR := $(abspath $(BUILD_DIR))

PROFILE_OUTPUT_DIR := $(OUTPUT_DIR)/profiles/$(PROFILE)

KCCFLAGS := -D_POSIX_C_SOURCE=200809 -nodefaultlibs -fno-native-compilation

# Appending to whatever the environment provided.
CFLAGS += -std=gnu11
CFLAGS += -Wall
CFLAGS += -Wextra
CFLAGS += -Werror
CFLAGS += -pedantic

# Appending to whatever the environment provided.
# Do not export: `clang-tools` sets these things via `cmake`.
CXXFLAGS += -std=c++17
CXXFLAGS += -Wall
CXXFLAGS += -Wextra
CXXFLAGS += -Werror
CXXFLAGS += -pedantic

export LOGGER := $(ROOT)/scripts/build-logger.sh

CLANG_TOOLS_BUILD_DIR := $(OUTPUT_DIR)/clang-tools
CLANG_TOOLS_BIN := $(CLANG_TOOLS_BUILD_DIR)/bin

PARSER_BUILD_DIR := $(OUTPUT_DIR)/parser
PARSER_BIN := $(PARSER_BUILD_DIR)

CDECL_BUILD_DIR := $(OUTPUT_DIR)/cdecl-3.6
CDECL_BIN := $(CDECL_BUILD_DIR)/src

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
	$(PARSER_BIN)/cparser \
	$(realpath $(K_BIN)/..) \
	$(CLANG_TOOLS_BIN)/clang-kast \
	$(CLANG_TOOLS_BIN)/call-sites \
	$(CDECL_BIN)/cdecl \
	LICENSE \
	licenses

PROFILE_FILES := include src compiler-src native pp cpp-pp cc cxx
PROFILE_FILE_DEPS := $(foreach f, $(PROFILE_FILES), $(PROFILE_DIR)/$(f))
SUBPROFILE_FILE_DEPS := $(foreach d, $(SUBPROFILE_DIRS), \
                        $(foreach f, $(PROFILE_FILES), $(d)/$(f)))

PERL_MODULES := $(wildcard $(ROOT)/scripts/RV_Kcc/*.pm)

LIBC_SO := $(PROFILE_OUTPUT_DIR)/lib/libc.so
LIBSTDCXX_SO := $(PROFILE_OUTPUT_DIR)/lib/libstdc++.so

define timestamp_of
    $(PROFILE_OUTPUT_DIR)/$(1)-kompiled/$(1)-kompiled/timestamp
endef


.PHONY: default
default: test-build

# Targets intended for direct invocation by the user,
# to check the installation of dependencies.
#
# No subsequent targets depend on these.

.PHONY: check-deps
check-deps: | check-ocaml check-cc check-cxx check-perl check-k

.PHONY: check-ocaml
check-ocaml:
	@ocaml -version > /dev/null 2>&1 || { \
		$(LOGGER) "ERROR: Missing OCaml installation. Please see INSTALL.md for more information." \
		&& false; \
	}

.PHONY: check-cc
check-cc:
	@$(CC) -v > /dev/null 2>&1 || { \
		$(LOGGER) "ERROR: Missing C compiler installation. Please see INSTALL.md for more information." \
		&& false; \
	}

.PHONY: check-cxx
check-cxx:
	@$(CXX) -v > /dev/null 2>&1 || { \
		$(LOGGER) "ERROR: Missing C++ compiler installation. Please see INSTALL.md for more information." \
		&& false; \
	}

.PHONY: check-perl
check-perl:
	@export STR="$$(perl scripts/checkForModules.pl)" && test ! -z "$${STR}" && $(LOGGER) "$${STR}"


.PHONY: check-k
check-k:
	@$(KOMPILE) --version > /dev/null 2>&1 || { \
		$(LOGGER) "ERROR: Missing K installation. Please see INSTALL.md for more information." \
		&& false; \
	}


# Real targets.

# We rely on this rule to make
# nonexisting directories.
.DEFAULT: ;@mkdir -p $@


$(OUTPUT_DIR)/writelong: scripts/writelong.c | $(OUTPUT_DIR)
	@$(LOGGER) "Building $@"
	@$(CC) $(CFLAGS) $< -o $@

$(OUTPUT_DIR)/extract-references: scripts/extract-references.cpp | $(OUTPUT_DIR)
	@$(LOGGER) "Building $@"
	@$(CXX) $(CXXFLAGS) $< -lstdc++fs -o $@

$(OUTPUT_DIR)/kcc: scripts/getopt.pl \
                   $(PERL_MODULES) \
                   $(OUTPUT_DIR)/writelong \
                   $(FILES_TO_DIST) \
                   | $(OUTPUT_DIR)/RV_Kcc
	cp -RLp $(FILES_TO_DIST) $(OUTPUT_DIR)
	cp -RLp $(PERL_MODULES) $(OUTPUT_DIR)/RV_Kcc
	cat scripts/RV_Kcc/Opts.pm | perl scripts/getopt.pl > $(OUTPUT_DIR)/RV_Kcc/Opts.pm
	cp -Lp $(OUTPUT_DIR)/kcc $(OUTPUT_DIR)/kclang

.PHONY: pack
pack: FATPACK_COMMAND := PERL5LIB="$(OUTPUT_DIR):$(PERL5LIB)" fatpack
pack: $(OUTPUT_DIR)/kcc
	@$(LOGGER) "Entering target $@"
	cd $(OUTPUT_DIR) \
		&& $(FATPACK_COMMAND) trace kcc
	cd $(OUTPUT_DIR) \
		&& $(FATPACK_COMMAND) packlists-for `cat fatpacker.trace` > packlists
	$(LOGGER) "$$(cat $(OUTPUT_DIR)/packlists)"
	cd $(OUTPUT_DIR) \
		&& $(FATPACK_COMMAND) tree `cat packlists`
	cp -RLp $(OUTPUT_DIR)/RV_Kcc $(OUTPUT_DIR)/fatlib/RV_Kcc
	cd $(OUTPUT_DIR) \
		&& $(FATPACK_COMMAND) file kcc > kcc.packed
	chmod --reference=$(OUTPUT_DIR)/kcc $(OUTPUT_DIR)/kcc.packed
	mv -f $(OUTPUT_DIR)/kcc.packed $(OUTPUT_DIR)/kcc
	cp -Lp $(OUTPUT_DIR)/kcc $(OUTPUT_DIR)/kclang
	rm -rf \
		$(OUTPUT_DIR)/fatlib \
		$(OUTPUT_DIR)/RV_Kcc \
		$(OUTPUT_DIR)/packlists \
		$(OUTPUT_DIR)/fatpacker.trace

.PHONY: PROFILE_DEPS
PROFILE_DEPS: $(OUTPUT_DIR)/kcc \
              $(PROFILE_FILE_DEPS) \
              $(SUBPROFILE_FILE_DEPS) \
              $(PROFILE)-native \
              | $(PROFILE_OUTPUT_DIR)/lib
	@printf "%s" $(PROFILE) > $(OUTPUT_DIR)/current-profile
	@printf "%s" $(PROFILE) > $(OUTPUT_DIR)/default-profile
	@-$(foreach f, $(PROFILE_FILE_DEPS), \
		cp -RLp $(f) $(PROFILE_OUTPUT_DIR);)
	@true $(foreach d, $(SUBPROFILE_DIRS), \
		&& mkdir -p $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib)
	@-$(foreach d, $(SUBPROFILE_DIRS), \
			$(foreach f, $(PROFILE_FILES), \
				cp -RLp $(d)/$(f) \
				$(OUTPUT_DIR)/profiles/$(shell basename $(d))/$(f);))
	@-$(foreach d, $(SUBPROFILE_DIRS), \
				cp -RLp $(PROFILE_OUTPUT_DIR)/native/* \
				$(OUTPUT_DIR)/profiles/$(shell basename $(d))/native;)


$(LIBSTDCXX_SO): $(call timestamp_of,c-cpp-linking) \
                 $(call timestamp_of,cpp-translation) \
                 $(wildcard $(PROFILE_DIR)/compiler-src/*.C) \
                 $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/compiler-src/*)) \
                 PROFILE_DEPS
	@$(LOGGER) "$(PROFILE): Translating the C++ standard library..."
	@cd $(PROFILE_DIR)/compiler-src && \
		$(OUTPUT_DIR)/kcc \
				-Wfatal-errors \
				--use-profile $(PROFILE) \
				-shared -o $@ *.C \
				$(KCCFLAGS) -I .
	@true $(foreach d,$(SUBPROFILE_DIRS), \
		&& cd $(d)/compiler-src && \
			$(OUTPUT_DIR)/kcc \
				-Wfatal-errors \
				--use-profile $(shell basename $(d)) \
				-shared \
				-o $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib/libstdc++.so \
				*.C $(KCCFLAGS) -I .)
	@$(LOGGER) "$(PROFILE): Done translating the C++ standard library."


$(LIBC_SO): $(call timestamp_of,c-cpp-linking) \
            $(call timestamp_of,c-translation) \
            $(wildcard $(PROFILE_DIR)/src/*.c) \
            $(foreach d,$(SUBPROFILE_DIRS),$(wildcard $(d)/src/*.c)) \
            PROFILE_DEPS
	@$(LOGGER) "$(PROFILE): Translating the C standard library..."
	@cd $(PROFILE_DIR)/src && \
		$(OUTPUT_DIR)/kcc \
				-Wfatal-errors \
				--use-profile $(PROFILE) \
				-shared -o $@ *.c \
				$(KCCFLAGS) -I .
	@true $(foreach d,$(SUBPROFILE_DIRS), \
		&& cd $(d)/src && \
			$(OUTPUT_DIR)/kcc \
				-Wfatal-errors \
				--use-profile $(shell basename $(d)) \
				-shared \
				-o $(OUTPUT_DIR)/profiles/$(shell basename $(d))/lib/libc.so \
				*.c $(KCCFLAGS) -I .)
	@$(LOGGER) "$(PROFILE): Done translating the C standard library."


.PHONY: $(PROFILE)-native
$(PROFILE)-native: CC := $(PROFILE_DIR)/cc
$(PROFILE)-native: CXX := $(PROFILE_DIR)/cxx
$(PROFILE)-native: $(PROFILE_OUTPUT_DIR)/native/main.o \
                   $(PROFILE_OUTPUT_DIR)/native/server.c \
                   $(PROFILE_OUTPUT_DIR)/native/builtins.o \
                   $(PROFILE_OUTPUT_DIR)/native/platform.o \
                   $(PROFILE_OUTPUT_DIR)/native/platform.h \
                   $(PROFILE_OUTPUT_DIR)/native/server.h

$(PROFILE_OUTPUT_DIR)/native/main.o: native-server/main.c \
                                     native-server/server.h \
                                     | $(PROFILE_OUTPUT_DIR)/native
	$(CC) $(CFLAGS) -c $< -o $@  -g

$(PROFILE_OUTPUT_DIR)/native/%.h: native-server/%.h \
                                  | $(PROFILE_OUTPUT_DIR)/native
	cp -RLp $< $@

$(PROFILE_OUTPUT_DIR)/native/server.c: native-server/server.c \
                                       | $(PROFILE_OUTPUT_DIR)/native
	cp -RLp $< $@

$(PROFILE_OUTPUT_DIR)/native/%.o: $(PROFILE_DIR)/native/%.c \
                                  $(wildcard native-server/*.h) \
                                  | $(PROFILE_OUTPUT_DIR)/native
	$(CC) $(CFLAGS) -c $< -o $@ -I native-server


.PHONY: test-build
test-build: $(LIBC_SO) \
            $(LIBSTDCXX_SO) \
            $(call timestamp_of,c-cpp)

$(PARSER_BUILD_DIR)/cparser: | $(PARSER_BUILD_DIR)
	@$(LOGGER) "Building the C parser..."
	@cp -RLp parser/* $(PARSER_BUILD_DIR)
	@$(MAKE) -C $(PARSER_BUILD_DIR)

$(CLANG_TOOLS_BIN)/%: $(CLANG_TOOLS_BUILD_DIR)/Makefile
	@$(LOGGER) "Entering target $@"
	@$(MAKE) -C $(CLANG_TOOLS_BUILD_DIR) $*

$(CLANG_TOOLS_BUILD_DIR)/Makefile: clang-tools/CMakeLists.txt | $(CLANG_TOOLS_BUILD_DIR)
	@$(LOGGER) "Entering target $@"
	@cd $(CLANG_TOOLS_BUILD_DIR) \
		&& test -f Makefile || cmake $(ROOT)/clang-tools

$(CDECL_BUILD_DIR)/Makefile.in: scripts/cdecl-3.6.tar.gz | $(OUTPUT_DIR)
	@$(LOGGER) "Extracting $<"
	-flock -w 120 $< \
		tar xvf $< -C $(OUTPUT_DIR)
	@touch $@

$(CDECL_BUILD_DIR)/Makefile: $(CDECL_BUILD_DIR)/Makefile.in
	@$(LOGGER) "Configuring $@"
	@cd $(CDECL_BUILD_DIR) && ./configure --without-readline

$(CDECL_BIN)/cdecl: $(CDECL_BUILD_DIR)/Makefile
	@$(LOGGER) "Entering target $@"
	@$(MAKE) -C $(CDECL_BUILD_DIR)


.PHONY: all-semantics
all-semantics:
	@$(MAKE) -C semantics all BUILD_DIR=$(PROFILE_OUTPUT_DIR) PROFILE_DIR=$(PROFILE_DIR)

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
# command line, do not forget to pass `BUILD_DIR=<dir>` if you specified one
# during the build.
.PHONY: simple-build-test
simple-build-test:
	@$(LOGGER) "Testing kcc..."
	printf "#include <stdio.h>\nint main(void) { printf(\"x\"); return 42; }" \
		| $(OUTPUT_DIR)/kcc --use-profile $(PROFILE) -x c - -o $(OUTPUT_DIR)/testProgram.compiled
	$(OUTPUT_DIR)/testProgram.compiled 2> /dev/null > $(OUTPUT_DIR)/testProgram.out; \
		test $$? -eq 42
	grep x $(OUTPUT_DIR)/testProgram.out > /dev/null 2>&1
	@$(LOGGER) "Done."
	@$(LOGGER) "Cleaning up..."
	@rm -f $(OUTPUT_DIR)/testProgram.compiled
	@rm -f $(OUTPUT_DIR)/testProgram.out
	@$(LOGGER) "Done."


# Builds with `KOMPILE_FLAGS=--profile-rule-parsing`.
# Intended for direct user invocation.
# Produces a `timelogs.d` directory.
# Also produces a `timelogs.d/timelogs.csv` file
# suitable for importing into an SQL database.
.PHONY: profile-rule-parsing
profile-rule-parsing: export KOMPILE_FLAGS += --profile-rule-parsing
profile-rule-parsing: test-build
	$(eval TIMELOGS_DIR := $(OUTPUT_DIR)/timelogs.d)
	$(eval TIMELOGS_CSV := $(TIMELOGS_DIR)/timelogs.csv)
	@$(LOGGER) "Moving timingXX.log files into $(TIMELOGS_DIR)..."
	@cd $(OUTPUT_DIR)/profiles && \
	find . \
		! -path "*.build*" \
		! -path "*.git*" \
		-type f \
		-name "timing*.log" \
		-print | \
	while IFS= read f; do \
		mkdir -p $(TIMELOGS_DIR)/"$$(dirname $$f)"; \
		mv $$f $(TIMELOGS_DIR)/"$$(dirname $$f)"; \
	done
	@$(LOGGER) "Done."
	@$(LOGGER) "Generating $(TIMELOGS_CSV)..."
	@cd $(TIMELOGS_DIR) && \
	find . \
		-type f \
		-name "timing*.log" \
		-exec \
			perl -ne '/Source\((.*?)\):(\d+):(\d+)\s+(.*?)$$/ && print "{},$$1,$$2,$$3,$$4\n";' {} \; \
	> $(TIMELOGS_CSV)
	@$(LOGGER) "Done."


# This makefile does not need to be re-built.
# See https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
Makefile: ;

.PHONY: clean
clean:
	-$(MAKE) -C parser clean
	-$(MAKE) -C semantics clean
	-$(MAKE) -C tests clean
	-rm -rf scripts/cdecl-3.6/
	-rm -rf $(OUTPUT_DIR)


XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)
.PHONY: $(XYZ_SEMANTICS)

$(XYZ_SEMANTICS):
	@$(MAKE) -C semantics $@ BUILD_DIR=$(PROFILE_OUTPUT_DIR) PROFILE_DIR=$(PROFILE_DIR)


# A) Move this to the end so that .SECONDEXPANSION does not
#    affect the rest of the rules.
# B) The % sign matches '$(NAME)-kompiled/$(NAME)',
#    e.g., c-cpp-kompiled/c-cpp'.
.SECONDEXPANSION:
$(PROFILE_OUTPUT_DIR)/%-kompiled/timestamp: PROFILE_DEPS \
                                            $$(notdir $$*)-semantics
	$(eval NAME := $(notdir $*))
	@$(LOGGER) "Distributing $(NAME)"
	@true $(foreach d,$(SUBPROFILE_DIRS), \
		&& cp -RLp $(PROFILE_OUTPUT_DIR)/$(NAME)-kompiled $(OUTPUT_DIR)/profiles/$(shell basename $(d)))

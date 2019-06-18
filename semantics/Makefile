# Overridden in the top-level makefile.
BUILD_DIR := $(CURDIR)/../dist/semantics

# Used internally.
OUTPUT_DIR := $(abspath $(BUILD_DIR))

# Overridden in the top-level makefile.
PROFILE_DIR := $(realpath $(CURDIR)/../profiles/x86-gcc-limited-libc)

# Appending to whatever the environment provided.
KOMPILE_FLAGS += --backend ocaml
KOMPILE_FLAGS += --non-strict
KOMPILE_FLAGS += --smt none

# Generate a makefile list from a colon-separated one.
# K_INCLUDE_PATH comes from the environment.
# signature of `subst`: from,to,text.
K_INCLUDE_DIRS := $(subst :, ,$(K_INCLUDE_PATH))

# Append some more things.
K_INCLUDE_DIRS += $(PROFILE_DIR)/semantics
K_INCLUDE_DIRS += $(PROFILE_DIR)/semantics/c
K_INCLUDE_DIRS += $(PROFILE_DIR)/semantics/cpp

# Appending to whatever the environment provided.
KDEP_FLAGS += $(addprefix -I ,$(K_INCLUDE_DIRS))
KOMPILE_FLAGS += $(addprefix -I ,$(K_INCLUDE_DIRS))
KOMPILE_FLAGS += --no-prelude
KOMPILE_FLAGS += -w all
KOMPILE_FLAGS += -v
KOMPILE_FLAGS += --debug


# Used specifically in the timestamp_of rules.
CPP_KOMPILE_FLAGS := --opaque-klabels c-translation.k
EXECUTION_KOMPILE_FLAGS := \
	--opaque-klabels \
	cpp-translation.k \
	--no-expand-macros \
	--ocaml-serialize-config '$$PGM' \
	--ocaml-dump-exit-code 139

define timestamp_of
    $(OUTPUT_DIR)/$(1)-kompiled/$(1)-kompiled/timestamp
endef

# Prerequisites for the timestamp rules are added
# by the `include`d makefiles.
$(call timestamp_of,c-translation):
	$(info Kompiling the static C semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) c-translation.k \
		-d "$(OUTPUT_DIR)/c-translation-kompiled"

$(call timestamp_of,cpp-translation):
	$(info Kompiling the static C++ semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) cpp-translation.k \
		-d "$(OUTPUT_DIR)/cpp-translation-kompiled"

$(call timestamp_of,c-cpp-linking):
	$(info Kompiling the C and C++ linking semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) c-cpp-linking.k \
		-d "$(OUTPUT_DIR)/c-cpp-linking-kompiled"

$(call timestamp_of,c-cpp):
	$(info Kompiling the dynamic C and C++ semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-cpp-kompiled" \
		--transition "interpRule"

$(call timestamp_of,c-nd):
	$(info Kompiling the dynamic C and C++ semantics with expression sequencing non-determinism...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-nd-kompiled" \
		--transition "observable ndtrans" \
		--superheat "ndheat" \
		--supercool "ndlocal"

$(call timestamp_of,c-nd-thread):
	$(info Kompiling the dynamic C and C++ semantics with thread-interleaving non-determinism...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-nd-thread-kompiled" \
		--transition "observable ndtrans ndthread"


.PHONY: default
default: $(XYZ_SEMANTICS)

XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)

.PHONY: all
all: nd thread

.PHONY: nd
nd: c-nd-semantics

.PHONY: thread
thread: c-nd-thread-semantics

.PHONY: clean
clean:
	@-rm -rf */c-translation-kompiled \
           */cpp-translation-kompiled \
					 */c-cpp-kompiled \
					 */c-nd-kompiled \
					 */c-nd-thread-kompiled \
					 .kompile-* \
					 $(OUTPUT_DIR)

GENERATED_MAKEFILE_DIR := $(OUTPUT_DIR)/make.d

$(GENERATED_MAKEFILE_DIR): ;@mkdir -p $@

BASIC_DEPENDS := $(addsuffix .dep.mk, \
                   $(addprefix $(GENERATED_MAKEFILE_DIR)/basic-, \
                      c-translation cpp-translation c-cpp-linking c-cpp))
SPECIAL_DEPENDS := $(addsuffix .dep.mk, \
                     $(addprefix $(GENERATED_MAKEFILE_DIR)/, \
                        nd nd-thread))

# See https://stackoverflow.com/a/4270649/6209703
ifneq ($(MAKECMDGOALS),clean)
  DEPENDS := $(BASIC_DEPENDS) $(SPECIAL_DEPENDS)
  -include $(DEPENDS)
endif

# See https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
Makefile: $(DEPENDS) ;

$(BASIC_DEPENDS): $(GENERATED_MAKEFILE_DIR)/basic-%.dep.mk: %.k \
                                                            | $(GENERATED_MAKEFILE_DIR)
	$(KDEP) $(KDEP_FLAGS) -d "$(OUTPUT_DIR)/$*-kompiled" -- $*.k \
		| perl -pe 's|(.*?)\s*:|\1 $@:|g' \
	> $@

$(SPECIAL_DEPENDS): $(GENERATED_MAKEFILE_DIR)/%.dep.mk: c-cpp.k \
                                                        | $(GENERATED_MAKEFILE_DIR)
	$(KDEP) $(KDEP_FLAGS) -d "$(OUTPUT_DIR)/c-$*-kompiled" -- c-cpp.k \
		| perl -pe 's|(.*?)\s*:|\1 $@:|g' \
	> $@


# Move this to the end so that .SECONDEXPANSION
# does not affect any other rules.
.SECONDEXPANSION:
.PHONY: $(XYZ_SEMANTICS)
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*)

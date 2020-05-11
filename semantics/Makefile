# Overridden in the top-level makefile.
BUILD_DIR := $(CURDIR)/../dist/semantics

# Used internally.
OUTPUT_DIR := $(abspath $(BUILD_DIR))

# Overridden in the top-level makefile.
PROFILE_DIR := $(realpath $(CURDIR)/../profiles/x86-gcc-limited-libc)

# Appending to whatever the environment provided.
KOMPILE_FLAGS += --backend llvm

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
KOMPILE_FLAGS += -ccopt -g


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

XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)

.PHONY: default
default: $(XYZ_SEMANTICS)


# Prerequisites for the timestamp rules are added
# by the `include`d makefiles.
$(call timestamp_of,c-translation):
	@$(LOGGER) "Kompiling the static C semantics..."
	$(KOMPILE) $(KOMPILE_FLAGS) c-translation.k \
		-d "$(OUTPUT_DIR)/c-translation-kompiled"

$(call timestamp_of,cpp-translation):
	@$(LOGGER) "Kompiling the static C++ semantics..."
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) cpp-translation.k \
		-d "$(OUTPUT_DIR)/cpp-translation-kompiled"

$(call timestamp_of,c-cpp-linking):
	@$(LOGGER) "Kompiling the C and C++ linking semantics..."
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) c-cpp-linking.k \
		-d "$(OUTPUT_DIR)/c-cpp-linking-kompiled"

$(call timestamp_of,c-cpp):
	@$(LOGGER) "Kompiling the dynamic C and C++ semantics..."
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-cpp-kompiled" \
		--transition "interpRule"

.PHONY: clean
clean:
	@-rm -rf .kompile-*

GENERATED_MAKEFILE_DIR := $(OUTPUT_DIR)/make.d

$(GENERATED_MAKEFILE_DIR): ;@mkdir -p $@


# See https://stackoverflow.com/a/4270649/6209703
ifneq ($(MAKECMDGOALS),clean)
  DEPENDS := $(addsuffix .dep.mk, \
               $(addprefix $(GENERATED_MAKEFILE_DIR)/, \
                 c-translation cpp-translation c-cpp-linking c-cpp))

  -include $(DEPENDS)
endif

# See https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html
Makefile: $(DEPENDS) ;

# This rule generates $(DEPENDS), which is empty if the goal is `clean`.
$(GENERATED_MAKEFILE_DIR)/%.dep.mk: %.k \
                                    | $(GENERATED_MAKEFILE_DIR)
	$(CURDIR)/../scripts/gen-file-atomically.sh \
		"$@" \
		"$(KDEP) $(KDEP_FLAGS) -d $(OUTPUT_DIR)/$*-kompiled -- $(realpath $<)"


# Move this to the end so that .SECONDEXPANSION
# does not affect any other rules.
.SECONDEXPANSION:
.PHONY: $(XYZ_SEMANTICS)
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*)

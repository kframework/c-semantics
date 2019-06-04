# NOTE: PROFILE_DIR is required to be passed from above.

OUTPUT_DIR := build

# Intended to be passed from above.
KOMPILE_FLAGS ?=
KDEP_FLAGS ?=

# These are used in this Makefile.
KOMPILE_FLAGS += --backend ocaml --non-strict --smt none
KDEP_FLAGS += -I $(PROFILE_DIR)/semantics
KDEP_FLAGS += -I $(PROFILE_DIR)/semantics/c
KDEP_FLAGS += -I $(PROFILE_DIR)/semantics/cpp



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

.PHONY: default
default: fast

$(call timestamp_of,c-translation):
	$(info Kompiling the static C semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) c-translation.k \
		-d "$(OUTPUT_DIR)/c-translation-kompiled" \
		--no-prelude -w all -v --debug \
		-I $(PROFILE_DIR)/semantics

$(call timestamp_of,cpp-translation):
	$(info Kompiling the static C++ semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) cpp-translation.k \
		-d "$(OUTPUT_DIR)/cpp-translation-kompiled" \
		--no-prelude -w all -v --debug \
		-I $(PROFILE_DIR)/semantics

$(call timestamp_of,c-cpp-linking):
	$(info Kompiling the C and C++ linking semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(CPP_KOMPILE_FLAGS) c-cpp-linking.k \
		-d "$(OUTPUT_DIR)/c-cpp-linking-kompiled" \
		--no-prelude -w all -v --debug \
		-I $(PROFILE_DIR)/semantics

$(call timestamp_of,c-cpp):
	$(info Kompiling the dynamic C and C++ semantics...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-cpp-kompiled" \
		--no-prelude -w all -v --transition "interpRule" \
		--debug \
		-I $(PROFILE_DIR)/semantics

$(call timestamp_of,c-nd):
	$(info Kompiling the dynamic C and C++ semantics with expression sequencing non-determinism...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-nd-kompiled" \
		--no-prelude --transition "observable ndtrans" \
		--superheat "ndheat" --supercool "ndlocal" \
		-I $(PROFILE_DIR)/semantics

$(call timestamp_of,c-nd-thread):
	$(info Kompiling the dynamic C and C++ semantics with thread-interleaving non-determinism...)
	$(KOMPILE) $(KOMPILE_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c-cpp.k \
		-d "$(OUTPUT_DIR)/c-nd-thread-kompiled" \
		--no-prelude --transition "observable ndtrans ndthread" \
		-I $(PROFILE_DIR)/semantics

.PHONY: all
all: fast nd thread

.PHONY: fast
fast: $(addsuffix -semantics,c-translation c-cpp c-cpp)

XYZ_SEMANTICS := $(addsuffix -semantics,c-translation cpp-translation c-cpp-linking c-cpp)

.PHONY: fast-cpp
fast-cpp: $(XYZ_SEMANTICS)

.PHONY: nd
nd: $(call timestamp_of,c-nd)

.PHONY: thread
thread: $(call timestamp_of,c-nd-thread)

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

DEPENDS := $(BASIC_DEPENDS) $(SPECIAL_DEPENDS)

Makefile: $(DEPENDS)

# See https://stackoverflow.com/a/4270649/6209703
ifneq ($(MAKECMDGOALS),clean)
  -include $(DEPENDS)
endif

$(BASIC_DEPENDS): $(GENERATED_MAKEFILE_DIR)/basic-%.dep.mk: | $(GENERATED_MAKEFILE_DIR)
	$(KDEP) $(KDEP_FLAGS) -d "$(OUTPUT_DIR)/$*-kompiled" -- $*.k > $@

$(SPECIAL_DEPENDS): $(GENERATED_MAKEFILE_DIR)/%.dep.mk: | $(GENERATED_MAKEFILE_DIR)
	$(KDEP) $(KDEP_FLAGS) -d "$(OUTPUT_DIR)/c-$*-kompiled" -- c-cpp.k > $@


# Move this to the end so that .SECONDEXPANSION
# does not affect any other rules.
.PHONY: $(XYZ_SEMANTICS)
.SECONDEXPANSION:
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*)

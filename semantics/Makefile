KOMPILE_DEFAULT_FLAGS=--backend ocaml --non-strict --smt none
CPP_KOMPILE_FLAGS=--opaque-klabels c11-translation.k
EXECUTION_KOMPILE_FLAGS=--opaque-klabels cpp14-translation.k --no-expand-macros --ocaml-serialize-config '$$PGM' --ocaml-dump-exit-code 139
KDEP_DEFAULT_FLAGS=

.PHONY: default all fast nd thread clean .depend-$(PROFILE)-c11-translation .depend-$(PROFILE)-c11-cpp14-execution .depend-$(PROFILE)-c11-cpp14-linking .depend-$(PROFILE)-nd .depend-$(PROFILE)-nd-thread .depend-$(PROFILE)-cpp14-translation

define timestamp_of
    .build/$(PROFILE)/$(1)-kompiled/$(1)-kompiled/timestamp
endef

default: fast

$(call timestamp_of,c11-translation):
	@echo "Kompiling the static C semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) c11-translation.k -d ".build/$(PROFILE)/c11-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/semantics

$(call timestamp_of,cpp14-translation):
	@echo "Kompiling the static C++ semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(CPP_KOMPILE_FLAGS) cpp14-translation.k -d ".build/$(PROFILE)/cpp14-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/semantics

$(call timestamp_of,c11-cpp14-linking):
	@echo "Kompiling the C and C++ linking semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(CPP_KOMPILE_FLAGS) c11-cpp14-linking.k -d ".build/$(PROFILE)/c11-cpp14-linking-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/semantics

$(call timestamp_of,c11-cpp14):
	@echo "Kompiling the dynamic C and C++ semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d ".build/$(PROFILE)/c11-cpp14-kompiled" --no-prelude -w all -v --transition "interpRule" --debug -I $(PROFILE_DIR)/semantics

$(call timestamp_of,c11-nd):
	@echo "Kompiling the dynamic C and C++ semantics with expression sequencing non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d ".build/$(PROFILE)/c11-nd-kompiled" --no-prelude --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal" -I $(PROFILE_DIR)/semantics

$(call timestamp_of,c11-nd-thread):
	@echo "Kompiling the dynamic C and C++ semantics with thread-interleaving non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d ".build/$(PROFILE)/c11-nd-thread-kompiled" --no-prelude --transition "observable ndtrans ndthread" -I $(PROFILE_DIR)/semantics

all: fast nd thread

fast: $(addsuffix -semantics,c11-translation c11-cpp14 c11-cpp14)

fast-cpp: $(addsuffix -semantics,c11-translation c11-cpp14 c11-cpp14-linking cpp14-translation)

XYZ_SEMANTICS := $(addsuffix -semantics,c11-translation cpp14-translation c11-cpp14-linking c11-cpp14)
.PHONY: $(XYZ_SEMANTICS)
.SECONDEXPANSION:
$(XYZ_SEMANTICS): %-semantics: $(call timestamp_of,$$*)

nd: $(call timestamp_of,c11-nd)

thread: $(call timestamp_of,c11-nd-thread)

clean:
	@-rm -rf */c11-translation-kompiled */cpp14-translation-kompiled */c11-cpp14-kompiled */c11-nd-kompiled */c11-nd-thread-kompiled .kompile-* .depend-* .build/*

.depend-$(PROFILE)-c11-translation:
	$(eval TMP := $(shell mktemp))
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d ".build/$(PROFILE)/c11-translation-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/c -- c11-translation.k > $(TMP)
	mv $(TMP) $@
.depend-$(PROFILE)-cpp14-translation:
	$(eval TMP := $(shell mktemp))
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d ".build/$(PROFILE)/cpp14-translation-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/cpp -I $(PROFILE_DIR)/semantics/c -- cpp14-translation.k > $(TMP)
	mv $(TMP) $@
.depend-$(PROFILE)-c11-cpp14-linking:
	$(eval TMP := $(shell mktemp))
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d ".build/$(PROFILE)/c11-cpp14-linking-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/cpp -I $(PROFILE_DIR)/semantics/c -- c11-cpp14-linking.k > $(TMP)
	mv $(TMP) $@
.depend-$(PROFILE)-c11-cpp14:
	$(eval TMP := $(shell mktemp))
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d ".build/$(PROFILE)/c11-cpp14-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/c -I $(PROFILE_DIR)/semantics/cpp -- c11-cpp14.k > $(TMP)
	mv $(TMP) $@

.depend-$(PROFILE)-nd:
	$(eval TMP := $(shell mktemp))
	$(KDEP) -d ".build/$(PROFILE)/c11-nd-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/c -I $(PROFILE_DIR)/semantics/cpp -- c11-cpp14.k > $(TMP)
	mv $(TMP) $@
.depend-$(PROFILE)-nd-thread:
	$(eval TMP := $(shell mktemp))
	$(KDEP) -d ".build/$(PROFILE)/c11-nd-thread-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/semantics/c -I $(PROFILE_DIR)/semantics/cpp -- c11-cpp14.k > $(TMP)
	mv $(TMP) $@

-include .depend-$(PROFILE)-c11-translation
-include .depend-$(PROFILE)-cpp14-translation
-include .depend-$(PROFILE)-c11-cpp14-linking
-include .depend-$(PROFILE)-c11-cpp14

-include .depend-$(PROFILE)-nd
-include .depend-$(PROFILE)-nd-thread

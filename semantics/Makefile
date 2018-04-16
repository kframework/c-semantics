export K_OPTS := -Xmx2048m -Xss32m
KOMPILE = kompile -O2
KDEP = kdep
KOMPILE_DEFAULT_FLAGS=--backend ocaml --non-strict --smt none
CPP_KOMPILE_FLAGS=--opaque-klabels c11/c11-translation.k
EXECUTION_KOMPILE_FLAGS=--opaque-klabels cpp14/cpp14-translation.k --no-expand-macros --ocaml-serialize-config '$$PGM' --ocaml-dump-exit-code 139
KDEP_DEFAULT_FLAGS=

C11_TRANSLATION_FILES = $(wildcard *.k) \
	$(wildcard language/translation/*.k) $(wildcard language/translation/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k)
	
C11_FILES = $(wildcard *.k) \
	$(wildcard language/execution/*.k) $(wildcard language/execution/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k) \
	$(wildcard library/*.k)

.PHONY: default all fast nd thread clean .depend-translation .depend-execution .depend-nd .depend-nd-thread .depend-cpp

define timestamp_of
    $(PROFILE)/$(1)-kompiled/$(1)-kompiled/timestamp
endef

default: fast

$(call timestamp_of,c11-translation):
	@echo "Kompiling the static C semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) c11/c11-translation.k -d "$(PROFILE)/c11-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/semantics

$(call timestamp_of,cpp14-translation):
	@echo "Kompiling the static C++ semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(CPP_KOMPILE_FLAGS) cpp14/cpp14-translation.k -d "$(PROFILE)/cpp14-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/cpp-semantics -I $(PROFILE_DIR)/semantics

$(call timestamp_of,c11-cpp14):
	@echo "Kompiling the dynamic C and C++ semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d "$(PROFILE)/c11-cpp14-kompiled" --no-prelude -w all -v --transition "interpRule" --debug -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

$(call timestamp_of,c11-nd):
	@echo "Kompiling the dynamic C and C++ semantics with expression sequencing non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d "$(PROFILE)/c11-nd-kompiled" --no-prelude --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

$(call timestamp_of,c11-nd-thread):
	@echo "Kompiling the dynamic C and C++ semantics with thread-interleaving non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) $(EXECUTION_KOMPILE_FLAGS) c11-cpp14.k -d "$(PROFILE)/c11-nd-thread-kompiled" --no-prelude --transition "observable ndtrans ndthread" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

all: fast nd thread

fast: translation execution

fast-cpp: translation execution cpp

translation: $(call timestamp_of,c11-translation)

cpp: $(call timestamp_of,cpp14-translation)

execution: $(call timestamp_of,c11-cpp14)

nd: $(call timestamp_of,c11-nd)

thread: $(call timestamp_of,c11-nd-thread)

clean:
	@-rm -rf */c11-translation-kompiled */cpp14-translation-kompiled */c11-cpp14-kompiled */c11-nd-kompiled */c11-nd-thread-kompiled

.depend-translation:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/c11-translation-kompiled" -I $(PROFILE_DIR)/semantics -- c11/c11-translation.k > $@-tmp
	mv $@-tmp $@
.depend-cpp:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/cpp14-translation-kompiled" -I $(PROFILE_DIR)/cpp-semantics -I $(PROFILE_DIR)/semantics -- cpp14/cpp14-translation.k > $@-tmp
	mv $@-tmp $@
.depend-execution:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/c11-cpp14-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > $@-tmp
	mv $@-tmp $@
.depend-nd:
	$(KDEP) -d "$(PROFILE)/c11-nd-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > $@-tmp
	mv $@-tmp $@
.depend-nd-thread:
	$(KDEP) -d "$(PROFILE)/c11-nd-thread-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > $@-tmp
	mv $@-tmp $@

-include .depend-translation
-include .depend-cpp
-include .depend-execution
-include .depend-nd
-include .depend-nd-thread

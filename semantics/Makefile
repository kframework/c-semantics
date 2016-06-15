export K_OPTS := -Xmx2048m -Xss32m
KOMPILE = kompile -O2
KDEP = kdep
KOMPILE_DEFAULT_FLAGS=--backend ocaml --non-strict --exit-code "<result-value> _:Int </result-value>"
KDEP_DEFAULT_FLAGS=

C11_TRANSLATION_FILES = $(wildcard *.k) \
	$(wildcard language/translation/*.k) $(wildcard language/translation/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k)
	
C11_FILES = $(wildcard *.k) \
	$(wildcard language/execution/*.k) $(wildcard language/execution/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k) \
	$(wildcard library/*.k)

.PHONY: default all fast nd thread clean .depend-translation .depend-execution .depend-nd .depend-nd-thread

default: fast

$(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/timestamp:
	@echo "Kompiling the static C semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) --smt none c11/c11-translation.k -d "$(PROFILE)/c11-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/semantics

$(PROFILE)/cpp14-translation-kompiled/cpp14-translation-kompiled/timestamp:
	@echo "Kompiling the static C++ semantics..."
	$(KOMPILE) $(KOKMPILE_DEFAULT_FLAGS) --smt none cpp14/cpp14-translation.k -d "$(PROFILE)/cpp14-translation-kompiled" --no-prelude -w all -v --debug -I $(PROFILE_DIR)/cpp-semantics

$(PROFILE)/c11-cpp14-kompiled/c11-cpp14-kompiled/timestamp:
	@echo "Kompiling the dynamic C and C++ semantics..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) --smt none c11-cpp14.k -d "$(PROFILE)/c11-cpp14-kompiled" --no-prelude -w all -v --transition "interpRule" --debug -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp:
	@echo "Kompiling the dynamic C and C++ semantics with expression sequencing non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) --smt none c11-cpp14.k -d "$(PROFILE)/c11-nd-kompiled" --no-prelude --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp:
	@echo "Kompiling the dynamic C and C++ semantics with thread-interleaving non-determinism..."
	$(KOMPILE) $(KOMPILE_DEFAULT_FLAGS) --smt none c11-cpp14.k -d "$(PROFILE)/c11-nd-thread-kompiled" --no-prelude --transition "observable ndtrans ndthread" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics

all: fast nd thread

fast: translation execution

fast-cpp: translation execution cpp

translation: $(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/timestamp

cpp: $(PROFILE)/cpp14-translation-kompiled/cpp14-translation-kompiled/timestamp

execution: $(PROFILE)/c11-cpp14-kompiled/c11-cpp14-kompiled/timestamp

nd: $(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp

thread: $(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp

clean:
	@-rm -rf */c11-translation-kompiled */c11-cpp14-kompiled */c11-nd-kompiled */c11-nd-thread-kompiled

.depend-translation:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/c11-translation-kompiled" -I $(PROFILE_DIR)/semantics -- c11/c11-translation.k > .depend-translation-tmp
	mv .depend-translation-tmp .depend-translation
.depend-cpp:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/cpp14-translation-kompiled" -I $(PROFILE_DIR)/cpp-semantics -- cpp14/cpp14-translation.k > .depend-translation-tmp
	mv .depend-cpp-tmp .depend-cpp
.depend-execution:
	$(KDEP) $(KDEP_DEFAULT_FLAGS) -d "$(PROFILE)/c11-cpp14-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > .depend-execution-tmp
	mv .depend-execution-tmp .depend-execution
.depend-nd:
	$(KDEP) -d "$(PROFILE)/c11-nd-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > .depend-nd-tmp
	mv .depend-nd-tmp .depend-nd
.depend-nd-thread:
	$(KDEP) -d "$(PROFILE)/c11-nd-thread-kompiled" -I $(PROFILE_DIR)/semantics -I $(PROFILE_DIR)/cpp-semantics -- c11-cpp14.k > .depend-nd-thread-tmp
	mv .depend-nd-thread-tmp .depend-nd-thread

-include .depend-translation
-include .depend-execution
-include .depend-nd
-include .depend-nd-thread

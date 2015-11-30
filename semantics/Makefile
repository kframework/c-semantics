export K_OPTS := -Xmx2048m -Xss32m
KOMPILE = kompile --ocamlopt
KDEP = kdep

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
	$(KOMPILE) --backend ocaml --non-strict --smt none c11-translation.k -d "$(PROFILE)/c11-translation-kompiled" -w all -v --debug -I $(PROFILE_DIR)/semantics

$(PROFILE)/c11-kompiled/c11-kompiled/timestamp:
	@echo "Kompiling the dynamic C semantics..."
	$(KOMPILE) --backend ocaml --non-strict --smt none c11.k -d "$(PROFILE)/c11-kompiled" -w all -v --transition "interpRule" --debug -I $(PROFILE_DIR)/semantics

$(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp:
	@echo "Kompiling the dynamic C semantics with expression sequencing non-determinism..."
	$(KOMPILE) --backend ocaml --non-strict --smt none c11.k -d "$(PROFILE)/c11-nd-kompiled" --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal" -I $(PROFILE_DIR)/semantiocs

$(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp:
	@echo "Kompiling the dynamic C semantics with thread-interleaving non-determinism..."
	$(KOMPILE) --backend ocaml --non-strict --smt none c11.k -d "$(PROFILE)/c11-nd-thread-kompiled" --transition "observable ndtrans ndthread" -I $(PROFILE_DIR)/semantics

all: fast nd thread

fast: translation execution

translation: $(PROFILE)/c11-translation-kompiled/c11-translation-kompiled/timestamp

execution: $(PROFILE)/c11-kompiled/c11-kompiled/timestamp

nd: $(PROFILE)/c11-nd-kompiled/c11-nd-kompiled/timestamp

thread: $(PROFILE)/c11-nd-thread-kompiled/c11-nd-thread-kompiled/timestamp

clean:
	@-rm -rf */c11-translation-kompiled */c11-kompiled */c11-nd-kompiled */c11-nd-thread-kompiled

.depend-translation:
	$(KDEP) c11-translation.k -d "$(PROFILE)/c11-translation-kompiled" -I $(PROFILE_DIR)/semantics > .depend-translation
.depend-execution:
	$(KDEP) c11.k -d "$(PROFILE)/c11-kompiled" -I $(PROFILE_DIR)/semantics > .depend-execution
.depend-nd:
	$(KDEP) c11.k -d "$(PROFILE)/c11-nd-kompiled" -I $(PROFILE_DIR)/semantics > .depend-nd
.depend-nd-thread:
	$(KDEP) c11.k -d "$(PROFILE)/c11-nd-thread-kompiled" -I $(PROFILE_DIR)/semantics > .depend-nd-thread

include .depend-translation
include .depend-execution
include .depend-nd
include .depend-nd-thread

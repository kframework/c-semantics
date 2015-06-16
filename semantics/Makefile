export K_OPTS := -Xmx2048m
KOMPILE = kompile

C11_TRANSLATION_FILES = $(wildcard *.k) \
	$(wildcard language/translation/*.k) $(wildcard language/translation/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k)
	
C11_FILES = $(wildcard *.k) \
	$(wildcard language/execution/*.k) $(wildcard language/execution/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k) \
	$(wildcard library/*.k)

K_CLEAN_FILES = .k c11-translation-kompiled c11-kompiled c11-nd-kompiled c11-nd-thread-kompiled

.PHONY: default all fast nd thread clean

default: fast

c11-translation-kompiled/c11-translation-kompiled/def.cmx: $(C11_TRANSLATION_FILES)
	@echo "Kompiling the static C semantics..."
	$(KOMPILE) --backend ocaml --kore --non-strict --smt none c11-translation.k -d "c11-translation-kompiled" -w all -v --debug

c11-kompiled/c11-kompiled/def.cmx: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics..."
	$(KOMPILE) --backend ocaml --kore --non-strict --smt none c11.k -d "c11-kompiled" -w all -v --transition "interpRule" --debug

c11-nd-kompiled/c11-nd-kompiled/def.cmx: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics with expression sequencing non-determinism..."
	$(KOMPILE) --backend ocaml --kore --non-strict --smt none c11.k -d "c11-nd-kompiled" --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal"

c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.cmx: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics with thread-interleaving non-determinism..."
	$(KOMPILE) --backend ocaml --kore --non-strict --smt none c11.k -d "c11-nd-thread-kompiled" --transition "observable ndtrans ndthread"

all: fast nd thread

fast: c11-translation-kompiled/c11-translation-kompiled/def.cmx c11-kompiled/c11-kompiled/def.cmx

nd: c11-nd-kompiled/c11-nd-kompiled/def.cmx

thread: c11-nd-thread-kompiled/c11-nd-thread-kompiled/def.cmx

clean:
	@-rm -rf $(K_CLEAN_FILES)


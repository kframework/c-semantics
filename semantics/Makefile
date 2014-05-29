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

c11-translation-kompiled: $(C11_TRANSLATION_FILES)
	@echo "Kompiling the static C semantics..."
	@$(KOMPILE) --backend java c11-translation.k -d "c11-translation-kompiled" -w all -v
	@touch c11-translation-kompiled

c11-kompiled: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics..."
	@$(KOMPILE) --backend java c11.k -d "c11-kompiled" -w all -v --transition "interpRule"
	@touch c11-kompiled

c11-nd-kompiled: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics with expression sequencing non-determinism..."
	@$(KOMPILE)  --backend java c11.k -d "c11-nd-kompiled" --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal"
	@touch c11-nd-kompiled

c11-nd-thread-kompiled: $(C11_FILES)
	@echo "Kompiling the dynamic C semantics with thread-interleaving non-determinism..."
	@$(KOMPILE)  --backend java c11.k -d "c11-nd-thread-kompiled" --transition "observable ndtrans ndthread"
	@touch c11-nd-thread-kompiled

all: fast nd thread

fast: c11-translation-kompiled c11-kompiled

nd: c11-nd-kompiled

thread: c11-nd-thread-kompiled

clean:
	@-rm -rf $(K_CLEAN_FILES)


KOMPILE = kompile

C11_TRANS_FILES = $(wildcard *.k) \
	$(wildcard language/translation/*.k) $(wildcard language/translation/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k)
	
C11_FILES = $(wildcard *.k) \
	$(wildcard language/execution/*.k) $(wildcard language/execution/*/*.k) \
	$(wildcard language/common/*.k) $(wildcard language/common/*/*.k) \
	$(wildcard library/*.k)

K_CLEAN_FILES = .k c11-trans-kompiled c11-kompiled c11-kompiled-nd c11-kompiled-nd-thread 

.PHONY: default all fast nd thread clean

default: fast

c11-trans-kompiled: $(C11_TRANS_FILES)
	@echo "Compiling the static C semantics..."
	@$(KOMPILE) c11-trans.k -d "c11-trans-kompiled" -w all -v --transition "interpRule"
	@touch c11-trans-kompiled

c11-kompiled: $(C11_FILES)
	@echo "Compiling the dynamic C semantics..."
	@$(KOMPILE) c11.k -d "c11-kompiled" -w all -v --transition "interpRule"
	@touch c11-kompiled

c11-kompiled-nd: $(C11_FILES)
	@echo "Compiling the dynamic C semantics with expression sequencing non-determinism..."
	@$(KOMPILE) c11.k -d "c11-kompiled-nd" --transition "observable ndtrans" --superheat "ndheat" --supercool "ndlocal"
	@touch c11-kompiled-nd

c11-kompiled-nd-thread: $(C11_FILES)
	@echo "Compiling the dynamic C semantics with thread-interleaving non-determinism..."
	@$(KOMPILE) c11.k -d "c11-kompiled-nd-thread" --transition "observable ndtrans ndthread"
	@touch c11-kompiled-nd-thread

all: fast nd thread

fast: c11-trans-kompiled c11-kompiled

nd: c11-kompiled-nd

thread: c11-kompiled-nd-thread

clean:
	@-rm -rf $(K_CLEAN_FILES)


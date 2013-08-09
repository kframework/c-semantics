KOMPILE = kompile

C11_FILES = $(wildcard *.k) $(wildcard */*.k) $(wildcard */*/*.k)

K_CLEAN_FILES = .k c11-kompiled c11-kompiled-nd c11-kompiled-nd-thread 

.PHONY: default all fast nd thread clean

default: fast

c11-kompiled: $(C11_FILES)
	@echo "Compiling the C definition..."
	@$(KOMPILE) c11.k -o "c11-kompiled" -w all -v -l C11 -transition "interpRule"
	@touch c11-kompiled

c11-kompiled-nd: $(C11_FILES)
	@echo "Compiling the C definition with expression sequencing non-determinism..."
	@$(KOMPILE) c11.k -o "c11-kompiled-nd" -l C11 -transition "observable ndtrans" -superheat "ndheat" -supercool "ndlocal"
	@touch c11-kompiled-nd

c11-kompiled-nd-thread: $(C11_FILES)
	@echo "Compiling the C definition with thread-interleaving non-determinism..."
	@$(KOMPILE) c11.k -o "c11-kompiled-nd-thread" -l C11 -transition "observable ndtrans ndthread"
	@touch c11-kompiled-nd-thread

all: fast nd thread

fast: c11-kompiled

nd: c11-kompiled-nd

thread: c11-kompiled-nd-thread

clean:
	@-rm -rf $(K_CLEAN_FILES)


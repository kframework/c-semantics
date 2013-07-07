KOMPILE = $(C_K_BASE)/bin/kompile

C11_FILES = $(wildcard *.k) $(wildcard */*.k) $(wildcard */*/*.k)

K_CLEAN_FILES = .k c11-kompiled c11-kompiled-nd c11-kompiled-nd-thread 

.PHONY: default check-vars all fast nd thread clean

default: fast

c11-kompiled: $(C11_FILES) | check-vars
	@echo "Compiling the C definition..."
	@$(KOMPILE) c11.k -o "c11-kompiled" -w -v -l C11 -transition "interpRule"
	@touch c11-kompiled

c11-kompiled-nd: $(C11_FILES) | check-vars
	@echo "Compiling the C definition with side-effect nondeterminism..."
	@$(KOMPILE) c11.k -o "c11-kompiled-nd" -l C11 -transition "observable ndtrans" -superheat "ndheat" -supercool "ndlocal"
	@touch c11-kompiled-nd

c11-kompiled-nd-thread: $(C11_FILES) | check-vars
	@echo "Compiling the C definition with thread-interleaving nondeterminism..."
	@$(KOMPILE) c11.k -o "c11-kompiled-nd-thread" -l C11 -transition "observable ndtrans ndthread"
	@touch c11-kompiled-nd-thread

all: fast nd thread

fast: c11-kompiled

nd: c11-kompiled-nd

thread: c11-kompiled-nd-thread

clean:
	@-rm -rf $(K_CLEAN_FILES)

check-vars:
ifeq ($(C_K_BASE),)
	@echo "ERROR: Please set C_K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export C_K_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif


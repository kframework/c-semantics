KOMPILE = $(C_K_BASE)/bin/kompile

KOMPILE_C = $(KOMPILE) c11.k -o "c11-kompiled" -w -v -l C11 -transition "interpRule"
KOMPILE_C_ND = $(KOMPILE) c11.k -o "c11-kompiled-nd" -l C11 -transition "observable ndtrans" -superheat "ndheat" -supercool "ndlocal"
KOMPILE_C_ND_THREAD = $(KOMPILE) c11.k -o "c11-kompiled-nd-thread" -l C11 -transition "observable ndtrans ndthread"

LIBC_FILES = libc.k $(wildcard library/*.k)

STATEMENT_FILES = $(wildcard language/statement/*.k)
EXPRESSION_FILES = $(wildcard language/expression/*.k)
DECLARATION_FILES = $(wildcard language/declaration/*.k)
TYPING_FILES = $(wildcard language/typing/*.k)
MEMORY_FILES = $(wildcard language/memory/*.k)

C_FILES = $(wildcard language/*.k) \
	$(STATEMENT_FILES) $(EXPRESSION_FILES) $(TYPING_FILES) \
	$(MEMORY_FILES) $(DECLARATION_FILES)

C11_FILES = $(wildcard *.k) $(LIBC_FILES) $(C_FILES)

K_CLEAN_FILES = .k c11-kompiled c11-kompiled-nd c11-kompiled-nd-thread 

.PHONY: default clean semantics fast nd thread

default: fast

check-vars:
ifeq ($(C_K_BASE),)
	@echo "ERROR: Please set C_K_BASE to the full path of your K installation."
	@echo "Make sure you do NOT include a trailing slash\\"
	@echo "One way to do this is to type 'export C_K_BASE=/path/to/k/framework', and then rerun 'make'"
	@exit 1
endif

c11-kompiled/main.maude: check-vars $(K_FILES) $(C11_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition..."
	@$(KOMPILE_C)

c11-kompiled-nd/main.maude: check-vars $(K_FILES) $(C11_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with side-effect nondeterminism..."
	@$(KOMPILE_C_ND)

c11-kompiled-nd-thread/main.maude: check-vars $(K_FILES) $(C11_FILES) $(INSERT_LINE)
	@echo "Compiling the C definition with thread-interleaving nondeterminism..."
	@$(KOMPILE_C_ND_THREAD)

semantics: fast nd thread

fast: c11-kompiled/main.maude

nd: c11-kompiled-nd/main.maude

thread: c11-kompiled-nd-thread/main.maude

clean:
	rm -rf $(K_CLEAN_FILES)

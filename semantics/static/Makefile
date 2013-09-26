KOMPILE = kompile

C11_FILES = $(wildcard *.k) $(wildcard */*.k) $(wildcard */*/*.k) \
	$(wildcard ../common/*.k) $(wildcard ../common/*/*.k)

K_CLEAN_FILES = .k c11-static-kompiled

.PHONY: all clean

all: c11-static-kompiled

c11-static-kompiled: $(C11_FILES)
	@echo "Compiling the C11 static semantics..."
	@$(KOMPILE) c11.k -o "c11-static-kompiled" -w all -v -l C11
	@touch c11-static-kompiled

clean:
	@-rm -rf $(K_CLEAN_FILES)


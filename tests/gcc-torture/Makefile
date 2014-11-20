TESTS = $(wildcard ./*.c)
GCC_COMPILED_TESTS = ${TESTS:.c=.gcc}
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc}
TEST_RESULTS = ${TESTS:.c=.out}

.PHONY: test clean

test: ${TEST_RESULTS}

%.out: %.kcc
	@echo -n "Running $<... "
	@-./$< > $@ 2>&1; if [ $$? -eq 0 ] ; then echo "passed $<"; else echo "failed $<"; cat $@; fi

%.kcc: %.c
	@echo -n "Compiling $<... "
	@-kcc -o $@ $< > $@.out 2>&1; if [ $$? -eq 0 ] ; then echo "passed $<"; else echo "failed $<"; cat $@.out; fi

clean:
	rm -rf *.out *.kcc

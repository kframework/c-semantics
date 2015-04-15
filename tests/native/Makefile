TUS = $(wildcard ./*.c)
TESTS = $(filter-out ./libtest.c, ${TUS})
GCC_COMPILED_TESTS = ${TESTS:.c=.gcc}
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc}
TEST_RESULTS = ${TESTS:.c=.out}
REFERENCE_TEST_RESULTS = ${TESTS:.c=.ref}
TEST_COMPARISON = ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${TEST_RESULTS}

reference: ${REFERENCE_TEST_RESULTS}

comparison: ${TEST_COMPARISON}

libtest.so: libtest.c
	gcc -shared -std=c11 -fPIC -o $@ $<

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.kcc: %.c libtest.so
	@echo -n "Compiling $<... "
	@../../dist/kcc -fnative-libc -l./libtest.so -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.gcc: %.c libtest.so
	@echo -n "Compiling $< (reference)... "
	@gcc -std=c11 -o $@ $< -ldl -lm ./libtest.so > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp libtest.so

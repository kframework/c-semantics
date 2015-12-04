TUS = $(wildcard ./*.c)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, ${TUS}))
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

compile: ${KCC_COMPILED_TESTS}

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-link1.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@../../dist/kcc -o $@ $^ > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@../../dist/kcc -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.gcc: %-link1.c %-link2.c
	@echo -n "Compiling $^ (reference)... "
	@gcc-4.9 -std=c11 -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.gcc: %.c
	@echo -n "Compiling $< (reference)... "
	@gcc-4.9 -std=c11 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp

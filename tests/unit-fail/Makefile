TUS = $(wildcard ./*.c)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, ${TUS}))
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc}
TEST_RESULTS = ${TESTS:.c=.out}
TEST_COMPARISON = ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 139 ] ; then echo "passed $<"; cat $@.tmp > $@; rm $@.tmp; else echo "failed $<"; cat $@.tmp; exit 1; fi
CHECK_RESULT_DIFF = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${TEST_RESULTS}

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

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_DIFF}

clean:
	rm -rf *.out *.kcc *.tmp *.cmp

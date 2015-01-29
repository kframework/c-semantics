TUS = $(wildcard ./*.c)
TESTS = $(filter-out %-link2.c, ${TUS})
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc.out}
TEST_COMPARISON = ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 1 -o $$? -eq 255 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${KCC_COMPILED_TESTS}

comparison: ${TEST_COMPARISON}

%-link1.kcc.out: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@../../dist/kcc $^ > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}

%.kcc.out: %.c
	@echo -n "Compiling $<... "
	@../../dist/kcc $< > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}

%.cmp: %.kcc.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.cmp

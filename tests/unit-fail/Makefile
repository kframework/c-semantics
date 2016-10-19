TUS = $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
CPP_TESTS = $(filter-out %.c, ${TESTS})
GCC_COMPILED_TESTS = ${TESTS:=.gcc}
KCC_COMPILED_TESTS = ${TESTS:=.kcc}
TEST_RESULTS = ${TESTS:=.out}
TEST_COMPARISON = ${TESTS:=.cmp}
CPP_TEST_COMPARISON = ${CPP_TESTS:=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 139 ] ; then echo "passed $<"; cat $@.tmp > $@; rm $@.tmp; else echo "failed $<"; cat $@.tmp; exit 1; fi
CHECK_RESULT_DIFF = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${TEST_RESULTS}

comparison: ${TEST_COMPARISON}

cpp-comparison: ${CPP_TEST_COMPARISON}

compile: ${KCC_COMPILED_TESTS}

# some versions of GNU make define the following pattern rule using cp. We need
# to disable this, otherwise we will skip compilation and things will break.
%.out: %

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-link1.c.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@../../dist/kcc -o $@ $^ > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.C.kcc: %-link1.C %-link2.C
	@echo -n "Compiling $^... "
	@../../dist/kcc -o $@ $^ > $@.tmnp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.c.kcc: %.c
	@echo -n "Compiling $<... "
	@../../dist/kcc -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.C.kcc: %.C
	@echo -n "Compiling $<... "
	@../../dist/kcc -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_DIFF}

clean:
	rm -rf *.out *.kcc *.tmp *.cmp

TUS = $(wildcard ./*.c)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link3.c, ${TUS:-link1.c=.c})))
CC ?= gcc
TEST_COMPARISON = ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

CHECK_RESULT_COMPILE_FATAL = if [ $$? -eq 1 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

CHECK_RESULT_RUN_FATAL = if [ $$? -eq 139 ] ; then echo "passed $<"; cat $@.tmp > $@; rm $@.tmp; else echo "failed $<"; cat $@.tmp; exit 1; fi

KCC ?= kcc
KCCFLAGS = -fno-diagnostics-color
CFLAGS = -fno-diagnostics-color -std=c11

.PHONY: clean comparison
.PRECIOUS: %.kcc %.out

comparison: ${TEST_COMPARISON}

%-bad-static.out: %-bad-static.kcc
	@cp $<.out $@

%-bad-static.kcc: %-bad-static.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-bad.kcc: %-bad.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}
%-good.kcc: %-good.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.out: %-good.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-bad.out: %-bad.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN_FATAL}

%-good.gcc: %-good.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) $(CFLAGS) -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.gcc: %-good-link1.c %-good-link2.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) $(CFLAGS) -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.output: %-good.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.output
	@echo -n "Comparing $^... "
	@diff --strip-trailing-cr $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

.PRECIOUS: %.out

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *-good.output *.cmp

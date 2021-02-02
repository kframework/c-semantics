TUS = $(wildcard ./*.c)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link3.c, ${TUS:-link1.c=.c})))
CC=gcc
TEST_COMPARISON = ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

KCC = kcc
KCCFLAGS = -frecover-all-errors -fno-native-compilation -fno-diagnostics-color -Wno-implementation-defined
CFLAGS = -fno-diagnostics-color -std=c11

.PHONY: clean comparison
.PRECIOUS: %.kcc %.out

comparison: ${TEST_COMPARISON}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) $(KCCFLAGS) -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.out: %-good.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-bad-static.out: %-bad-static.kcc
	@cp $<.out $@

%-bad.out: %-bad.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-bad-nc.out: %-bad-nc.kcc
	@echo -n "Running $<... "
	@./$< 2>&1 | sed 's/:[0-9][0-9]*$$//' > $@.tmp; ${CHECK_RESULT_RUN}

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

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *-good.output *.cmp

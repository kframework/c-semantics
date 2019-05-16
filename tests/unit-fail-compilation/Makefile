TUS = $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
CPP_TESTS = $(filter-out %.c, ${TESTS})
C_TESTS = $(filter-out %.C, ${TESTS})
KCC_COMPILED_TESTS = ${TESTS:=.kcc.out}
TEST_COMPARISON = ${TESTS:=.cmp}
CPP_TEST_COMPARISON = ${CPP_TESTS:=.cmp}
C_TEST_COMPARISON = ${C_TESTS:=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 1 -o $$? -eq 255 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

KCC ?= ../../dist/kcc
KXX ?= ../../dist/k++

KCCFLAGS = -fno-diagnostics-color -Werror -Wfatal-errors

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${KCC_COMPILED_TESTS}

comparison: ${TEST_COMPARISON}

c-comparison: ${C_TEST_COMPARISON}
cpp-comparison: ${CPP_TEST_COMPARISON}

%-link1.c.kcc.out: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) $(KCCFLAGS) $^ > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}
	@sed -i "/kcc -d/d" $@

%-link1.C.kcc.out: %-link1.C %-link2.C
	@echo -n "Compiling $^... "
	@$(KXX) $(KCCFLAGS) $^ > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}
	@sed -i "/k++ -d/d" $@

%.c.kcc.out: %.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) $< > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}
	@sed -i "/kcc -d/d" $@

%.C.kcc.out: %.C
	@echo -n "Compiling $<... "
	@$(KXX) -fno-native-compilation $(KCCFLAGS) $< > $@.tmp 2>&1; ${CHECK_RESULT_COMPILE}
	@sed -i "/k++ -d/d" $@


%.cmp: %.kcc.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.cmp

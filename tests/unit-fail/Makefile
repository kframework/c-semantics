include ../check-results.mk

TUS := $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES :=
TESTS := $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
CPP_TESTS := $(filter-out %.c, ${TESTS})
C_TESTS := $(filter-out %.C, ${TESTS})
GCC_COMPILED_TESTS := ${TESTS:=.gcc}
KCC_COMPILED_TESTS := ${TESTS:=.kcc}
C_KCC_COMPILED_TESTS := ${C_TESTS:=.kcc}
TEST_RESULTS := ${TESTS:=.out}
TEST_COMPARISON := ${TESTS:=.cmp}
CPP_TEST_COMPARISON := ${CPP_TESTS:=.cmp}
C_TEST_COMPARISON := ${C_TESTS:=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
# CHECK_RESULT_RUN = if [ $$? -eq 139 ] ; then echo "passed $<"; cat $@.tmp > $@; rm $@.tmp; else echo "failed $<"; cat $@.tmp; exit 1; fi
CHECK_RESULT_DIFF = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

KCC := ../../dist/kcc
KXX := ../../dist/k++

KCCFLAGS := -frecover-all-errors -fno-diagnostics-color

.PRECIOUS: %.kcc %.out

.PHONY: test
test: ${TEST_RESULTS}

.PHONY: comparison
comparison: ${TEST_COMPARISON}

.PHONY: c-comparison
c-comparison: ${C_TEST_COMPARISON}

.PHONY: cpp-comparison
cpp-comparison: ${CPP_TEST_COMPARISON}

.PHONY: compile
compile: ${KCC_COMPILED_TESTS}

.PHONY: c-compile
c-compile: ${C_KCC_COMPILED_TESTS}

# some versions of GNU make define the following pattern rule using cp. We need
# to disable this, otherwise we will skip compilation and things will break.
%.out: %

%.out: %.kcc
	@echo -n "Running $<... "
	@-./$< > $@ 2>&1

%-link1.c.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) $(KCCFLAGS) -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.C.kcc: %-link1.C %-link2.C
	@echo -n "Compiling $^... "
	@$(KXX) $(KCCFLAGS) -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.c.kcc: %.c
	@echo -n "Compiling $<... "
	@$(KCC) $(KCCFLAGS) -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.C.kcc: %.C
	@echo -n "Compiling $<... "
	@$(KXX) $(KCCFLAGS) -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_DIFF}

.PHONY: clean
clean:
	rm -rf *.out *.kcc *.tmp *.cmp

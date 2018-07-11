TUS = $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES=
TESTS = $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
CPP_TESTS = $(filter-out %.c, ${TESTS})
C_TESTS = $(filter-out %.C, ${TESTS})
GCC_COMPILED_TESTS = ${TESTS:=.gcc}
KCC_COMPILED_TESTS = ${TESTS:=.kcc}
TEST_RESULTS = ${TESTS:=.out}
REFERENCE_TEST_RESULTS = ${TESTS:=.ref}
TEST_COMPARISON = ${TESTS:=.cmp}
CPP_TEST_COMPARISON = ${CPP_TESTS:=.cmp}
C_TEST_COMPARISON = ${C_TESTS:=.cmp}

ifeq ($(origin CC),default)
	CC = gcc-4.9
endif

ifeq ($(origin CXX),default)
	CXX=g++-5
endif

KCC=../../dist/kcc
KXX=../../dist/k++

LDFLAGS=-pthread

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PHONY: test clean reference comparison
.PRECIOUS: %.kcc %.out

test: ${TEST_RESULTS}

reference: ${REFERENCE_TEST_RESULTS}

comparison: ${TEST_COMPARISON}

c-comparison: ${C_TEST_COMPARISON}
cpp-comparison: ${CPP_TEST_COMPARISON}

compile: ${KCC_COMPILED_TESTS}

zeroinit-class-padding.C.cmp:
	@echo $@: disabled due to GCC bug 85548

# some versions of GNU make define the following pattern rule using cp. We need
# to disable this, otherwise we will skip compilation and things will break.
%.out: %

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-link1.c.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) -fno-native-compilation -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.C.kcc: %-link1.C %-link2.C
	@echo -n "Compiling $^... "
	@$(KXX) -fno-native-compilation -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.c.kcc: %.c
	@echo -n "Compiling $<... "
	@$(KCC) -fno-native-compilation -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}
%.C.kcc: %.C
	@echo -n "Compiling $<... "
	@$(KXX) -fno-native-compilation -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.c.gcc: %-link1.c %-link2.c
	@echo -n "Compiling $^ (reference)... "
	@$(CC) $(LDFLAGS) -std=c11 -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.C.gcc: %-link1.C %-link2.C
	@echo -n "Compiling $^ (reference)... "
	@$(CXX) -std=c++14 -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.c.gcc: %.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) $(LDFLAGS) -std=c11 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}
%.C.gcc: %.C
	@echo -n "Compiling $< (reference)... "
	@$(CXX) -std=c++14 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff --strip-trailing-cr $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp

clean-c:
	rm -f *.c.*

clean-cpp:
	rm -f *.C.*

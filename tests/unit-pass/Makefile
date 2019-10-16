ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

Makefile: $(ROOT)/../check-results.mk ;

include $(ROOT)/../check-results.mk

TUS := $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES :=
OS_STDIO_EXCLUDES := $(wildcard ./stdio-*.c)
OS_EXCLUDES := $(OS_STDIO_EXCLUDES) \
               ./pthreads-starve.c \
               ./fopen-enoent.c \
               ./oldstyle-main.c \
               ./j016.c \
               ./struct-ini-1.c \
               ./20051113-1.c \
               ./20050502-1.c \
               ./991112-1.c \
               ./string-opt-5.c \
               ./inst-check.c \
               ./930621-1.c \
               ./20040331-1.c \
               ./include-time.C
TESTS := $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
OS_TESTS := $(filter-out $(OS_EXCLUDES), $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS}))))
CPP_TESTS := $(filter-out %.c, ${TESTS})
C_TESTS := $(filter-out %.C, ${TESTS})
GCC_COMPILED_TESTS := ${TESTS:=.gcc}
KCC_COMPILED_TESTS := ${TESTS:=.kcc}
TEST_RESULTS := ${TESTS:=.out}
REFERENCE_TEST_RESULTS := ${TESTS:=.ref}
TEST_COMPARISON := ${TESTS:=.cmp}
OS_TEST_COMPARISON := ${OS_TESTS:=.cmp}
CPP_TEST_COMPARISON := ${CPP_TESTS:=.cmp}
C_TEST_COMPARISON := ${C_TESTS:=.cmp}

CC := gcc-7
CXX := g++-7

KCC := $(ROOT)/../../dist/kcc
KXX := $(ROOT)/../../dist/k++

LDFLAGS := -pthread


.PRECIOUS: %.kcc %.out

.PHONY: test
test: ${TEST_RESULTS}

.PHONY: reference
reference: ${REFERENCE_TEST_RESULTS}

.PHONY: comparison
comparison: ${TEST_COMPARISON}

.PHONY: os-comparison
os-comparison: ${OS_TEST_COMPARISON}

.PHONY: c-comparison
c-comparison: ${C_TEST_COMPARISON}

.PHONY: cpp-comparison
cpp-comparison: ${CPP_TEST_COMPARISON}

.PHONY: compile
compile: ${KCC_COMPILED_TESTS}

zeroinit-class-padding.C.cmp:
	@echo $@: disabled due to GCC bug 85548

# some versions of GNU make define the following pattern rule using cp. We need
# to disable this, otherwise we will skip compilation and things will break.
%.out: %

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN_VERBOSE}

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
	@$(CXX) -std=c++14 -fno-elide-constructors -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff --strip-trailing-cr $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

.PHONY: clean
clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp *.log

.PHONY: clean-c
clean-c:
	rm -f *.c.*

.PHONY: clean-cpp
clean-cpp:
	rm -f *.C.*

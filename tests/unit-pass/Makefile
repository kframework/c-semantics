include ../check-results.mk

TUS := $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES :=
OS_TUS := $(wildcard ./j*.c) $(wildcard ./*.C)
OS_EXCLUDES := ./stdio-scanf11.c \
               ./stdio-scanf12.c \
               ./stdio-scanf15.c \
               ./stdio-bug3.c \
               ./stdio-bug5.c \
               ./stdio-bug6.c \
               ./stdio-bug7.c \
               ./stdio-bug12.c \
               ./stdio-bug18.c \
               ./stdio-bug19.c \
               ./stdio-bug20.c \
               ./stdio-fwrite.c \
               ./stdio-temptest.c \
               ./compcertTSO-2.c \
               ./stdio-ferror.c \
               ./stdio-fgets.c \
               ./stdio-fseek.c \
               ./stdio-scanf-flush.c \
               ./stdio-ungetc.c \
               ./stdio-sscanf.c \
               ./stdio-fileno.c \
               ./inst-check.c \
               ./pthreads-starve.c \
               ./fopen-enoent.c \
               ./oldstyle-main.c \
               ./struct-ini-1.c \
               ./j016.c \
               ./include-time.C \
               ./new23.C \
               ./new41.C
TESTS := $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${TUS})))
OS_TESTS := $(filter-out $(OS_EXCLUDES), $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, ${OS_TUS}))))
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

ifeq ($(origin CC),default)
	CC := gcc-7
endif

ifeq ($(origin CXX),default)
	CXX := g++-7
endif

KCC := ../../dist/kcc
KXX := ../../dist/k++

LDFLAGS := -pthread


.PRECIOUS: %.kcc %.out

.PHONY: test
test: ${TEST_RESULTS}

.PHONY: reference
reference: ${REFERENCE_TEST_RESULTS}

.PHONY: comparison
comparison: ${TEST_COMPARISON}
os-comparison: ${OS_TEST_COMPARISON}

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
	@$(CXX) -std=c++14 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff --strip-trailing-cr $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

.PHONY: clean
clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp

.PHONY: clean-c
clean-c:
	rm -f *.c.*

.PHONY: clean-cpp
clean-cpp:
	rm -f *.C.*

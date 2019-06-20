include ../../check-results.mk

TUS := $(wildcard ./*.c) $(wildcard ./*.C)
EXCLUDES :=
TESTS := $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link2.C, $(filter-out %-link3.C, ${TUS}))))
GCC_COMPILED_TESTS := ${TESTS:.c=.gcc}
KCC_COMPILED_TESTS := ${TESTS:.c=.kcc}
TEST_RESULTS := ${TESTS:.c=.out}
REFERENCE_TEST_RESULTS := ${TESTS:.C=.ref}
TEST_COMPARISON := ${TESTS:.c=.cmp}

KCC := ../../../dist/kcc
KXX := ../../../dist/k++


.PRECIOUS: %.kcc %.out

.PHONY: test
test: ${TEST_RESULTS}

.PHONY: reference
reference: ${REFERENCE_TEST_RESULTS}

.PHONY: comparison
comparison: ${TEST_COMPARISON}

.PHONY: compile
compile: ${KCC_COMPILED_TESTS}

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-link1.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) -o $@ $^ > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.kcc: %-link1.C %-link2.C
	@echo -n "Compiling $^... "
	@$(KCC) -o $@ $^ > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@$(KCC) -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}
%.kcc: %.C
	@echo -n "Compiling $<... "
	@$(KCC) -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.gcc: %-link1.c %-link2.c
	@echo -n "Compiling $^ (reference)... "
	@$(CC) -std=c11 -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-link1.gcc: %-link1.C %-link2.C
	@echo -n "Compiling $^ (reference)... "
	@$(CXX) -std=c++14 -o $@ $^ -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.gcc: %.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) -std=c11 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}
%.gcc: %.C
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

# The location of this makefile.
ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# Intended to come from the environment.
KCC ?= $(realpath $(ROOT)/../../../../../dist/kcc)

TUS := $(wildcard ./*.c)
EXCLUDES :=
TESTS := $(filter-out $(EXCLUDES), $(filter-out %-link2.c, $(filter-out %-link3.c, ${TUS:-link1.c=.c})))
TEST_COMPARISON := ${TESTS:.c=.cmp}

CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; $(KCC) -d -frecover-all-errors -fno-native-compilation -o $@ $<; exit 1; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; exit 1; fi

.PRECIOUS: %.kcc %.out

.PHONY: comparison
comparison: ${TEST_COMPARISON}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@$(KCC) -frecover-all-errors -fno-native-compilation -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.kcc: %-link1.c %-link2.c
	@echo -n "Compiling $^... "
	@$(KCC) -frecover-all-errors -fno-native-compilation -o $@ $^ > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.out: %-good.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-bad-static.out: %-bad-static.kcc
	@cp $<.out $@

%-bad.out: %-bad.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%-good.gcc: %-good.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) -std=c11 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.gcc: %-good-link1.c %-good-link2.c
	@echo -n "Compiling $< (reference)... "
	@$(CC) -std=c11 -o $@ $< -lm > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%-good.output: %-good.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.output
	@echo -n "Comparing $^... "
	@diff --strip-trailing-cr $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

.PHONY: clean
clean:
	rm -rf *.out *.kcc *.tmp *.gcc *-good.output *.cmp

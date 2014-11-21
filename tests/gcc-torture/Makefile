TESTS = $(wildcard ./*.c)
GCC_COMPILED_TESTS = ${TESTS:.c=.gcc}
KCC_COMPILED_TESTS = ${TESTS:.c=.kcc}
TEST_RESULTS = ${TESTS:.c=.out}
REFERENCE_TEST_RESULTS = ${TESTS:.c=.ref}
TEST_COMPARISON = ${TESTS:.c=.cmp}

GCC = gcc -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99
CHECK_RESULT_COMPILE = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp.out $@.out; else echo "failed $<"; cat $@.tmp.out; fi
CHECK_RESULT_RUN = if [ $$? -eq 0 ] ; then echo "passed $<"; mv $@.tmp $@; else echo "failed $<"; cat $@.tmp; fi

.PHONY: test clean reference

export K_NAILGUN := true

test: start-server ${TEST_RESULTS}

reference: ${REFERENCE_TEST_RESULTS}

compare: start-server ${TEST_COMPARISON}

start-server:
	kserver > kserver.log 2>&1 &

%.out: %.kcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.kcc: %.c
	@echo -n "Compiling $<... "
	@kcc -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.gcc: %.c
	@echo -n "Compiling $< (reference)... "
	@${GCC} -o $@ $< > $@.tmp.out 2>&1; ${CHECK_RESULT_COMPILE}

%.ref: %.gcc
	@echo -n "Running $<... "
	@./$< > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

%.cmp: %.out %.ref
	@echo -n "Comparing $^... "
	@diff $^ > $@.tmp 2>&1; ${CHECK_RESULT_RUN}

clean:
	rm -rf *.out *.kcc *.tmp *.gcc *.ref *.cmp kserver.log
	stop-kserver

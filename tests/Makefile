PARSER ?= ../dist/cparser

GOOD_DIRECTORIES = buildTests
FAIL_DIRECTORIES = shouldFail unspecified-shouldFail
MUSTFAIL_DIRECTORIES = mustFail
INTEGRATION_DIRECTORIES = integration
UNIT_DIRECTORIES = unitTests
THIRD_PARTY_DIRECTORIES = lcc-tests clight-tests-unit cil llvm-regression llvm-unit
TORTURE_DIRECTORIES = gcc-torture
CSMITH_DIRECTORIES = csmith
ALL_DIRECTORIES = $(MUSTFAIL_DIRECTORIES) $(GOOD_DIRECTORIES) $(FAIL_DIRECTORIES) $(INTEGRATION_DIRECTORIES) $(UNIT_DIRECTORIES) $(TORTURE_DIRECTORIES) $(THIRD_PARTY_DIRECTORIES)

#ALL_FILES = $(foreach var, $(GOOD_DIRECTORIES), $(wildcard $(var)/*.c))
#ALL_PROGRAMS_BASIC = $(basename $(ALL_FILES))
#ALL_PROGRAMS = $(filter-out $(DONT_WORK), $(ALL_PROGRAMS_BASIC))
#ALL_TARGETS = $(foreach var,  $(filter-out $(DONT_RUN), $(ALL_PROGRAMS)), $(dir $(var))compare-$(notdir $(var)).pass)
GOOD_TARGETS = $(foreach var,  $(GOOD_DIRECTORIES), results-pass-$(var).xml)
FAIL_TARGETS = $(foreach var,  $(FAIL_DIRECTORIES), results-fail-$(var).xml)
MUSTFAIL_TARGETS = $(foreach var,  $(MUSTFAIL_DIRECTORIES), results-fail-$(var).xml)
INTEGRATION_TARGETS = $(foreach var, $(INTEGRATION_DIRECTORIES), results-pass-$(var).xml)
UNIT_TARGETS = $(foreach var, $(UNIT_DIRECTORIES), results-pass-$(var).xml)
THIRD_PARTY_TARGETS = $(foreach var, $(THIRD_PARTY_DIRECTORIES), results-pass-$(var).xml)
TORTURE_TARGETS = $(foreach var, $(TORTURE_DIRECTORIES), results-pass-$(var).xml)
CSMITH_TARGETS = $(foreach var, $(CSMITH_DIRECTORIES), results-pass-$(var).xml)

CLEAN_TARGETS = $(foreach var, $(ALL_DIRECTORIES), clean-$(var))

all: $(PARSER) test 

integration: $(INTEGRATION_TARGETS)

unit: $(MUSTFAIL_TARGETS) adhoc $(UNIT_TARGETS)

adhoc: results-adhoc.xml

results-adhoc.xml:
	@perl adhocTests.pl

thirdParty: $(THIRD_PARTY_TARGETS)

torture: $(TORTURE_TARGETS)

csmith: $(CSMITH_TARGETS)

#.INTERMEDIATE: test-%.kcc test-%.gcc output-% retval-%
#.PRECIOUS: test-%.kcc test-%.gcc output-% retval-% compare-%.pass
.PHONY: all test clean good shouldFail clean-% adhoc csmith torture thirdParty integration

test: good
	@$(MAKE) -C ../semantics dynamic-c-expressions.pdf
	@echo "Tests finished running."
	
good: $(GOOD_TARGETS)

shouldFail: $(FAIL_TARGETS)

results-pass-%.xml:
	@perl runtest.pl -p $*
	
results-fail-%.xml:
	@perl runtest.pl -f $*
		
clean: $(CLEAN_TARGETS) clean-./
	
clean-%:
	rm -f ./$*/*.parsed.c ./$*/*.compcert.c ./$*/*.gcc ./$*/*.kcc ./$*/*.o ./$*/*.pass ./$*/*.tmp ./$*/*.log ./$*/*.cil ./$*/*-gen.maude ./$*/*.gen.maude ./$*/*.pre.gen ./$*/*.prepre.gen ./$*/*.xml ./$*/a.out ./$*/*.kdump

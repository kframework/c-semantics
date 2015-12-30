.PHONY: check implementation-defined undefined unspecified clean

check:	implementation-defined undefined unspecified
clean:
	$(MAKE) -C implementation-defined clean
	$(MAKE) -C undefined clean
	$(MAKE) -C unspecified clean

implementation-defined undefined unspecified:
	$(MAKE) -C $@ comparison

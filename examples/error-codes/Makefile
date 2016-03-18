.PHONY: check implementation-defined undefined unspecified posix lint clean violates-constraint/nonfatal

check:	implementation-defined undefined unspecified posix lint violates-constraint/nonfatal
clean:
	$(MAKE) -C implementation-defined clean
	$(MAKE) -C undefined clean
	$(MAKE) -C unspecified clean
	$(MAKE) -C posix clean
	$(MAKE) -C lint clean
	$(MAKE) -C violates-constraint/nontfatal clean

implementation-defined undefined unspecified posix lint violates-constraint/nonfatal:
	$(MAKE) -C $@ comparison

.PHONY: check implementation-defined undefined unspecified posix lint clean violates-constraint/nonfatal violates-constraint/fatal

check:	implementation-defined undefined unspecified posix lint violates-constraint/nonfatal violates-constraint/fatal
clean:
	$(MAKE) -C implementation-defined clean
	$(MAKE) -C undefined clean
	$(MAKE) -C unspecified clean
	$(MAKE) -C posix clean
	$(MAKE) -C lint clean
	$(MAKE) -C violates-constraint/nonfatal clean
	$(MAKE) -C violates-constraint/fatal clean

implementation-defined undefined unspecified posix lint violates-constraint/nonfatal violates-constraint/fatal:
	$(MAKE) -C $@ comparison

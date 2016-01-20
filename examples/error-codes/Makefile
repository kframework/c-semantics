.PHONY: check implementation-defined undefined unspecified posix lint clean

check:	implementation-defined undefined unspecified posix lint
clean:
	$(MAKE) -C implementation-defined clean
	$(MAKE) -C undefined clean
	$(MAKE) -C unspecified clean
	$(MAKE) -C posix clean
	$(MAKE) -C lint clean

implementation-defined undefined unspecified posix lint:
	$(MAKE) -C $@ comparison

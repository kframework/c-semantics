#include <stdio.h>
int main(void) {
	char buf[300];
	int retval;
	retval = sprintf(buf, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
}

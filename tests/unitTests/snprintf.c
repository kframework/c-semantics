#include <stdio.h>
int main(void) {
	char buf[300] = "foo";
	int retval;
	retval = snprintf(0, 0, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 0, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 5, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 15, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 16, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 17, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
	retval = snprintf(buf, 30, "%d, %x, %X", 35, (unsigned int)-35, 43);
	printf("%d: %s\n", retval, buf);
}

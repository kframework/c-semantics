#include <stdlib.h>

int atoi(const char *c) {
	int res = 0;
	while (*c >= '0' && *c <= '9')
		res = res * 10 + *c++ - '0';
	return res;
}

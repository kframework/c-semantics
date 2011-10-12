#include <stdarg.h>

int f(int x, int y) {
	va_list ap;
	va_start(ap, x);
	va_end(ap);
	return 0;
}
int main(void) {
	f(5, 6);
	return 0;
}

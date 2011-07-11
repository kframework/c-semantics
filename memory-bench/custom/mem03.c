#include <stdarg.h>
#include <stdio.h>

int main(void) 	{
	int *p;
	int y = 0;
	if (1) {
		int x = 5;
		p = &x;
	}
	int r = *(p = &y) + *p;
	//int r = *p + *(p = &y);
	return r;
}

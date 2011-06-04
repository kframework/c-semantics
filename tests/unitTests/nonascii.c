// this test is based on wchar_t-1.c from the gcc torture tests
#include <stddef.h>
#include <stdio.h>
wchar_t x[] = L"Ω";
wchar_t y = L'Ω';

int main (void) {
	printf("size of 2 element string is %d, and size of element is %d\n", (int)sizeof(x), (int)sizeof(wchar_t));
	if (x[0] == L'Ω') {
		printf("first element is same\n");
	} else {
		printf("first element is different\n");
	}
	if (x[1] == L'\0') {
		printf("terminator element is same\n");
	} else {
		printf("terminator element is different\n");
	}
	if (y == L'Ω') {
		printf("chars are same\n");
	} else {
		printf("chars are different\n");
	}
}

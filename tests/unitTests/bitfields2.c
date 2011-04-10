// This test is based on a test from the GCC C torture tests.
#include <stdio.h>

int main(void) {
	struct x { signed int i : 7; unsigned int u : 7; } bit;

	unsigned int u;
	int i;
	unsigned int unsigned_result = -13U % 61;
	int signed_result = -13 % 61;

	bit.u = 61, u = 61; 
	bit.i = -13, i = -13;

	printf("i=%d, u=%d\n", i, u);
	printf("bit.i=%d, bit.u=%d\n", bit.i, bit.u);
	printf("unsigned_result=%d, signed_result=%d\n", unsigned_result, signed_result);
	
	printf("i %% u = %d\n", i % u);
	if (i % u != unsigned_result) {
		printf("i %% u != unsigned_result\n");
	}
	
	printf("i %% (unsigned int) u = %d\n", i % (unsigned int) u);
	if (i % (unsigned int) u != unsigned_result) {
		printf("i %% (unsigned int) u != unsigned_result\n");
	}

	/* Somewhat counter-intuitively, bit.u is promoted to an int, making the operands and result an int.  */
	printf("i %% bit.u = %d\n", i % bit.u);
	if (i % bit.u != signed_result) {
		printf("i %% bit.u != signed_result\n");
	}

	printf("bit.i %% bit.u = %d\n", bit.i % bit.u);
	if (bit.i % bit.u != signed_result) {
		printf("bit.i %% bit.u != signed_result\n");
	}

	/* But with a cast to unsigned int, the unsigned int is promoted to itself as a no-op, and the operands and result are unsigned. */
	printf("i %% (unsigned int) bit.u = %d\n", i % (unsigned int) bit.u);
	if (i % (unsigned int) bit.u != unsigned_result) {
		printf("i %% (unsigned int) bit.u != unsigned_result\n");
	}

	printf("bit.i %% (unsigned int) bit.u = %d\n", bit.i % (unsigned int) bit.u);
	if (bit.i % (unsigned int) bit.u != unsigned_result) {
		printf("bit.i %% (unsigned int) bit.u != unsigned_result\n");
	}

  return 0;
}

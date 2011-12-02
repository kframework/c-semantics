#include <stdio.h>
#include <stdlib.h>

/* C1X-1516 6.2.4:6
For such an object that does not have a variable length array type, its lifetime extends from entry into the block with which it is associated until execution of that block ends in any way. (Entering an enclosed block or calling a function suspends, but does not end, execution of the current block.) If the block is entered recursively, a new instance of the object is created each time. The initial value of the object is indeterminate. If an initialization is specified for the object, it is performed each time the declaration or compound literal is reached in the execution of the block; otherwise, the value becomes indeterminate each time the declaration is reached. 
*/
int f1(void) {
	int* p = NULL;
	label:
	if (p) { 
		printf("1i = %d\n", *p);
		goto end;
	}
	int i;
	if (!p) { i = 16; }
	p = &i;
	goto label;
	end:
	return 0;
}

int f2(void) {
	int count = 0;
	int* p = NULL;
	label:
	if (p) { 
		printf("2i = %d\n", *p);
	}
	int i;
	if (count < 3) {
		i = count;
		count++;
	} else {
		goto end;
	}
	if (p == NULL) { p = &i; }
	goto label;
	end:
	return 0;
}

int f3(void) {
	int count = 0;
	int* p = NULL;
	label:
	if (p) { 
		printf("3i = %d\n", *p);
	}
	int i = 5;
	if (count < 3) {
		count++;
		if (p == NULL) { p = &i; }
		goto label;
	}
	return 0;
}

int f4(void) {
	int count = 0;
	label:;
	int i;
	if (count < 3) {
		count++;
		goto label;
	}
	return 0;
}


int main(void) {
	f1();
	f2();
	f3();
	f4();
	return 0;
}

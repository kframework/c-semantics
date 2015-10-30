// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

#include <stdio.h>

struct v {
	struct { long k, l; } w;
	int m;
} v1;

int main(void){
	// v1.i = 2;
	// printf("%d\n", v1.i);
	v1.w.k = 3; // invalid: inner structure is not anonymous
	printf("%ld\n", v1.w.k);
	// v1.w.k = 5;
	// printf("%d\n", v1.w.k);
	return 0;
}

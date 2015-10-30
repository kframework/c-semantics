// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

// kcc-assert-error(00033)
int main(void) {
	int a;
	int b;
	if (&a >= &a) {
		return 0;
	}
}

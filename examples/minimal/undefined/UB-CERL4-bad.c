// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

// kcc-assert-error(00033)
int main(void) {
	int a;
	int b;
	if (&a >= &b) {
		return 0;
	}
}

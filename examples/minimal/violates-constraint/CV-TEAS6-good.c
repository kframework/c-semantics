// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

// kcc-assert-error(00035)
#include <stdio.h>

int good(void){
	const int x = 0;
	return x;
}

int main(void){
	good();
	return 0;
}

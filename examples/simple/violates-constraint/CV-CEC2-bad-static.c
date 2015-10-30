// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

// kcc-assert-error(00041)

int main(void){
	5 ? (void)5 : (signed char)6;
}

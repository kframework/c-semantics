// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

static int a = 1;
int main() {
	//Identifier a now has internal linkage with extern.
	extern int a;
}

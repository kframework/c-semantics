// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

union { int i; int c; } ic;
int main(void){ 
	ic.c = ic.i;
	return ic.c;
}

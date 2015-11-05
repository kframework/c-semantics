// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(int * restrict p, int * restrict q) {
	p = q;
	return 5;
}

int main(void){
	int p = 5;
	int q = 6;
	f(&p, &q);
	return 0;
}

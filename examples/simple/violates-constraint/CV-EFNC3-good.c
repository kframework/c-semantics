// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

// this example is loosely based on an example in sentence 1509 in http://www.knosof.co.uk/cbook/cbook.html
int g();

int f(int * restrict p) {
	g(p);
	return *p;
}

int main(void){
	int x = 5;
	return f(&x) == 5;
}

int g(int * p) {
	*p = 10;
	return 0;
}

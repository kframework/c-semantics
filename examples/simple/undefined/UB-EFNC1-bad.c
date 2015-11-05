// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(int x){
	return x;
}

int main(void){
	int (*x)(double) = (int (*)(double))&f;
	return x(0);
}

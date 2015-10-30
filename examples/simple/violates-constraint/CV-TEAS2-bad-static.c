// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int f(int x){
	return x;
}

int main(void){
	int (*x)(double) = &f;
	return x(5);
}

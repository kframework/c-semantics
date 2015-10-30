// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int f(int x){
	return x;
}

int main(void){
	int (*x)(int) = &f;
	return x(0);
}

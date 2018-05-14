// Copyright (c) 2015-2018 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(int x){
	return x;
}

int main(void){
	int (*x)(double);
      x = &f;
	return x(5);
}

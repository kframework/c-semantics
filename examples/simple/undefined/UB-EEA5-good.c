// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int f(int x[static 5]){
	return 0;
}

int main(void){
	int a[10] = {0};
	f(a);
	return 0;
}

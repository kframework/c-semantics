// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main(void){
	char a[5] = {1, 2, 3, 4, 5};
	*(char*)(&a[4]);
	return 0;
}


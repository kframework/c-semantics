// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main(void){
	char a[5] = {1, 2, 3, 4, 5};
	return *(int*)(&a[4]);
}


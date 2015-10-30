// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main(void){
	int x = 0;
	{
		int x = 5;
	}
	x;
	return 0;
}

// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

int main(void){
	float x = 5;
	float* p = (float*)&x;
	*p;
}

// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main(void){
	float x = 5;
	float* p = (float*)&x;
	*p;
}

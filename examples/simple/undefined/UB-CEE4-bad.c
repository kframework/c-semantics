// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main(void){
	int* p;
	{
		int x = 5;
		p = &x;
	} // the memory for x should not be accessible now
	int y = *p;
	return 0;
}

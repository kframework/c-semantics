// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int main(void){
	int* p;
	{
		int x = 5;
		p = &x;
	} // the memory for x should not be accessible now
	int y = 0;
	return 0;
}

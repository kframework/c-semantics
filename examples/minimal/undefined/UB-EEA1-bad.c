// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

union { int i; char c; } ic;
int main(void){ 
	ic.c = ic.i;
	return ic.c;
}

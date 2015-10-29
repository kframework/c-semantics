// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int f(int x){
	return x;
}

int main(void){
	int (*x)(int) = &f;
	return x(0);
}

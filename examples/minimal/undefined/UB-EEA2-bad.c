// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

int f(int * restrict p, int * restrict q) {
	p = q;
	return 5;
}

int main(void){
	int p = 5;
	int q = 6;
	f(&p, &q);
	return 0;
}

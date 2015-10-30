// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

struct _s {
	int x;
	int a[];
} s;

int main(void){
	&(s.a[0]);
}

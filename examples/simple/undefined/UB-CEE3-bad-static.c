// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

struct _s {
	int x;
	int a[];
} s;

int main(void){
	&(s.a[1]);
}

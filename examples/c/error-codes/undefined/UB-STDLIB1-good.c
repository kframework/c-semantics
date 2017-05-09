// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <stdlib.h>
int main(void){
	unsigned char a[5] = "abc";
	unsigned char* p = realloc(0, 5);
	p[0] = 'a';
	return 0;
}

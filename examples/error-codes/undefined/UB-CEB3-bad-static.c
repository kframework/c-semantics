// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <limits.h>
int main(void){
	return (int)1 << sizeof(int) * CHAR_BIT;
}

// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

#include <limits.h>
int main(void){
	return (int)1 >> (sizeof(int) - 1) * CHAR_BIT;
}

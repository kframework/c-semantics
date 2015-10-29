// Copyright (c) 2015 RV-Match Team. All Rights Reserved.

#include <limits.h>
int main(void){
	(int)1 << (sizeof(int) - 1) * CHAR_BIT;
	return 0;
}

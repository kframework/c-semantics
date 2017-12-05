// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int foo (int *p1, int *p2) {
	return (*p1)++ + (*p2)++;
}

int main (void) {
      int x = 2;
      int result = (x = 1) + (x = 2);
	int a = 0;
	foo (&a, &a);
	return 0;
}

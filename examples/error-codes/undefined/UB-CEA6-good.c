// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int x;
union {
  short x;
  int y;
} foo;
int main(void){
  foo.y = 1;
  int y = 5 + foo.y;
  return 0;
}

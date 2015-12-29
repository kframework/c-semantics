// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int f(x, x)
      int x, y;
{
      return x;
}

int main(void) {
      return f(0, 0);
}

// Copyright (c) 2015 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

_Atomic union u {
      int x;
} u;

int main(void) {
      return u.x;
}

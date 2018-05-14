// Copyright (c) 2015-2018 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

struct e {
      int x;
};

struct {
      short x;
      struct e y;
      union { struct e u1; double u2; } z;
      long w;
} s;

int main(void){
      struct e t;

      s.x = 2;
      s.y = t;
      s.z.u2 = 2.0;
      s.z.u2;
      s.z.u1;
      s.w = 2;
}

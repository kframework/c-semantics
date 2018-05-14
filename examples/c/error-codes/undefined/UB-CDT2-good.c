// Copyright (c) 2015-2018 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

union e {
      int x;
};

struct {
      short x;
      union e y;
      union { union e u1; double u2; } z;
      long w;
} s;

int main(void){
      union e t;

      s.x = 2;
      s.y = t;
      s.z.u2 = 2.0;
      s.z.u2;
      s.z.u1;
      s.w = 2;
}

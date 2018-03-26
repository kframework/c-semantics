// Copyright (c) 2018 Runtime Verification, Inc. (RV-Match team). All Rights Reserved.

int main(void){
      union { int a; int b[2]; } u;
      u.b[1] = 1;
      u.a = 2;

      5 / u.b[0];
}

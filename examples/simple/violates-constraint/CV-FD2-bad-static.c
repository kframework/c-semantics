// Copyright (c) 2015 Runtime Verification, Inc. All Rights Reserved.

typedef int arr[5];

int x[5];

arr foo() {
  return x;
}

int main() {
  return 0;
}

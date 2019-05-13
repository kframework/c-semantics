

int foo(double (&&x)[5]= {1, 2, 3, 4, 5}) { return 1; }

int foo(double (&&x)[4] = {1, 2, 3, 4}) { return 0; }

int main() {
  return foo();
}
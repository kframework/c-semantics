union Union { int a; char b = 0; };

int main() {
  Union x = {};
  x.a = 1023;
  return x.b == 0;
}

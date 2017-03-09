
int main() {
  static union { int a; char b; float c; };
  a = 0;
  b = 'J';
  return a == 0;
}
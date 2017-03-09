static union { int a; char b; };

int main() {
  a = 0;
  b = 'J';
  return a == 0;
}
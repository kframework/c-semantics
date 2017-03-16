
union { int a; char b; } x;

int main() {
  x.a = 0;
  x.b = 'J';
  return x.a == 0;
}
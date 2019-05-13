union Union { int a; char b; };

int main() {
  Union x = { 0 };
  x.b = 'J';
  return x.a == 0;
}

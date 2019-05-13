struct B { int x, y; };
struct A { int x; B y; };
A o[] = {1, {2, 3}, 4, 5};
int main() {
  return o[1].y.x - 5;
}
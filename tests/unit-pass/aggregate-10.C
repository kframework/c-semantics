struct A { int x, y, z; };
struct B { int x, y; A z = {1, 2, 3}; };
int main() {
  B x[] = {5, 6, 7, 8};
  return x[0].z.z;
}
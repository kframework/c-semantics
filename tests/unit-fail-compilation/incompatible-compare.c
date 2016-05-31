struct { int x; float y; } s;
int main() {
  int *a = &s.x;
  float *b = &s.y;
  a < b;
}

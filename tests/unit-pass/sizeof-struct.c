int main() {
  int x = 0;
  if (x == x)
    return (0);

  return sizeof(struct { int x; });
}

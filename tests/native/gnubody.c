int main() {
  int x = ({ int y = 0; y; });
  return x;
}

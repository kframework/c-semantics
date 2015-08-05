int main() {
  int x = ({ int y = 0; y; });
  int z = ({ 0; });
  return x + z;
}

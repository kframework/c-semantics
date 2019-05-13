struct Y {int x, y; };
Y x = {1, 2};
int main() {
  return x.y - 2*x.x;
}
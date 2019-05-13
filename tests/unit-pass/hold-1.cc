int g;
int z[2];
void A() {
  z[g=1] = 0;
}

int main() {
  g = -1;
  A();
}

extern "C" void exit(int);
void doExit(void) {
  exit(0);
}

void (*test)(void);

int main() {
  test = doExit;
  test();
}

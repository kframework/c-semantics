const int x = 0;
int* restrict y = 0;
volatile int z;
_Atomic int w;

int f();
const int g(); // Qualified return types, not function types.
volatile int h();
_Atomic int k();

int main(void) {
      return 0;
}

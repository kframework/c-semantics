extern "C" void abort();

constexpr int a = 1;
const extern int b;
int c = b;
constexpr int b = a;

int main() {
  if (c != 1) abort();
}

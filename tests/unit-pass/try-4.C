extern "C" void abort(void);

int main() {
  int *ptr;
  int error = 1;
  try {
    try {
      throw 0;
    } catch (int &x) {
      ptr = &x;
      throw;
    }
  } catch (int &y) {
    if (ptr != &y) abort();
    error--;
  }
  return error;
}

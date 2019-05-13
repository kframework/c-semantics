int error = 0;
int correct = 0;

extern "C" void abort(void);

int main() {
  try {
    try {
      throw 0;
      error++;
    } catch (const char *) {
      error++;
    }
    error++;
  } catch (int) {
    correct++;
  }

  if (correct != 1) abort();

  return error;
}

int error = 0;
int correct = 0;

extern "C" void abort(void);

int main() {
  try {
    {
      for (;;) {
        try {
          throw 0;
          error++;
        } catch (...) {
          correct++;
          throw 0;
          error++;
        }
        error++;
      }
      error++;
    }
    error++;
  } catch (...) {
    correct++;
  }

  if (correct != 2) abort();

  return error;
}

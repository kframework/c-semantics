int error = 0;
int correct = 0;

extern "C" void abort(void);

void doThrow() {
  {
    throw 0;
    error++;
  }
  error++;
}

int main() {
  try {
    throw 0;
    error++;
  } catch (...) {
    correct++;
  }

  try {
    {
      throw 0;
      error++;
    }
    error++;
  } catch (...) {
    correct++;
  }

  try {
    {
      doThrow();
      error++;
    }
    error++;
  } catch (...) {
    correct++;
  }

  if (correct != 3) abort();

  return error;
}

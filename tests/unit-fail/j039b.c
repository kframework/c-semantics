int f(float x) {
      return (int) x;
}

int main(void) {
      return ((int (*)())f)(0.0);
}


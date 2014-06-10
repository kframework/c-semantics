int f(int x, ...) {
      return x;
}

int main(void) {
      return ((int (*)())f)(0);
}


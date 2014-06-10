int f(int x, int y) {
      return x;
}

int g(double x) {
      return (int) x;
}


int main(void) {
      ((int (*)())f)(0, 0);

      ((int (*)())g)(0.0);

      return 0;
}


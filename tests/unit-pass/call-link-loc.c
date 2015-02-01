int g(int);

int (*f)(int) = g;

int g(int x) { return x - 1; }

int main(void) {
      return f(1);
}


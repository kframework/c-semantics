struct s {
  int x = 0;
  int * y = &x;
};

int main() {
  s z{};
}


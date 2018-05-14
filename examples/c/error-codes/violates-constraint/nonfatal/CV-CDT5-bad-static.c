struct s {
      int a : 8;
      int b : 0;
};

struct s x[1] = {{0, 0}};

int main() {
      x[0].b = 0;
}

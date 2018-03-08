struct s {
      int a : 8;
      int : 0;
};

struct s x[1] = {{0}};

int main() {
      x[0].a = 0;
}

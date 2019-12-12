struct s {
      signed int a : 8;
      signed int b : 0;
};

struct s x[1] = {{0, 0}};

int main() {
      x[0].b = 0;
}

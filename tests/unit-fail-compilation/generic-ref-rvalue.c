struct s { const int x; };

struct s S;

struct s f(void) {
      return S;
}


int main() {
      return _Generic(&(f().x), const int *: -1);
}

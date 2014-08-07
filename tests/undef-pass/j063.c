int main(void) {
      struct s* a;
      struct s (*b)();
      typedef struct s s;

      union u* c;
      union u (*d)();
      typedef union u u;

      struct s { int x; };
      union u { int x; };

      return 0;
}

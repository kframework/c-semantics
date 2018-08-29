struct s {
   struct {
         int a;
         int b;
   };
};

int foo(struct s * z) ;

int main() { return foo((void*)0); }

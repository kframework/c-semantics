struct idk { int xxx; };

struct s {
   struct {
         int a;
         int b;
   };
};

int foo(struct s * z) ;

int foo(struct s * z) { return 0; }

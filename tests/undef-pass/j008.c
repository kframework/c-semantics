static int f(void);

static int f(void){
      return 0;
}

static int g(void){
      return 0;
}
static int g(void);

static int x;
static int x;
extern int y;
static int b;

int main(void){
      return f() + g() + x + b;
}

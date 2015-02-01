int foo();
int bar();

int baz(a)
      int a;
{
      return 0;
}

int main(void){
      return foo(1, 2) + bar() + baz(5);
}

int foo(int a, int b){
      return 0;
}

int bar(){
      return 0;
}

// 6.7.6.3:15: "If one type has a parameter type list and the other type is
// specified by a function declarator that is not part of a function definition
// and that contains an empty function identifier list, the parameter list
// shall not have an ellipses terminator and the type of each parameter shall
// be compatible with the type that results from the application of the default
// argument promotions."

void f();
void f(int x, ...) { }

int main(void) {
      return 0;
}

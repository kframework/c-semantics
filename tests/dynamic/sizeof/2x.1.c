
// "The sizeof operator shall not be applied to an expression that has function
// type or an incomplete type..."

int a[];

int main(void) {
      return sizeof(a);
}

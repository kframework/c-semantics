
// "The sizeof operator shall not be applied to an expression that has function
// type or an incomplete type..."

int main(void) {
      return sizeof(main);
}

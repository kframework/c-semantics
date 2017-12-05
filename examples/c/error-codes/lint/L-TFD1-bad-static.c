void f(void) {
    __asm__ ("" : : : "memory");
}

int main(void) {
      f();
}

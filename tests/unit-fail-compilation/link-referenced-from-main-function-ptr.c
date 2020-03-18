extern int f();

int g(int (*fptr)()) { return (*fptr)(); }

int h() { return f(); }

int main(void) { return g(&h); }

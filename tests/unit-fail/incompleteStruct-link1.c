extern struct foo x;
void bar(struct foo *x);
struct foo * const p = &x;

int main() { bar(p); }

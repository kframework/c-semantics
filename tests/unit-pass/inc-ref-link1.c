extern struct foo x;

void bar(struct foo *x);

struct foo *p = &x;

int main() {
  bar(p);
  return 0;
}

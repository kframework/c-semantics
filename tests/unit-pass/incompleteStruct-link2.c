struct foo { int y; } x;
void bar(struct foo *p) {
  int *p2 = (int *)p;
}

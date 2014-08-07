// From the frama-c value analysis manual/tutorial, p. 37.

struct S { int a; int b; int c; };
struct T { int p; struct S s; };
union U { struct S s; struct T t; } u;

void copy(struct S *p, struct S *q) {
      *p = *q;
}

int main(int c, char **v) {
      u.s.b = 1;
      copy(&u.t.s, &u.s);
      return u.t.s.a + u.t.s.b + u.t.s.c;
}

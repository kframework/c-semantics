int a[2] = {0, 1};
int *p = &(a[0]);

struct {
      int f1;
      int f2;
} b = {0, 1};
int *q = &(b.f1);

struct c_ {
      int f1;
      int f2;
} c = {0, 1};
struct c_ *rr = &c;
int *r = &((&c)->f1);

double d1, d2;
double *ss = &d1;
double *s = (double*)&d1;

int e1, e2;
int *ttt = &e1;
int **tt = &ttt;
int *t1 = &*((int*)0);

int main(void) {
      int *t2 = 0;
      return *p + *q + *r + *s + (t1 != t2);
}

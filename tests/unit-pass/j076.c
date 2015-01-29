unsigned a1[5];
unsigned a1[5];

double a2[5];
double a2[5];

int * restrict a3[5];
int * restrict a3[5];

const int a4[5];
const int a4[5];

int (*a5[5])(int, int);
int (*a5[5])(int, int);

int a6[5 + 2];
int a6[5 + 2];

int a7[];
int a7[5];

int f(int n) { return n; }

int main(void) {
      int n = 3;
      int a[n][6];
      int (*p)[6];

      p = a;

      1 ? (int(*)[f(3)]) 0 : (int (*)[3]) 0;
      return 0;
}

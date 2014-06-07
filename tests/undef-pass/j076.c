unsigned a[5];
unsigned a[5];

double b[5];
double b[5];

int * restrict c[5];
int * restrict c[5];

const int d[5];
const int d[5];

int (*e[5])(int, int);
int (*e[5])(int, int);

int f[5 + 2];
int f[5 + 2];

int g[];
int g[5];

int main(void) {
      return 0;
}

extern int x;

static int *y = &x;

int main(void) {
      return *y;
}

// Based on the Toyota ITC benchmark.
typedef struct {
      signed int ret : 5;
      signed int a : 7;
} s;

int main(void) {
      s s;
      s.a = 0x1f;
      s.ret = s.a;
}

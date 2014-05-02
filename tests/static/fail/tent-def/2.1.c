// 6.9.2p3
// GCC elides this decl because there's no use, but it should probably still be
// an error.
static int x[];

int main(void) {
      return 0;
}

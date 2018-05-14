extern int x;

int main(void) {
  extern int gaga;

  gaga ++; -- gaga;
  ++ gaga; gaga --;
  gaga += 1; gaga -= 1;
  gaga *= 1; gaga /= 1; gaga %= 1;
  gaga <<= 1; gaga >>= 1;
  gaga ^= 1;
  gaga &= 1; gaga |= 1;

  x ++; -- x;
  ++ x; x --;
  x += 1; x -= 1;
  x *= 1; x /= 1; x %= 1;
  x <<= 1; x >>= 1;
  x ^= 1;
  x &= 1; x |= 1;

  return (gaga + x) != 2;
}

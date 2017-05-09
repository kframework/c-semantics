// KCC can also detect buffer overflows within the subobjects of an aggregate
// type. Here we see a struct declared with an array followed by an integer.
// It is correct to assume that the struct is laid out sequentially in memory.
// However, nonetheless, it is a buffer overflow to access the 32nd index of
// this array because it was declared with size 32. This means that we are
// able to detect if a buffer overflow might leak sensitive information
// contained elsewhere in a struct that also contains an array.

struct foo {
  char buffer[32];
  int secret;
};

int idx = 0;

void setIdx() {
  idx = 32;
}

int main() {
  setIdx();
  struct foo x = {0};
  x.secret = 5;
  return x.buffer[idx];
}

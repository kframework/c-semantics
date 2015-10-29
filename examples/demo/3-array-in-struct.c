// KCC can also detect buffer overflows within the subobjects of an aggregate
// type. Here we see a struct declared with an array followed by an integer.
// It is correct to assume that the struct is laid out sequentially in memory.
// However, nonetheless, it is a buffer overflow to access the 32nd indexx of
// this array because it was declared with size 32. This means that we are
// able to detect if a buffer overflow might leak sensitive information
// contained elsewhere in a struct that also contains an array.
struct foo {
  char x[32];
  int secret;
};

int main() {
  struct foo x = {0};
  x.secret = 5;
  return x.x[32];
}

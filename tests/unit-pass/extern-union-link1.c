union U { int word; unsigned char bytes[4]; };
struct S { int a; int b; };

extern union U u;
extern struct S s;

int * x = &s.a;

int main(int argc, char** argv) {
      u.word = 15;
      return u.word - 15;
}

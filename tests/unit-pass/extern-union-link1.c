union u {
      int word;
      unsigned char bytes[4];
};

extern union u foo;

int main(int argc, char** argv) {
      foo.word = 15;
      return foo.word - 15;
}

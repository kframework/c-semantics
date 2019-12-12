int main() {
      return _Generic( 'a', char: 1, int: 2, long: 3, default: 0, signed int: 4) != 2;
}

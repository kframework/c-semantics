int main() {
      return _Generic( (unsigned long) 1 + 2, int: 2, long: 3, default: 0, default: 0) != 0;
}

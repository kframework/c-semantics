int main() {
      return _Generic( (char)'a', int: 2, long: 3, default: 0) != 0;
}

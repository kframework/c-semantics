int main() {
      return _Generic((double const) 0,
                  default: 0,
                  double const: 1);
}

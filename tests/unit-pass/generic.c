extern void abort(void);

// Based on excerpts from DR 423 and 481.
int main() {
      char const* a = _Generic("bla", char*: "blu");
      // char const* b = _Generic("bla", char[4]: "blu");
      char const* c = _Generic((int const){ 0 }, int: "blu");
      // char const* d = _Generic((int const){ 0 }, int const: "blu");
      char const* e = _Generic(+(int const){ 0 }, int: "blu");
      // char const* f = _Generic(+(int const){ 0 }, int const: "blu");
      char const* g = _Generic(abort, void(*)(void): "blu");
      if (_Generic((double const) 0,
                  default: 0,
                  double const: 1))
            abort();
}

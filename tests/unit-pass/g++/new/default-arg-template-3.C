template<class T> T f(T x = T()) {return x;}

int main() {
  return f<int>();
}
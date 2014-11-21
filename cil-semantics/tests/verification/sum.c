unsigned sum(unsigned n) {
  if (n)
    return n + sum(n - 1);
  else
    return 0;
}

int main() {
  return sum(10);
}


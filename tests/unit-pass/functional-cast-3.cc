typedef const int cint;

int f(int a) {
    a = a + 1;
    return a;
}

int main() {
    int x = f(cint());
    return x - 1;
}
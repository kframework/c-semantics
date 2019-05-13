struct C {
    static int f(int = 3);
};

int C::f(int i) {return i;}

int main() {
    return C::f() - 3;
}
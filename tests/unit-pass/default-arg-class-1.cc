struct C {
    static int f(int i = 3) {return i;}
};

int main() {
    return C::f() - 3;
}
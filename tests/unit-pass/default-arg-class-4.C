struct C {
    int g(int i, int j = 99);
};

int C::g(int i = 88, int j) {
    return j - i;
}

int main() {
    C obj;
    return obj.g() - 11;
}
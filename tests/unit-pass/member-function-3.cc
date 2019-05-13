struct s {
    static int x;
    void mf2() volatile, mf3() &&; // can be cv-qualified and reference-qualified
    int get() const volatile {
        return x;
    }
};

int s::x = 0;

int main() {
    s x={};
    return x.get();
}
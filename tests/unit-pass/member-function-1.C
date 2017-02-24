struct s {
    int x;
    int get() {
        return x;
    }
};

int main() {
    s x{0};
    return x.get();
}
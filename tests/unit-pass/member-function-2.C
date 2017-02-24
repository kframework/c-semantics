struct s {
    static int x;
    int get() {
        return x;
    }
};

int s::x = 0;

int main() {
    s x={};
    return x.get();
}
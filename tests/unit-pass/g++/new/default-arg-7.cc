int f(int x, int y) {
    return x - y;
}

int main() {
    int f(int, int = 5);
    return f(5);
}
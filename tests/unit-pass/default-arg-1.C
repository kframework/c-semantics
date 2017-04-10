int point(int x) {return x;}

int point(int = 3);

int main() {
    return point() - 3;
}
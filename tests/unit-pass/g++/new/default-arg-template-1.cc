int r;
template<class T> void f(T x, int y = sizeof(T)) {r = y;}

int main() {
    f('a');
    return r - sizeof(char);
}
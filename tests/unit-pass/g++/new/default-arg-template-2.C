template<class T> int f(T x, int y = sizeof(T)) {return y; }

int main() {
    return f('a') - sizeof(char);
}
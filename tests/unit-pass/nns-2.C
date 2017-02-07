namespace y {
    int a = 0;
}
namespace x {
    namespace y {
        int a = 1;
    }
    int getA() {
        return y::a;
    }
}

int main() {
    return x::getA() - 1;
}
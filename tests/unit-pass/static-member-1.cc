struct c{
    static int x;
};

int c::x = 1;

int main() {
    return c::x - 1;
}
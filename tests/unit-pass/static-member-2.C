struct c{
    static int x;
    static int y;
};

int c::y = 0;
int y = 1;
int c::x = c::y;

int main() {
    return c::x;
}
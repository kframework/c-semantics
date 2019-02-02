class UsingTest {
     using character = char;
     
     public:
     character c;
};

int main() {
     UsingTest t;
     t.c = 'c';

     return 0;
}

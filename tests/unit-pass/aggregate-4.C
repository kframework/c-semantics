//  8.5.1:7
struct S { int a; const char* b; int c; int d = b[a]; };
S ss = { 1, "asdf" };

int main () {
 return ss.d- 's';
}
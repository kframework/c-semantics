extern int f();

int g() { return f(); }

int main(int argc, char* argv[]) { if (argc < 0) return g(); else return 0; }

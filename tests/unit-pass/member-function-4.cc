struct s {
    int field = 0;
    int get() {
        return field;
    }
};

int main() {
    s obj={};
    return obj.get();
}
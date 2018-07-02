int main() {
        int a[2];
        a[1] = 5;
        return (&a + 1)[1];
}


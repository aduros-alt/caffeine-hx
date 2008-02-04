
int be_test() {
    union {
        long l;
        char c[sizeof (long)];
    } testu;
    testu.l = 1;
    return (testu.c[sizeof (long) - 1] == 1);
}


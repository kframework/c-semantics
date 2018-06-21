#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct pair {
        char x;
        int y;
};

static const struct pair zs = {0};

int
main(int argc, char **argv)
{
        struct pair s = zs;

        (void)fwrite(&s, sizeof(s), 1, stdout);

        return EXIT_SUCCESS;
}


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct pair {
        char x;
        int y;
};

static const struct pair zs;

int
main(int argc, char **argv)
{
        (void)fwrite(&zs, sizeof(zs), 1, stdout);

        return EXIT_SUCCESS;
}


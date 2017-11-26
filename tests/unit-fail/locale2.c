#include <locale.h>
#include <string.h>

int main(void) {
      struct lconv* conv = localeconv();

      memset(conv, 0, sizeof(struct lconv));
}

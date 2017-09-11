#include <stdio.h>
#include <wchar.h>

int main(void) {
      char buf[10];
      sprintf(buf, "%lc\n", (wint_t) 80);
}

#include <locale.h>

int main(void) {
      char* loc = setlocale(-1, NULL);

      loc = setlocale(LC_ALL, NULL);

      *loc = 'x';
}

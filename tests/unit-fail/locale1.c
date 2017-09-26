#include <locale.h>

int main(void) {
      char* loc = setlocale(LC_ALL, NULL);

      *loc = 'x';
}

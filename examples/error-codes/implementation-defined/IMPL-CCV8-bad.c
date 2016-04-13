#include<stddef.h>
#include<stdio.h>
int main() {
  char *ptr = NULL;
  for (int i = 0; i < sizeof(char *); i++) {
    char byte = (char)(ptr + i);
    if (byte != 0) {
      printf("Not a null pointer.");
    }
  }
}

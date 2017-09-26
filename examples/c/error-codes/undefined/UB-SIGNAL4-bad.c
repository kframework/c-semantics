#include <signal.h>

int x;

int main(void) {
      signal(SIGUSR1, (void (*)(int))&x);
}

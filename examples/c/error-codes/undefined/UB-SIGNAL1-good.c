#include <signal.h>

void handler(int sig) { return; }

int main(void) {
      signal(SIGUSR1, handler);
}

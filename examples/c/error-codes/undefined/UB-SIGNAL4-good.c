#include <signal.h>

void handler(int sig) { return; }

int main(void) {
      signal(SIGUSR1, SIG_DFL);
      signal(SIGUSR1, SIG_IGN);
      signal(SIGUSR1, handler);
}

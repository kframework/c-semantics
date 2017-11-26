#include <signal.h>
void handler(int sig) { }

int main(void) {
      signal(SIGUSR1, handler);
      signal(SIGUSR2, handler);
      raise(SIGUSR1);
}

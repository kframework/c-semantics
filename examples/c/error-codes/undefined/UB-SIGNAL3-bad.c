#include <signal.h>
void handler(int sig) { }

int main(void) {
      signal(SIGILL, handler);
      raise(SIGILL);
}

// Here we see that KCC is also able to detect undefinedness relating to
// nondeterministic input to the program. If we pass no argument to this
// executable, then argv[0] == 0, so the while loop is not called. If we pass
// an argument less than 9 characters (10 with the null terminator) to the
// executable, the program is well-defined. However, if we pass a longer
// string to argv, a buffer overflow occurs.

// We plan to extend RV-Match in the future with technology that can explore
// the nondeterministic state space of a program based on its input
// conditions, which would eventually allow errors of this type to be detected
// even if the user cannot think of an input that exercises the bug. This will
// be possible still without the need for any false positives.
static void sampleFunc(char *path, char *input) {
  char *argvptr;
  argvptr = input;
  if (argvptr)
    while ((*path++ = *argvptr++) != 0);
  return;
}

int main(int argc, char **argv) {
  char p[10];
  sampleFunc(p, argv[1]);
  return 0;
}


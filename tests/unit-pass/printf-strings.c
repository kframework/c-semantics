#include <stdio.h>
int main(void) {
      char *                   s1  = (char*)                   "one";
      unsigned char *          s2  = (unsigned char*)          "two";
      signed char *            s3  = (signed char*)            "three";

      printf("%s %s %s\n", s1, s2, s3);

      const char *             s4  = (const char*)             "four";
      const unsigned char *    s5  = (const unsigned char*)    "five";
      const signed char *      s6  = (const signed char*)      "six";

      printf("%s %s %s\n", s4, s5, s6);

      volatile char *          s7  = (volatile char*)          "seven";
      volatile unsigned char * s8  = (volatile unsigned char*) "eight";
      volatile signed char *   s9  = (volatile signed char*)   "nine";

      printf("%s %s %s\n", s7, s8, s9);

}

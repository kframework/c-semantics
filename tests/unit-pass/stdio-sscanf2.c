#include <stdio.h>

int main(int argc, char ** argv) {
      char * ent[] = {
            "rdatastructsuf.h",
            "rdatastructpre.h",
            ".",
            "any_255",
            "hs_4",
            "..",
            "ch_3",
            "generic",
            "abc0123_123",
            "in_1",
            "b_123",
            "A_123",
            "1B_123",
            "B_75823",
            "C_75823",
            "B4_75823",
            "C4_75823",
            "test",
            "a_1",
            "z_1",
            "0_1",
            "9_1",
            "-_1",
            "CCCCCCCC_1",
      };

      char * pat[] = {
            "%20[0-9a-z-]_%d",
            "%20[0-1-9a-b-z]_%d",
            "%20[9-0z-a]_%d",
            "%20[B-C3-5B-B]_%d",
            "%[-1-9b-a-]_%d",
            "%[a-a]_%d",
      };

      for (int i = 0; i != (sizeof(ent) / sizeof(ent[0])); ++i) {
            for (int j = 0; j != (sizeof(pat) / sizeof(pat[0])); ++j) {
                  char first[256];
                  int second;

                  int r = sscanf(ent[i], pat[j], first, &second);

                  if (r == 0) {
                        printf("No match (pat: %s): %s\n", pat[j], ent[i]);
                  } else if (r == 1) {
                        printf("Partial match (pat: %s, first: %s): %s\n", pat[j], first, ent[i]);
                  } else {
                        printf("Match (pat: %s, first: %s, second: %d): %s\n", pat[j], first, second, ent[i]);
                  }
            }
      }

      puts("Exiting normally.");
}

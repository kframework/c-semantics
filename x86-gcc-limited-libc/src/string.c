#include <string.h>
#include <stdlib.h>
// nice public domain implementations at http://en.wikibooks.org/wiki/C_Programming/Strings

// from http://clc-wiki.net/wiki/strncpy, public domain
char* strncpy(char* restrict dest, const char* restrict src, size_t n) {
      char *ret = dest;
      do {
            if (!n--) {
                  return ret;
            }
      } while (*dest++ = *src++);
      while (n--) {
            *dest++ = 0;
      }
      return ret;
}

size_t strlen(const char * str) {
      const char *s;
      for (s = str; *s; ++s);
      return(s - str);
}

void* memset(void* dest, int value, size_t len) {
      unsigned char *ptr = (unsigned char*)dest;
      while (len-- > 0) {
            *ptr++ = value;
      }
      return dest;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
void *memchr(const void *s, int c, size_t n) {
      const unsigned char *src = s;
      unsigned char uc = c;
      while (n-- != 0) {
            if (*src == uc) {
                  return (void *) src;
            }
            src++;
      }
      return NULL;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
size_t strcspn(const char *s1, const char *s2) {
      const char *sc1;
      for (sc1 = s1; *sc1 != '\0'; sc1++)
            if (strchr(s2, *sc1) != NULL)
                  return (sc1 - s1);
      return sc1 - s1;            /* terminating nulls match */
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
char *strpbrk(const char *s1, const char *s2) {
      const char *sc1;
      for (sc1 = s1; *sc1 != '\0'; sc1++)
            if (strchr(s2, *sc1) != NULL)
                  return (char *)sc1;
      return NULL;                /* terminating nulls match */
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
size_t strspn(const char *s1, const char *s2) {
      const char *sc1;
      for (sc1 = s1; *sc1 != '\0'; sc1++)
            if (strchr(s2, *sc1) == NULL)
                  return (sc1 - s1);
      return sc1 - s1;            /* terminating nulls don't match */
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
char *strstr(const char *haystack, const char *needle) {
      size_t needlelen;
      /* Check for the null needle case.  */
      if (*needle == '\0')
            return (char *) haystack;
      needlelen = strlen(needle);
      for (; (haystack = strchr(haystack, *needle)) != NULL; haystack++)
            if (strncmp(haystack, needle, needlelen) == 0)
                  return (char *) haystack;
      return NULL;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
char *strtok_r(char *restrict s, const char *restrict delimiters, char **restrict lasts) {
      char *sbegin, *send;
      sbegin = s ? s : *lasts;
      sbegin += strspn(sbegin, delimiters);
      if (*sbegin == '\0') {
            *lasts = "";
            return NULL;
      }
      send = sbegin + strcspn(sbegin, delimiters);
      if (*send != '\0')
            *send++ = '\0';
      *lasts = send;
      return sbegin;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings
char *strtok(char *restrict s1, const char *restrict delimiters) {
      static char *ssave = "";
      return strtok_r(s1, delimiters, &ssave);
}

int strcmp (const char * s1, const char * s2) {
      for(; *s1 == *s2; ++s1, ++s2)
            if(*s1 == 0)
                  return 0;
      return *(unsigned char *)s1 < *(unsigned char *)s2 ? -1 : 1;
}

void *memmove(void *s1, const void *s2, size_t n) {
      unsigned char* tmp = malloc(n);
      memcpy(tmp, s2, n);
      memcpy(s1, tmp, n);
      free(tmp);
      return s1;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings#The_strcat_function
char *strchr(const char *s, int c) {
      /* Scan s for the character.  When this loop is finished,
         s will either point to the end of the string or the
         character we were looking for.  */
      while (*s != '\0' && *s != (char)c)
            s++;
      return ((*s == c) ? (char *) s : NULL);
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings#The_strncmp_function
int strncmp(const char *s1, const char *s2, size_t n) {
      unsigned char uc1, uc2;
      /* Nothing to compare?  Return zero.  */
      if (n == 0)
            return 0;
      /* Loop, comparing bytes.  */
      while (n-- > 0 && *s1 == *s2) {
            /* If we've run out of bytes or hit a null, return zero
               since we already know *s1 == *s2.  */
            if (n == 0 || *s1 == '\0')
                  return 0;
            s1++;
            s2++;
      }
      uc1 = (*(unsigned char *) s1);
      uc2 = (*(unsigned char *) s2);
      return ((uc1 < uc2) ? -1 : (uc1 > uc2));
}


char *(strrchr)(const char *s, int c) {
      const char *last = NULL;
      /* If the character we're looking for is the terminating null,
         we just need to look for that character as there's only one
         of them in the string.  */
      if (c == '\0')
            return strchr(s, c);
      /* Loop through, finding the last match before hitting NULL.  */
      while ((s = strchr(s, c)) != NULL) {
            last = s;
            s++;
      }
      return (char *) last;
}



// from http://www.danielvik.com/2010/02/fast-memcpy-in-c.html
// by Daniel Vik
void* memcpy(void* restrict dest, const void* restrict src, size_t count) {
      unsigned char* dst8 = (unsigned char*)dest;
      unsigned char* src8 = (unsigned char*)src;

      while (count--) {
            *dst8++ = *src8++;
      }
      return dest;
}

// this is public domain
int memcmp(const void *s1, const void *s2, size_t n) {
      const unsigned char *us1 = (const unsigned char *) s1;
      const unsigned char *us2 = (const unsigned char *) s2;
      while (n-- != 0) {
            if (*us1 != *us2) {
                  return (*us1 < *us2) ? -1 : +1;
            }
            us1++;
            us2++;
      }
      return 0;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings#The_strcat_function
char *strcat(char *restrict s1, const char *restrict s2) {
      char *s = s1;
      /* Move s so that it points to the end of s1.  */
      while (*s != '\0')
            s++;
      /* Copy the contents of s2 into the space at the end of s1.  */
      strcpy(s, s2);
      return s1;
}

// public domain implementation from http://en.wikibooks.org/wiki/C_Programming/Strings#The_strncat_function
char *strncat(char *restrict s1, const char *restrict s2, size_t n) {
      char *s = s1;
      /* Loop over the data in s1.  */
      while (*s != '\0')
            s++;
      /* s now points to s1's trailing null character, now copy
         up to n bytes from s1 into s stopping if a null character
         is encountered in s2.
         It is not safe to use strncpy here since it copies EXACTLY n
         characters, NULL padding if necessary.  */
      while (n != 0 && (*s = *s2++) != '\0') {
            n--;
            s++;
      }
      *s = '\0'; // CME: fixed problem here; read memory and was comparing
      return s1;
}


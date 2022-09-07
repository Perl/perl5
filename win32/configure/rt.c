
/* This file determines the mingw-w64 mingw-runtime   *
 * version string - which is defined on both 32-bit   *
 * and 64-bit mingw-w64 compilers.                    *
 * This value is written to $Config{mingwrt_version}. */

#include <stdio.h>
#include <windows.h>

int main(void) {
#if defined(__MINGW64_VERSION_STR)
  printf("%s", __MINGW64_VERSION_STR);
#else
  printf(""); 
#endif

return 0;
}


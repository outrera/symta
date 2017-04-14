#ifndef SYMTA_COMPAT_H_
#define SYMTA_COMPAT_H_

char *realpath(const char *path, char *resolved_path);

//check for mingw w64, which has different library from usual mingw
int compat_clock_gettime(int X, struct timespec *ts);

#ifdef my_clock_gettime
#undef my_clock_gettime
#endif
#define my_clock_gettime(x,ts) compat_clock_gettime(x,ts)

#endif

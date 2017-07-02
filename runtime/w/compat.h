#ifndef SYMTA_COMPAT_H_
#define SYMTA_COMPAT_H_

char *realpath(const char *path, char *resolved_path);

//check for mingw w64, which has different library from usual mingw
int cmt_clock_gettime(int X, struct timespec *ts);
int cmt_mkdir(const char *path, int mode);

#endif

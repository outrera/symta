#ifndef SYMTA_COMPAT_H_
#define SYMTA_COMPAT_H_

#define CLOCK_REALTIME 0
int cmt_clock_gettime(int clk_id, struct timespec *ts);

#endif

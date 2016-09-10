#ifndef _SIGACTION_H_
#define _SIGACTION_H_

#include <stdint.h>
#include <signal.h>
#include <sys/types.h>

#define SA_NOCLDSTOP 0x1   /* Do not generate SIGCHLD when children stop */
#define SA_SIGINFO   0x2   /* Invoke the signal catching function with */
#define SA_ONSTACK   0x4   /* Signal delivery will be on a separate stack. */
#define SA_RESTART   0x8   /* If the flag is not set, interruptible functions
                              interrupted by this signal shall fail with errno
                              set to [EINTR]. [Option End] */

typedef int uid_t;
typedef uint32_t sigset_t;

typedef union sigval_t {
  int sival_int;
  void *sival_ptr;
} sigval_t;

struct siginfo_t {
  int      si_signo;     /* Signal number */
  int      si_code;      /* Signal code */
  int      si_errno;     /* An errno value */
  pid_t    si_pid;       /* Sending process ID */
  uid_t    si_uid;       /* Real user ID of sending process */
  void    *si_addr;      /* Memory location which caused fault */
  int      si_status;    /* Exit value or signal */
  long     si_band;      /* Band event */
  sigval_t si_value;     /* Signal value */
};

typedef struct siginfo_t siginfo_t;

struct sigaction {
  /* Pointer to a signal-catching function or one of
     the macros SIG_IGN or SIG_DFL. */
  void     (*sa_handler)(int);
  /* Set of signals to be blocked during execution of 
     the signal handling function. */
  sigset_t   sa_mask;
  /* Special flags to affect behavior of signal. */
  int        sa_flags;
  /* Pointer to a signal-catching function. */
  void     (*sa_sigaction)(int, siginfo_t *, void *);
};

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);

#endif /*  _SYS_MMAN_H_ */

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

typedef struct stack_t stack_t;

struct stack_t {
  void *ss_sp;     /* This points to the base of the signal stack.  */
  size_t ss_size;  /* This is the size (in bytes) of the signal stack which ‘ss_sp’ points to. */
  int ss_flags;
};


/*
enum {
  REG_GS = 0,
  REG_FS,
  REG_ES,
  REG_DS,
  REG_EDI,
  REG_ESI,
  REG_EBP,
  REG_ESP,
  REG_EBX,
  REG_EDX,
  REG_ECX,
  REG_EAX,
  REG_TRAPNO,
  REG_ERR,
  REG_EIP,
  REG_CS,
  REG_EFL,
  REG_UESP,
  REG_SS
};*/

enum {
  REG_R8 = 0,
  REG_R9,
  REG_R10,
  REG_R11,
  REG_R12,
  REG_R13,
  REG_R14,
  REG_R15,
  REG_RDI,
  REG_RSI,
  REG_RBP,
  REG_RBX,
  REG_RDX,
  REG_RAX,
  REG_RCX,
  REG_RSP,
  REG_RIP,
  REG_EFL,
  REG_CSGSFS,
  REG_ERR,
  REG_TRAPNO,
  REG_OLDMASK,
  REG_CR2
};

typedef struct mcontext_t {
  intptr_t gregs[19];
  void *fpregs;
} mcontext_t;

typedef struct ucontext_t ucontext_t;

struct ucontext_t {
  ucontext_t *uc_link;     /* pointer to the context that will be resumed
                             when this context returns*/
  sigset_t    uc_sigmask;  /* the set of signals that are blocked when this
                              context is active */
  stack_t     uc_stack;    /* the stack used by this context */
  mcontext_t  uc_mcontext; /* a machine-specific representation of the saved
                              context */
};
                        
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
  void     (*sa_sigaction)(int signum, siginfo_t *siginfo, void *context);
};

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);

#endif /*  _SIGACTION_H_ */

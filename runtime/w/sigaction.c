/* Basic sigaction() api for Windows
 * Author: Nikita Sadkov
 * License: Public Domain (only sigaction files, other files have their own license)
 * For now it handles just SIGSEGV with address.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#include "sigaction.h"

#ifndef NSIG
#define NSIG 128
#endif 

static struct sigaction sigacts[NSIG];
static siginfo_t siginfo;

static void (*p_sigsegv_handler)(void *);
static int sa_ready;

static void do_sig(int sig, void *addr) {
  struct sigaction *sa = sigacts+sig;
  if (!sa->sa_sigaction) {
    sa->sa_handler(sig);
    return;
  }
  siginfo.si_signo = sig;
  siginfo.si_addr = addr;
  sa->sa_sigaction(sig, &siginfo, 0);
}

static LONG WINAPI windows_exception_handler(EXCEPTION_POINTERS * ExceptionInfo) {
  void *segfault_place;
  LONG r = EXCEPTION_EXECUTE_HANDLER; //by default abort execution
  switch(ExceptionInfo->ExceptionRecord->ExceptionCode)
  {
  case EXCEPTION_ACCESS_VIOLATION:
      segfault_place = (void*)ExceptionInfo->ExceptionRecord->ExceptionInformation[1];
      do_sig(SIGSEGV, segfault_place);
      r = EXCEPTION_CONTINUE_EXECUTION; //hope user has fixed it
      break;
  case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
      fputs("Error: EXCEPTION_ARRAY_BOUNDS_EXCEEDED\n", stderr);
      break;
  case EXCEPTION_BREAKPOINT:
      fputs("Error: EXCEPTION_BREAKPOINT\n", stderr);
      break;
  }
  return r;
}

static void default_handler(int sig) {
  fprintf(stderr, "Error: unhandled signal %d\n", sig);
  abort();
}

static void init_sigaction() {
  int i;
  sa_ready = 1;
  for (i = 0; i < NSIG; i++) {
    sigacts[i].sa_handler = default_handler;
    sigacts[i].sa_sigaction = 0;
    sigacts[i].sa_mask = 0;
    sigacts[i].sa_flags = 0;
  }
  SetUnhandledExceptionFilter(windows_exception_handler);
}

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) {
  if (!sa_ready) init_sigaction();
  if (oldact) memcpy(oldact, sigacts+signum, sizeof(*act));
  memcpy(sigacts+signum, act, sizeof(*act));
  return 0;
}

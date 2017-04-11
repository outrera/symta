#ifndef RUNTIME_INTERNAL_H
#define RUNTIME_INTERNAL_H

#include "symta.h"

#define MAX_METHODS (4*1024)
#define MAX_LIBS 1024

// predefine method slots
#define M_SIZE 0
#define M_NAME 1
#define M_SINK 2

#define LIST_SIZE(o) ((uintptr_t)O_CODE(o))

#define IS_FIXTEXT(o) (O_TAGL(o) == T_FIXTEXT)
#define IS_BIGTEXT(o) (O_TAG(o) == TAG(T_TEXT))
#define IS_TEXT(o) (IS_FIXTEXT(o) || IS_BIGTEXT(o))

#define BIGTEXT_SIZE(o) REF4(o,0)
#define BIGTEXT_DATA(o) ((char*)&REF1(o,4))

#define C_ANY(o,arg_index,meta)

#define C_FN(o,arg_index,meta) \
  if (O_TAG(o) != TAG(T_CLOSURE)) \
    api->bad_type(api, "fn", arg_index, meta)

#define C_INT(o,arg_index,meta) \
  if (O_TAGL(o) != T_INT) \
    api->bad_type(api, "int", arg_index, meta)

#define C_FLOAT(o,arg_index,meta) \
  if (O_TAGL(o) != T_FLOAT) \
    api->bad_type(api, "float", arg_index, meta)

#define C_TEXT(o,arg_index,meta) \
  if (!IS_TEXT(o)) \
    api->bad_type(api, "text", arg_index, meta)

#define C_BYTES(o,arg_index,meta) \
  if (O_TAG(o) != TAG(T_BYTES)) \
    api->bad_type(api, "bytes", arg_index, meta)

#define BUILTIN_CLOSURE(dst,code) { CLOSURE(dst, code, 0); }


#define BUILTIN_CHECK_VARARGS(expected) \
  if (NARGS(E) < FIXNUM(expected)) { \
    return api->bad_argnum(api, E, -FIXNUM(expected)); \
  }

#define BUILTIN_SETUP(sname,name,nargs) \
  static void *b_##name(api_t *api); \
  static fn_meta_t meta_b_##name[1] = \
    {{0,(void*)FIXNUM(nargs),sname,b_##name,0,0,"builtin"}}; \
  static void setup_b_##name(api_t *api) { \
    set_meta(meta_b_##name[0].fn, meta_b_##name); \
  }

#define getArg(i) (*((void**)E+(i)))

#define BUILTIN0(sname, name) \
  BUILTIN_SETUP(sname,name,0) \
  static void *b_##name(api_t *api) { \
  PROLOGUE; \
  void *A, *R; \
  CHECK_NARGS(0);
#define BUILTIN1(sname,name,a_check,a) \
  BUILTIN_SETUP(sname,name,1) \
  static void *b_##name(api_t *api) { \
  PROLOGUE; \
  void *A, *R, *a; \
  CHECK_NARGS(1); \
  a = getArg(0); \
  a_check(a, 0, sname);
#define BUILTIN2(sname,name,a_check,a,b_check,b) \
  BUILTIN_SETUP(sname,name,2) \
  static void *b_##name(api_t *api) { \
  PROLOGUE; \
  void *A, *R, *a, *b; \
  CHECK_NARGS(2); \
  a = getArg(0); \
  a_check(a, 0, sname); \
  b = getArg(1); \
  b_check(b, 1, sname);
#define BUILTIN3(sname,name,a_check,a,b_check,b,c_check,c) \
  BUILTIN_SETUP(sname,name,3) \
  static void *b_##name(api_t *api) { \
  PROLOGUE; \
  void *A, *R, *a, *b,*c; \
  CHECK_NARGS(3); \
  a = getArg(0); \
  a_check(a, 0, sname); \
  b = getArg(1); \
  b_check(b, 1, sname); \
  c = getArg(2); \
  c_check(c, 2, sname);
#define BUILTIN_VARARGS(sname,name) \
  BUILTIN_SETUP(sname,name,-1) \
  static void *b_##name(api_t *api) { \
  PROLOGUE; \
  void *A, *R; \
  BUILTIN_CHECK_VARARGS(0);
#define RETURNS(r) R = (void*)(r); RETURN(R); }
#define RETURNS_NO_GC(r) RETURN_NO_GC(r); }


#endif //SYMTA_H

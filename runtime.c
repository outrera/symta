#include <dlfcn.h>

#include "runtime.h"

#define getArg(i) ((void**)(E))[i]
#define getVal(x) ((uintptr_t)(x)&~TAG_MASK)


#define HEAP_SIZE (1024*1024*32)
#define MAX_ARRAY_SIZE (HEAP_SIZE/2)

static void *heap_base[HEAP_SIZE+POOL_SIZE];
static void *heap_tags[HEAP_SIZE/4];
static void **heap_ptr;
static void **heap_end;
static int pools_count = 0;

#define ARRAY_POOL  (POOL_SIZE+0)
#define META_POOL   (POOL_SIZE+1)
#define LIST_POOL   (POOL_SIZE+2)
#define SYMBOL_POOL (POOL_SIZE+3)

static void **alloc(int count) {
  void **r = heap_ptr;
  heap_ptr += (count+POOL_SIZE-1)/POOL_SIZE;
  if ((void**)heap_ptr > heap_end) {
    printf("FIXME: can't alloc %d cells, implement GC\n", count);
    abort();
  }
  return r;
}

static int new_pool(regs_t *regs) {
  return pools_count++;
}

static int is_unicode(char *s) {
  return 0;
}

static void bad_type(regs_t *regs, char *expected, int arg_index, char *name) {
  int i, nargs = (int)NARGS;
  printf("arg %d isnt %s, during call to:\n", arg_index, expected);
  printf("  %s", name);
  for (i = 1; i < nargs; i++) printf(" %s", print_object(getArg(i)));
  printf("\n", name);
  abort();
}

#define C_ANY(o,arg_index,meta)

#define C_FIXNUM(o,arg_index,meta) \
  if (GET_TAG(o) != T_FIXNUM) \
    bad_type(regs, "fixnum", arg_index, meta)

#define C_SYMBOL(o,arg_index,meta) \
  if (GET_TAG(o) != T_CLOSURE || POOL_HANDLER(o) != b_symbol) \
    bad_type(regs, "symbol", arg_index, meta)

#define C_LIST(o,arg_index,meta) \
  if (GET_TAG(o) != T_CLOSURE || POOL_HANDLER(o) != b_list) \
    bad_type(regs, "list", arg_index, meta)

#define BUILTIN_CHECK_NARGS(expected,tag) \
  if (NARGS != expected) { \
    static void *stag = 0; \
    if (!stag) SYMBOL(stag, tag); \
    regs->handle_args(regs, (intptr_t)expected, stag, v_empty); \
    return; \
  }
#define BUILTIN_CHECK_NARGS_ABOVE(tag) \
  if (NARGS < 1) { \
    static void *stag = 0; \
    if (!stag) SYMBOL(stag, tag); \
    regs->handle_args(regs, -1, stag, v_empty); \
    return; \
  }


#define CALL0(f,k) \
  ALLOC(E, 1, 1, 1); \
  STORE(E, 0, k); \
  CALL(f);

#define CALL1(f,k,a) \
  ALLOC(E, 2, 2, 2); \
  STORE(E, 0, k); \
  STORE(E, 1, a); \
  CALL(f);

#define CALL2(f,k,a,b) \
  ALLOC(E, 3, 3, 3); \
  STORE(E, 0, k); \
  STORE(E, 1, a); \
  STORE(E, 2, b); \
  CALL(f);

#define BUILTIN0(name) \
  static void b_##name(regs_t *regs) { \
  void *k; \
  BUILTIN_CHECK_NARGS(1,#name); \
  k = getArg(0);
#define BUILTIN1(name,a_check, a) \
  static void b_##name(regs_t *regs) { \
  void *k, *a; \
  BUILTIN_CHECK_NARGS(2,#name); \
  k = getArg(0); \
  a = getArg(1); \
  a_check(a, 0, #name);
#define BUILTIN2(name,a_check,a,b_check,b) \
  static void b_##name(regs_t *regs) { \
  void *k, *a, *b; \
  BUILTIN_CHECK_NARGS(3,#name); \
  k = getArg(0); \
  a = getArg(1); \
  a_check(a, 0, #name); \
  b = getArg(2); \
  b_check(a, 1, #name);
#define BUILTIN_VARARGS(name) \
  static void b_##name(regs_t *regs) { \
  void *k; \
  BUILTIN_CHECK_NARGS_ABOVE(#name); \
  k = getArg(0);

#define RETURNS(r) CALL0(k,(r)); }
#define RETURNS_VOID }

// E[0] = environment, E[1] = continuation, E[2] = function_name
// run continuation recieves entry point into user specified program
// which it runs with supplied host resolver, which resolves all builtin symbols
BUILTIN0(run) CALL1(k,fin,host); RETURNS_VOID

BUILTIN0(fin) T = k; RETURNS_VOID

BUILTIN_VARARGS(void)
  printf("FIXME: implement `void`\n");
  abort();
RETURNS(0)

BUILTIN_VARARGS(empty)
  printf("FIXME: implement `empty`\n");
  abort();
RETURNS(0)

BUILTIN2(add,C_FIXNUM,a,C_FIXNUM,b)
RETURNS((intptr_t)a + (intptr_t)b - 1)

BUILTIN2(sub,C_FIXNUM,a,C_FIXNUM,b)
RETURNS((intptr_t)a - (intptr_t)b + 1)

BUILTIN2(mul,C_FIXNUM,a,C_FIXNUM,b)
RETURNS(((intptr_t)a/(1<<TAG_BITS)) * ((intptr_t)b-1) + 1)

BUILTIN2(div,C_FIXNUM,a,C_FIXNUM,b)
RETURNS((intptr_t)a / (intptr_t)b * (1<<TAG_BITS) + 1)

// FIXME: we can re-use single META_POOL, changing only `k`
BUILTIN1(tag_of,C_ANY,a)
  ALLOC(E, 0, META_POOL, 1); // signal that we want meta-info
  STORE(E, 0, k);
  CALL_TAGGED(a);
RETURNS_VOID

BUILTIN_VARARGS(fixnum)
  printf("FIXME: implement fixnum handler");
  abort();
RETURNS(0)

BUILTIN_VARARGS(list)
  printf("FIXME: implement list-handler\n");
  abort();
RETURNS(0)

BUILTIN_VARARGS(symbol)
  printf("FIXME: implement symbol-handler\n");
  abort();
RETURNS(0)

// FIXME1: use different pool-descriptors to encode length
// FIXME2: immediate encoding for symbols:
//         one 7-bit char, then nine 6-bit chars (61 bit in total)
//         7-bit char includes complete ASCII
//         6-bit char includes all letters, all digits `_` and 0 (to indicate EOF)
static void *alloc_symbol(regs_t *regs, char *s) {
  int l, a;
  void *p;

  if (is_unicode(s)) {
    printf("FIXME: implement unicode symbols\n");
    abort();
  }

  l = strlen(s);
  a = ((l+4)+TAG_MASK)>>TAG_BITS;
  ALLOC(p,b_symbol,SYMBOL_POOL,a);
  *(uint32_t*)p = l;
  memcpy(((uint32_t*)p+1), s, l);
  return p;
}

#define CONS(dst,a,b) \
  ALLOC(T, b_list, LIST_POOL, 2); \
  STORE(T, 0, a); \
  STORE(T, 1, b); \
  MOVE(dst, T);

BUILTIN_VARARGS(make_list)
  void *xs = v_empty;
  int i = (int)NARGS;
  while (i-- > 1) {
    CONS(xs, getArg(i), xs);
  }
RETURNS(xs)

static struct {
  char *name;
  void *fun;
} builtins[] = {
  {"+", b_add},
  {"-", b_sub},
  {"*", b_mul},
  {"/", b_div},
  {"tag_of", b_tag_of},
  {"list", b_make_list},
  {0, 0}
};

BUILTIN1(host,C_SYMBOL,t_name)
  int i;
  char *name = (char*)getVal(t_name);
  for (i = 0; ; i++) {
    if (!builtins[i].name) {
      printf("host doesn't provide `%s`\n", name);
      abort();
    }
    if (!strcmp(builtins[i].name, name)) {
      break;
    }
  }
RETURNS(builtins[i].fun)


#define CAR(x) ((void**)getVal(x))[0]
#define CDR(x) ((void**)getVal(x))[1]
static char *print_object_r(regs_t *regs, char *out, void *o) {
  int tag = GET_TAG(o);

  if (tag == T_CLOSURE) {
    pfun handler = POOL_HANDLER(o);
    if ((uintptr_t)handler < MAX_ARRAY_SIZE) {
      out += sprintf(out, "$(array %d %p)", (int)(uintptr_t)handler, o);
    } else if (handler == b_symbol) {
      int i;
      int l = *(uint32_t*)o;
      char *p = (char*)o + 4;
      for (i = 0; i < l; i++) *out++ = *p++;
    } else if (handler == b_list) {
      out += sprintf(out, "(");
      for (;;) {
        out = print_object_r(regs, out, CAR(o));
        o = CDR(o);
        if (o == v_empty) break;
        out += sprintf(out, " ");
      }
      out += sprintf(out, ")");
    } else if (handler == b_empty) {
      out += sprintf(out, "()");
    } else if (handler == b_void) {
      out += sprintf(out, "Void");
    } else {
      //FIXME: check metainfo to see if this object has associated print routine
      out += sprintf(out, "#(closure %p %p)", handler, o);
    }
  } else if (tag == T_FIXNUM) {
    out += sprintf(out, "%ld", (intptr_t)o/(1<<TAG_BITS));
  } else {
    out += sprintf(out, "#(ufo %d %p)", tag, o);
  }
  return out;
}

// FIXME: use heap instead
static char print_buffer[1024*16];
char* print_object_f(regs_t *regs, void *object) {
  print_object_r(regs, print_buffer, object);
  return print_buffer;
}



static void handle_args(regs_t *regs, intptr_t expected, void *tag, void *meta) {
  intptr_t got = NARGS;
  void *k = getArg(0);
  if (got == 0) { //request for tag
    CALL0(k, tag);
    return;
  } else if (got == -1) {
    CALL0(k, meta);
    return;
  }
  printf("bad number of arguments: got=`%ld`, expected=`%ld`\n", got-1, expected-1);
  if (meta != v_void) {
  }
  abort();
}

static regs_t *new_regs() {
  regs_t *regs = (regs_t*)malloc(sizeof(regs_t));
  memset(regs, 0, sizeof(regs_t));

  regs->handle_args = handle_args;
  regs->print_object_f = print_object_f;
  regs->new_pool = new_pool;
  regs->alloc = alloc;
  regs->alloc_symbol = alloc_symbol;

  return regs;
}

#define CLOSURE(dst,code) \
  { \
    int builtin_pool = regs->new_pool(); \
    ALLOC(dst, code, builtin_pool, 0); \
  }

int main(int argc, char **argv) {
  int i;
  char *module;
  void *lib;
  pfun entry;
  regs_t *regs;

  if (argc != 2) {
    printf("usage: %s <start_module>\n", argv[0]);
    abort();
  }

  module = argv[1];

  heap_ptr = (void**)(((uintptr_t)heap_base + POOL_SIZE) & POOL_BASE);
  regs = new_regs();

  // multi-array pools
  for (i = 0; i < POOL_SIZE; i++) regs->new_pool();

  regs->new_pool(); // array pool
  regs->new_pool(); // meta pool
  regs->new_pool(); // list pool
  regs->new_pool(); // string pool

  CLOSURE(v_void, b_void);
  CLOSURE(v_empty, b_empty);

  CLOSURE(run, b_run);
  CLOSURE(fin, b_fin);
  CLOSURE(host, b_host);

  for (i = 0; ; i++) {
    if (!builtins[i].name) break;
    CLOSURE(builtins[i].fun, builtins[i].fun);
  }

  lib = dlopen(module, RTLD_LAZY);
  if (!lib) {
    printf("cant load %s\n", module);
    abort();
  }

  entry = (pfun)dlsym(lib, "entry");
  if (!entry) {
    printf("cant find symbol `entry` in %s\n", module);
    abort();
  }

  entry(regs);

  printf("%s\n", print_object(T));
  //printf("main() says goodbay\n");
}

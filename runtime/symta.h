#ifndef SYMTA_H
#define SYMTA_H

#include <stdint.h>
#include <setjmp.h>

#define SYMTA_DEBUG 1

#define TAGL_BITS ((uintptr_t)2)
#define PTR_BITS ((uintptr_t)40)
#define TAGH_BITS ((uintptr_t)10)
#define ALIGN_BITS ((uintptr_t)3)

//#define MAX_TYPES (1<<TAGH_BITS)
#define MAX_TYPES 512

#define TAGH_SHIFT (64-TAGH_BITS)

#define TAGL_MASK (((uintptr_t)1<<TAGL_BITS)-1)
#define PTR_MASK ((((uintptr_t)1<<PTR_BITS)-1)<<ALIGN_BITS)
#define TAGH_MASK ((((uintptr_t)1<<TAGH_BITS)-1)<<TAGH_SHIFT)
#define ALIGN_MASK (((uintptr_t)1<<ALIGN_BITS)-1)

//all liftable objects are 8-byte aligned
//so we use 4th bit of their address for flag
#define LIFT_FLAG ((uintptr_t)4)

#define O_TAGL(o) ((uintptr_t)(o)&TAGL_MASK)
#define O_TAGH(o) ((uintptr_t)(o)>>TAGH_SHIFT)
#define O_TAG(o) ((uintptr_t)(o)&(TAGH_MASK|TAGL_MASK))
#define O_TYPE(o) (O_TAGL(o) == T_DATA ? O_TAGH(o) : O_TAGL(o))
#define O_PTR(o) ((uintptr_t)(o)&PTR_MASK)
#define REF1(base,off) (*(uint8_t*)(O_PTR(base)+(off)))
#define REF4(base,off) (*(uint32_t*)(O_PTR(base)+(off)*4))
#define REF(base,off) (*(void**)(O_PTR(base)+(off)*sizeof(void*)))
#define O_FRAME(x) ((frame_t*)REF(x,-1))
#define O_LEVEL(x) (O_FRAME(x)-api->frames)
#define O_CODE(x) REF(x,-2)
#define O_FN(x) ((pfun)O_CODE(x))

#define NARGS(x) ((intptr_t)O_CODE(x))

#define TAG(tag) (((uintptr_t)(tag)<<TAGH_SHIFT) | T_DATA)

#define ADD_TAGL(src,tag) ((void*)((uintptr_t)(src) | tag))
#define ADD_TAG(src,tag) ((void*)((uintptr_t)(src) | TAG(tag)))

#define IMMEDIATE(x) (O_TAGL(x) != T_DATA)


#define T_INT     0
#define T_FLOAT   1
#define T_FIXTEXT 2
#define T_DATA    3
#define T_CLOSURE 4
#define T_LIST    5
#define T_VIEW    6
#define T_CONS    7
#define T_OBJECT  8
#define T_TEXT    9
#define T_VOID    10
#define T_GENERIC_LIST 11
#define T_GENERIC_TEXT 12
#define T_HARD_LIST    13
#define T_BYTES        14

// sign preserving shifts
#define ASHL(x,count) ((x)*(1<<(count)))
#define ASHR(x,count) ((x)/(1<<(count)))
#define FIXNUM(x) ASHL((intptr_t)(x),ALIGN_BITS)
#define UNFIXNUM(x) ASHR((intptr_t)(x),ALIGN_BITS)

#define FIXTEXT(x) (void*)(((uint64_t)(x)<<3) | T_FIXTEXT)

#define LIST_SIZE(o) ((uintptr_t)O_CODE(o))

#define FXNNEG(dst,o) dst = (void*)(-(intptr_t)(o))
#define FXNADD(dst,a,b) dst = (void*)((intptr_t)(a) + (intptr_t)(b))
#define FXNSUB(dst,a,b) dst = (void*)((intptr_t)(a) - (intptr_t)(b))
#define FXNMUL(dst,a,b) dst = (void*)(UNFIXNUM(a) * (intptr_t)(b))
#define FXNDIV(dst,a,b) dst = (void*)(FIXNUM((intptr_t)(a) / (intptr_t)(b)))
#define FXNREM(dst,a,b) dst = (void*)((intptr_t)(a) % (intptr_t)(b))
#define FXNEQ(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) == (intptr_t)(b))
#define FXNNE(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) != (intptr_t)(b))
#define FXNLT(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) < (intptr_t)(b))
#define FXNGT(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) > (intptr_t)(b))
#define FXNLTE(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) <= (intptr_t)(b))
#define FXNGTE(dst,a,b) dst = (void*)FIXNUM((intptr_t)(a) >= (intptr_t)(b))
#define FXNAND(dst,a,b) dst = (void*)((uintptr_t)(a) & (uintptr_t)(b))
#define FXNIOR(dst,a,b) dst = (void*)((uintptr_t)(a) | (uintptr_t)(b))
#define FXNXOR(dst,a,b) dst = (void*)((uintptr_t)(a) ^ (uintptr_t)(b))
#define FXNSHL(dst,a,b) dst = (void*)((intptr_t)(a)<<UNFIXNUM(b))
#define FXNSHR(dst,a,b) dst = (void*)(((intptr_t)(a)>>UNFIXNUM(b))&~TAGL_MASK)
#define FXNTAG(dst,x) dst = (void*)FIXNUM(O_TAGL(x))
#define FXNREF(dst,x,i) dst = (void*)REF((x),UNFIXNUM(i))
#define FXNREFS(dst,x,i,v) dst = 0; LIFT((void*)O_PTR(x),UNFIXNUM(i),(v))
#define FXNSIZE(dst,x) dst = (void*)LIST_SIZE(x)
#define FXNCANGET(dst,x,i) dst = (void*)FIXNUM(!O_TAGL(i) && O_TAGL(x)==T_LIST \
                                             && (uintptr_t)(i) < (uintptr_t)LIST_SIZE(x))
#define UNFXN(dst,x) dst = (void*)UNFIXNUM(x)

#define LOAD_FLOAT(dst,x) { \
    double d_ = (double)(x); \
    uint64_t t_ = (*(uint64_t*)&d_); \
    dst = (void*)((t_&~TAGL_MASK) | T_FLOAT); \
  }

#define UNFLOAT(dst,x) { \
    uint64_t t_ = (uint64_t)(x)&~TAGL_MASK; \
    dst = *(double*)&t_; \
  }

#define HEAP_SIZE (32*1024*1024)
#define OBJ_HEAD_SIZE 2

// should be less than C's stack, which is 1024*1024 bytes
#define MAX_LEVEL (1024*1024/9)

typedef struct fn_meta_t { //function metadata
  intptr_t size;    // closure size - the size of environment,
                    // this function closes over.
  void *nargs; // number of arguments
  void *name;  // function name text (anonymous, when name is 0)
  void *fn;
  int32_t row;
  int32_t col;
  void *origin;  // user-provided metadata
}  __attribute__((packed)) fn_meta_t;


typedef struct frame_t {
  void **top;  //this frame's heap top
  void *base;  //pointer to current frame's heap base, used by GC
  void *clsr;  //closure
  void *lifts; //what should be lifted to parent frame
  void *onexit; //called on exit
} frame_t;

typedef struct api_t api_t;
struct api_t {
  frame_t *frame; // current frame

  uintptr_t method; // current method, we execute

  void *jmp_return;

  // constants
  void *void_;
  void *empty_;
  uintptr_t m_ampersand;
  uintptr_t m_underscore;

  // runtime's C API
  void (*bad_type)(api_t *api, char *expected, int arg_index, char *name);
  void* (*bad_argnum)(api_t *api, void *E, intptr_t expected);
  void (*tables_init)(api_t *api, void *tables);
  char* (*print_object_f)(api_t *api, void *object);
  void (*gc_lifts)();
  void *(*alloc_text)(char *s);
  void (*fatal)(api_t *api, void *msg);
  void (*add_subtype)(api_t *api, intptr_t super, intptr_t sub);
  void (*set_type_size_and_name)(api_t *api, intptr_t tag, intptr_t size, void *name);
  void (*add_method)(api_t *api, intptr_t method_id, intptr_t type_id, void *handler);
  void *(*get_method)(uintptr_t tag);
  void *(*get_method_name)(uintptr_t method_id);
  char *(*text_chars)(api_t *api, void *text);

  void *collectors[MAX_TYPES]; //garbage collectors for each type
  void *top[2]; // heap top
  frame_t frames[MAX_LEVEL]; // stack frames should come directly before the heap
  void *heap[2][HEAP_SIZE];
};

typedef void *(*pfun)(api_t *api);

#define No api->void_
#define Empty api->empty_
#define Frame api->frame
#define Lifts Frame->lifts
#define Top (*Frame->top)
#define Base Frame->base
#define Level (api->frame-api->frames)


//HEAP_GUARD could probable be useful, when allocating large
// memory size, that could otherwise jump over guard page
#define HEAP_GUARD()

#define ALLOC_BASIC(dst,code,count) \
  { \
    void** t_; \
    HEAP_GUARD(); \
    dst = (void**)Top - (uintptr_t)(count); \
    Top = t_ = (void**)dst - OBJ_HEAD_SIZE; \
    *t_ = (void*)(code); \
    *(t_+1) = Frame; \
  }

#define ALLOC_DATA(dst,tag,count) \
  { \
    void** t_; \
    HEAP_GUARD(); \
    dst = (void**)Top - (uintptr_t)(count); \
    Top = t_ = (void**)dst - 1; \
    *t_ = Frame;\
    dst = ADD_TAG(dst,tag); \
  }

#define CLOSURE(dst,code,count) \
  ALLOC_BASIC(dst,code,count); \
  dst = ADD_TAG(dst, T_CLOSURE);

//local closure
#define LOSURE(name,size) void *name[size];

//ARgList
#define ARL(dst,size) ALLOC_BASIC(dst,FIXNUM(size),size)

#define LIST_ALLOC(dst,size) \
  ARL(dst,size); \
  dst = ADD_TAG(dst, T_LIST);

typedef struct tot_entry_t { //table of tables entry
  intptr_t size;
  void *table;
}  __attribute__((packed)) tot_entry_t;
#define TABLES_INIT(tables) api->tables_init(api,tables);

#define SET_TYPE_PARAMS(tag,size,name) \
  api->set_type_size_and_name(api,(intptr_t)(tag),size,name);
#define DMET(method,type,handler) api->add_method(api,(intptr_t)type,(intptr_t)method,handler);
#define SUBTYPE(super,sub) api->add_subtype(api,(intptr_t)(super),(intptr_t)(sub));

#define IS_LIST(o) (O_TAG(o) == TAG(T_LIST))

#define print_object(object) api->print_object_f(api, object)
#define MIN(a,b) ((a) < (b) ? (a) : (b))

#define LOCAL(name) name:;
#define BRANCH(cnd,name) if (cnd) goto name;
#define ZBRANCH(cnd,name) if (!(cnd)) goto name;
#define JMP(name) goto name;
#ifdef WINDOWS
#define BEGIN_CODE \
  int __stdcall DllMainCRTStartup(void *a, uint32_t  b, void *c) { return 1; } \
  static void __dummy___ () {
#else
#define BEGIN_CODE static void __dummy___ () {
#endif
#define END_CODE }
#define LDFXN(dst,x) dst = (void*)FIXNUM(x)
#define TEXT(dst,x) dst = api->alloc_text((char*)(x))
#define THIS_METHOD(dst) dst = (void*)api->method;
#define METHOD_NAME(dst,method) dst = api->get_method_name((uintptr_t)method);
#define TYPE_ID(dst,o) dst = (void*)FIXNUM(O_TYPE(o));
// P holds points to closure of current function
// E holds pointer to arglist of current function
#define PROLOGUE void *P = Frame->clsr; \
                 void *E = (void**)Top+OBJ_HEAD_SIZE;
#define ENTRY(name) } void *name(api_t *api) {PROLOGUE; void *dummy;
#define DECL_LABEL(name) static void *name(api_t *api);
#define LABEL(name) } static void *name(api_t *api) {PROLOGUE; void *dummy;
#define VAR(name) void *name;

//opens new frame before allocating arguments for a call
#define BPUSH() \
  ++Frame; \
  /*fprintf(stderr, "Entering %ld\n", Level);*/ \
  Base = Top;
#define BPOP() \
  /*fprintf(stderr, "Leaving %ld\n", Level);*/ \
  Top = Base; \
  --Frame;
#define CALL(k,f) Frame->clsr = f; k = O_FN(f)(api);

#define MCALL(k,o,m) \
  api->method = (uintptr_t)m; \
  {\
    static uintptr_t cached_tag = 0xFFFFFF; \
    static void *cached_method; \
    uintptr_t tag = O_TAG(o); \
    if (cached_tag != tag) { \
      cached_tag = tag; \
      cached_method = api->get_method(tag); \
    } \
    CALL(k,cached_method); \
  }

#define CALL_TAGGED(k,o) \
  { \
    if (O_TAG(o) == TAG(T_CLOSURE)) { \
      CALL(k,o); \
    } else { \
      void *as = ADD_TAG((void**)Top+OBJ_HEAD_SIZE, T_LIST); \
      void *e; \
      ARL(e,2); \
      STARG(e,0,o); \
      STARG(e,1,as); \
      MCALL(k,o,api->m_ampersand); \
    } \
  }

//#define GCDEBUG fprintf(stderr, "GC %p:%p -> %p\n", Top, Base, api->top[(Level-1)&1]);
typedef void *(*collector_t)( void *o);
#define GC_LIFTS() if (Lifts) api->gc_lifts();
#define RETURN(o) \
  if (!IMMEDIATE(o) && O_FRAME(o) == Frame) { \
    o = ((collector_t)api->collectors[O_TAGH(o)])(o); \
  } \
  if (Lifts) api->gc_lifts();\
  BPOP(); \
  return (void*)(o);
#define RETURN_NO_GC(value) return (void*)(value);
#define LIFTS_CONS(dst,head,tail) \
  { \
   void** t_ = (void**)Top-2;\
   Top=t_; \
   *t_ = (head); \
   *(t_+1) = (tail); \
   dst = t_; \
  }
#define LIFTS_HEAD(xs) (*((void**)(xs)))
#define LIFTS_TAIL(xs) (*((void**)(xs)+1))
#define LIFT(base,pos,value) \
  { \
    void **p_ = (void**)(base)+(pos); \
    if (IMMEDIATE(value)) { \
      *p_ = (value); \
    } else if (O_FRAME(value) <= O_FRAME(base)) { \
      *p_ = (void*)((uintptr_t)(value) & ~LIFT_FLAG); \
    } else { \
      *p_ = (void*)((uintptr_t)(value) | LIFT_FLAG); \
      LIFTS_CONS(Lifts, p_, Lifts); \
    } \
  }
#define LDARG(dst,src,src_off) dst = *((void**)(src)+(src_off))
#define STARG(dst,dst_off,src) *((void**)(dst)+(dst_off)) = (void*)(src)
#define LOAD(dst,src,src_off) dst = REF(src,src_off)
#define STOR(dst,dst_off,src) REF(dst,dst_off) = (void*)(src)
#define COPY(dst,dst_off,src,src_off) REF(dst,dst_off) = REF(src,src_off)
#define MOVE(dst,src) dst = (void*)(src)
#define TAGGED(dst,src,tag) dst = ADD_TAG(src,tag)
#define DGET(dst,src,off) dst = REF(src, off)
#define DSET(dst,off,src) LIFT(&REF(dst,0),off,src)
#define DINIT(dst,off,src) REF(dst, off) = src
//untagged store
#define UTSTOR(dst,off,src) *(void**)((uint8_t*)(dst)+(uint64_t)(off)) = src

#define FATAL(msg) api->fatal(api, msg);

#define SET_UNWIND_HANDLER(r,h) Frame->onexit = h;
#define REMOVE_UNWIND_HANDLER(r) Frame->onexit = 0;

typedef struct {
  jmp_buf anchor;
  frame_t *frame;
  api_t *api;
} jmp_state;

#define SETJMP(dst) { \
    jmp_state *js_; \
    ALLOC_BASIC(api->jmp_return, 0, ((sizeof(jmp_state)+ALIGN_MASK)>>ALIGN_BITS)); \
    js_ = (jmp_state*)api->jmp_return; \
    js_->frame = api->frame; \
    js_->api = api; \
    setjmp(js_->anchor); \
    api = js_->api; \
    dst = api->jmp_return; \
  }

#define LONGJMP(state,value) { \
    jmp_state *js_; \
    js_ = (jmp_state*)state; \
    while (js_->frame != api->frame) { \
      void *h_ = Frame->onexit; \
      Frame->onexit = 0; \
      if (O_TAG(h_) == TAG(T_CLOSURE)) { \
          void *k_; \
          BPUSH(); \
          ARL(E,0); \
          CALL(k_,h_) \
      } \
      GC(value); \
      BPOP(); \
    } \
    api->jmp_return = value; \
    longjmp(js_->anchor, 0); \
  }

#define CHECK_NARGS(expected) \
  if (NARGS(E) != FIXNUM(expected)) { \
    api->bad_argnum(api, E, FIXNUM(expected)); \
  }

// kludge for FFI identifiers
#define text_ char*
#define voidp_ void*
#define u4 uint32_t

#define FFI_VAR(type,name) type name;

#define FFI_TO_INT(dst,src) \
  if (O_TAGL(src) != T_INT) api->bad_type(api, "int", 0, 0); \
  dst = (int)UNFIXNUM(src);
#define FFI_FROM_INT(dst,src) dst = (void*)FIXNUM((intptr_t)src);

#define FFI_TO_U4(dst,src) \
  if (O_TAGL(src) != T_INT) \
    api->bad_type(api, "int", 0, 0); \
  dst = (uint32_t)UNFIXNUM(src);
#define FFI_FROM_U4(dst,src) dst = (void*)FIXNUM((intptr_t)src);

#define FFI_TO_DOUBLE(dst,src) UNFLOAT(dst,src);
#define FFI_FROM_DOUBLE(dst,src) LOAD_FLOAT(dst,src);

#define FFI_TO_FLOAT(dst,src) { \
    double _x; \
    UNFLOAT(_x,src); \
    _dst = (float)_x; \
  }
#define FFI_FROM_FLOAT(dst,src) LOAD_FLOAT(dst,(double)src);

#define FFI_TO_TEXT_(dst,src) dst = api->text_chars(api,src);
#define FFI_FROM_TEXT_(dst,src) dst = api->alloc_text(src);

#define FFI_TO_VOIDP_(dst,src) dst = (void*)(src);
#define FFI_FROM_VOIDP_(dst,src) dst = (void*)(src);

#define FFI_GET(dst,type,ptr,off) dst = (void*)FIXNUM(((type*)(ptr))[UNFIXNUM(off)]);
#define FFI_SET(type,ptr,off,val) ((type*)(ptr))[UNFIXNUM(off)] = (type)UNFIXNUM(val);

void *entry(api_t *api);
void *setup(api_t *api);

#endif //SYMTA_H

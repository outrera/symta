GCDEF(gc_closure) {
  int i, size;
  frame_t *frame;
  void *p, *q;
  void **pp, **oo;
  void *fixed_size, *dummy;
  api_t *api = &api_g;
  size = ((fn_meta_t*)get_meta(O_FN(o)))->size;
  GCPRE
  CLOSURE(p, O_CODE(o), size);
  MARK_MOVED(o,p);
  pp = (void**)&REF(p,0);
  oo = (void**)&REF(o,0);
  for (i = 0; i < size; i++) {
    q = oo[i];
    frame = O_FRAME(q);
    if (frame == GCFrame) {
      q = gc_arglist(q);
    } else {
      if (frame > (frame_t*)api->heap) {
        // already moved
        q = frame;
      }
    }
    pp[i] = q;
  }
  GCPOST
  return p;
}

GCDEF(gc_list) {
  int i, size;
  void *p;
  void **pp, **oo;
  api_t *api = &api_g;
  size = (int)UNFIXNUM(LIST_SIZE(o));
  GCPRE
  LIST_ALLOC(p, size);
  MARK_MOVED(o,p);
  pp = (void**)&REF(p,0);
  oo = (void**)&REF(o,0);
  for (i = 0; i < size; i++) {
    GC_REC(pp[i], oo[i]);
  }
  GCPOST
  return p;
}

GCDEF(gc_view) {
  void *p, *q;
  api_t *api = &api_g;
  uint32_t start = VIEW_START(o);
  uint32_t size = VIEW_SIZE(o);
  GCPRE
  VIEW(p, 0, start, size);
  MARK_MOVED(o,p);
  q = ADD_TAG(&VIEW_REF(o,0,0), T_LIST);
  GC_REC(q, q);
  O_CODE(p) = &REF(q, 0);
  GCPOST
  return p;
}

GCDEF(gc_cons) {
  void *p;
  api_t *api = &api_g;
  GCPRE
  CONS(p, 0, 0);
  MARK_MOVED(o,p);
  GC_REC(CAR(p), CAR(o))
  GC_REC(CDR(p), CDR(o))
  GCPOST
  return p;
}

GCDEF(gc_text) {
  void *p;
  api_t *api = &api_g;
  GCPRE
  p = alloc_bigtext(api, BIGTEXT_DATA(o), BIGTEXT_SIZE(o));
  MARK_MOVED(o,p);
  GCPOST
  return p;
}

GCDEF(gc_bytes) {
  void *p;
  api_t *api = &api_g;
  int size = (int)BYTES_SIZE(o);
  GCPRE
  p = alloc_bytes(api, size);
  memcpy(BYTES_DATA(p), BYTES_DATA(o), size);
  MARK_MOVED(o,p);
  GCPOST
  return p;
}

GCDEF(gc_data) {
  int i, size;
  void *p;
  void **pp, **oo;
  api_t *api = &api_g;
  uintptr_t tag = O_TAGH(o);
  size = types[tag].size;
  GCPRE
  ALLOC_DATA(p, tag, size);
  MARK_MOVED(o,p);
  pp = (void**)&REF(p,0);
  oo = (void**)&REF(o,0);
  for (i = 0; i < size; i++) {
    GC_REC(pp[i], oo[i]);
  }
  GCPOST
  return p;
}

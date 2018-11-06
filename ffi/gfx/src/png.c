#include <setjmp.h>
#include <png.h>
#include <string.h>
#include <errno.h>

#include "gfx.h"


#ifndef png_jmpbuf
#  define png_jmpbuf(png_ptr)   ((png_ptr)->jmpbuf)
#endif

gfx_t *gfx_load_png(char *filename) {
  gfx_t *gfx = 0;
  int i, x, y;
  png_structp png_ptr = NULL;
  png_infop info_ptr = NULL;
  png_infop end_info = NULL;
  png_uint_32 width, height, rowbytes;
  int bit_depth, color_type;
  png_byte *image_data = 0;
  png_bytep *row_pointers = 0;
  uint8_t sig[8];
  FILE *infile;

  infile = fopen(filename, "rb");

  if (!infile) {
    fprintf(stderr, "cant open `%s`\nError: %s\n", filename, strerror(errno));
    return 0;
  }

  if (0) {
fail:
    if (gfx) free(gfx);
    if (image_data) free(image_data);
    if (row_pointers) free(row_pointers);
    fclose(infile);
    return 0;
  }

  fread(sig, 1, 8, infile);
  if (!png_check_sig(sig, 8)) {
    fprintf(stderr, "bad signature for `%s`\n", filename);
    goto fail;
  }

  png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_ptr) {
    fprintf(stderr, "png_create_info_struct: out of memory for `%s`\n", filename);
    goto fail;
  }

  info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_read_struct(&png_ptr, NULL, NULL);
    fprintf(stderr, "png_create_info_struct: out of memory for `%s`\n", filename);
    goto fail;
  }

  end_info = png_create_info_struct(png_ptr);
  if (!end_info) {
    fprintf(stderr, "error: png_create_info_struct returned 0.\n");
    png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp) NULL);
    goto fail;
  }

  // setjmp() must be called in every function that calls a PNG-reading libpng function
  if (setjmp(png_jmpbuf(png_ptr))) {
jmpbuf_fail:
    png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
    goto fail;
  }

  png_init_io(png_ptr, infile);
  png_set_sig_bytes(png_ptr, 8); // tell libpng that we already read the 8 signature bytes
  png_read_info(png_ptr, info_ptr); // read all PNG info up to image data

  png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, NULL, NULL, NULL);

  png_read_update_info(png_ptr, info_ptr);

  rowbytes = png_get_rowbytes(png_ptr, info_ptr);
  image_data = malloc(rowbytes * height * sizeof(png_byte)+15);
  if (!image_data) {
    fprintf(stderr, "load_png: could not allocate memory for PNG image data\n");
    png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
    goto jmpbuf_fail;
  }

  row_pointers = malloc(height * sizeof(png_bytep));
  if (!row_pointers) {
    fprintf(stderr, "load_png: could not allocate memory for PNG row pointers\n");
    png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
    goto jmpbuf_fail;
  }

  for (y = 0; y < height; y++) {
    row_pointers[height - 1 - y] = image_data + y * rowbytes;
  }

  png_read_image(png_ptr, row_pointers);

  if (bit_depth != 8 && bit_depth != 16 && color_type != PNG_COLOR_TYPE_PALETTE) {
    fprintf(stderr, "load_png: unsupported bit_depth=%d\n", bit_depth);
    goto fail;
  }

  if (color_type == PNG_COLOR_TYPE_RGB) { //RGB
    gfx = new_gfx(width, height);
    if (bit_depth == 8) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; x++) {
          gfx_set(gfx, x, y, R8G8B8(row[0], row[1], row[2]));
          row += 3;
        }
      }
    } else {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; x++) {
          gfx_set(gfx, x, y, R8G8B8(row[1], row[3], row[5]));
          row += 6;
        }
      }
    }
  } else if (color_type == PNG_COLOR_TYPE_RGB_ALPHA) {
    gfx = new_gfx(width, height);
    if (bit_depth == 8) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; x++) {
          gfx_set(gfx, x, y, R8G8B8A8(row[0], row[1], row[2], 0xFF-row[3]));
          row += 4;
        }
      }
    } else {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; x++) {
          gfx_set(gfx, x, y, R8G8B8A8(row[1], row[3], row[5], 0xFF-row[7]));
          row += 8;
        }
      }
    }
  } else if (color_type == PNG_COLOR_TYPE_PALETTE) {
    uint32_t cmap[GFX_CMAP_SIZE];
    png_colorp palette;
    int num_palette; // palette size
    png_bytep trans;
    int num_trans;
    png_color_16p trans_values;

    gfx = new_gfx(width, height);

    if (png_get_PLTE(png_ptr, info_ptr, &palette, &num_palette) == 0) {
      fprintf(stderr, "load_png: couldn't retrieve palette\n");
      png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
      goto fail;
    }

    if (png_get_tRNS(png_ptr, info_ptr, &trans, &num_trans, &trans_values) == 0) {
      num_trans = 0;
    }

    for (i = 0; i < num_palette; i++) {
      int a = i < num_trans ? 0xFF - trans[i] : 0;
      cmap[i] = R8G8B8A8(palette[i].red, palette[i].green, palette[i].blue, a);
    }

    gfx_set_cmap(gfx, cmap);

    if (bit_depth == 8) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; x++) {
          gfx_set(gfx, x, y, row[0]);
          row++;
        }
      }
    } else if (bit_depth == 4) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; ) {
          png_byte c = row[0];
          for (i = 4; i >=0 ; i-=4) {
            gfx_set(gfx, x, y, (c>>i)&0xF);
            if (++x == width) break;
          }
          row++;
        }
      }
    } else if (bit_depth == 2) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; ) {
          png_byte c = row[0];
          for (i = 6; i >=0 ; i-=2) {
            gfx_set(gfx, x, y, (c>>i)&0x3);
            if (++x == width) break;
          }
          row++;
        }
      }
    } else if (bit_depth == 1) {
      for (y = 0; y < height; y++) {
        png_byte *row = row_pointers[y];
        for (x = 0; x < width; ) {
          png_byte c = row[0];
          for (i = 7; i >=0 ; i-=1) {
            gfx_set(gfx, x, y, (c>>i)&0x1);
            if (++x == width) break;
          }
          row++;
        }
      }
    } else {
      fprintf(stderr, "load_png: implement indexed bit_depth=%d\n", bit_depth);
      abort();
    }
  } else {
    fprintf(stderr, "load_png: unsupported color_type=%d\n", color_type);
    goto fail;
  }

  png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
  fclose(infile);

  free(image_data);
  free(row_pointers);

  return gfx;
}

void gfx_save_png(char *filename, gfx_t *gfx) {
  png_structp Png;
  png_infop Info;
  int I, X, Y, BPR;
  png_byte *Q, **Rows;
  FILE *F;
  png_color Pal[256];
  png_color_16 CK;
  png_byte Alpha[256];
  int Bits;

  if (gfx->cmap) {
    Bits = 8;
  } else {
    Bits = 24;
    times (Y, gfx->h) {
      times (X, gfx->w) {
        int r, g, b, a;
        fromR8G8B8A8(r,g,b,a, gfx_get(gfx,X,Y));
        if (a) {
          Bits = 32;
          goto bits32;
        }
      }
    }
    bits32:;
  }

  F = fopen(filename, "wb");
  if (!F) {
    printf("cant create %s\n", filename);
    abort();
  }

  Png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  Info = png_create_info_struct(Png);
  png_set_IHDR(Png,
               Info,
               gfx->w,
               gfx->h,
               8, // depth of color channel
               Bits == 8 ? PNG_COLOR_TYPE_PALETTE :
               Bits == 32 ? PNG_COLOR_TYPE_RGB_ALPHA :
                            PNG_COLOR_TYPE_RGB,
               PNG_INTERLACE_NONE,
               PNG_COMPRESSION_TYPE_DEFAULT,
               PNG_FILTER_TYPE_DEFAULT);

  BPR = (gfx->w*Bits + 7)/8;
  Rows = png_malloc(Png, gfx->h * sizeof(png_byte *));
  if (Bits == 8) {
    CK.index = 0;
    times (I, 256) {
      fromR8G8B8A8(Pal[I].red, Pal[I].green, Pal[I].blue, Alpha[I], gfx->cmap[I]);
      if (Alpha[I] == 0xFF && !CK.index) CK.index = I;
      Alpha[I] = 0xFF - Alpha[I];
    }
    png_set_tRNS(Png, Info, Alpha, 256, &CK);
    png_set_PLTE(Png, Info, Pal, 256);
    times (Y, gfx->h) {
      Rows[Y] = Q = png_malloc(Png, BPR);
      times (X, gfx->w) *Q++ = (uint8_t)gfx_get(gfx,X,Y);
    }
  } else if (Bits == 24) {
    times (Y, gfx->h) {
      Rows[Y] = Q = png_malloc(Png, BPR);
      times (X, gfx->w) {
        fromR8G8B8(Q[0],Q[1],Q[2], gfx_get(gfx,X,Y));
        Q += 3;
      }
    }
  } else if (Bits == 32) {
    times (Y, gfx->h) {
      Rows[Y] = Q = png_malloc(Png, BPR);
      times (X, gfx->w) {
        fromR8G8B8A8(Q[0],Q[1],Q[2],Q[3], gfx_get(gfx,X,Y));
        Q[3] = 0xFF - Q[3];
        Q += 4;
      }
    }
  } else {
    printf("  png_save: cant save %d-bits PNGs\n", Bits);
    abort();
  }

  png_init_io(Png, F);
  png_set_rows(Png, Info, Rows);
  png_write_png(Png, Info, PNG_TRANSFORM_IDENTITY, NULL);

  times (Y, gfx->h) png_free(Png, Rows[Y]);
  png_free(Png, Rows);

  png_destroy_write_struct(&Png, &Info);
  fclose(F);
}

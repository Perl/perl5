#ifndef ENCODE_H
#define ENCODE_H
#ifndef U8
typedef unsigned char U8;
#endif

typedef struct encpage_s encpage_t;

struct encpage_s
{
 const U8   *seq;
 encpage_t  *next;
 U8         min;
 U8         max;
 U8         dlen;
 U8         slen;
};

typedef struct encode_s encode_t;
struct encode_s
{
 encpage_t  *t_utf8;
 encpage_t  *f_utf8;
 const U8   *rep;
 int        replen;
 U8         min_el;
 U8         max_el;
 const char *name[2];
};

#ifdef U8
extern int do_encode(encpage_t *enc, const U8 *src, STRLEN *slen,
                     U8 *dst, STRLEN dlen, STRLEN *dout, int approx);

extern void Encode_DefineEncoding(encode_t *enc);
#endif

#define ENCODE_NOSPACE  1
#define ENCODE_PARTIAL  2
#define ENCODE_NOREP    3
#define ENCODE_FALLBACK 4
#endif

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
 const char *name;
 encpage_t  *t_utf8;
 encpage_t  *f_utf8;
 const U8   *rep;
 int        replen;
};


#ifndef CECTYPE_H
#define CECTYPE_H 1

#if UNDER_CE < 300
#define isdigit(C) iswdigit(C)
#define isalpha(C) iswalpha(C)
#define islower(C) iswlower(C)
#define isupper(C) iswupper(C)
#define isspace(C) iswspace(C)
#define isalnum(C) iswalnum(C)
#define iscntrl(C) iswcntrl(C)
#define isprint(C) iswprint(C)
#define ispunct(C) iswpunct(C)
#define isxdigit(C) iswxdigit(C)
#define isascii(C) iswascii(C)
#define isgraph(C) iswgraph(C)
#endif

#endif

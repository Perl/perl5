#ifndef SYS_TYPES_H
#define SYS_TYPES_H 1

#ifndef _TIME_T_DEFINED_
typedef unsigned long time_t;
#define _TIME_T_DEFINED_
#endif

typedef unsigned long dev_t;
typedef unsigned long ino_t;
typedef unsigned short gid_t;
typedef unsigned short uid_t;
typedef long clock_t;
typedef long ptrdiff_t;
typedef long off_t;

typedef unsigned char u_char;
typedef unsigned short u_short;

typedef unsigned char * caddr_t;
typedef unsigned int size_t;

#endif

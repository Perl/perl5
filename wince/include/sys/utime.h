#ifndef SYS_UTIME_H
#define SYS_UTIME_H 1

#include "time.h"

struct utimbuf 
{
  time_t actime;
  time_t modtime;
};

struct _utimbuf 
{
  time_t actime;
  time_t modtime;
};

#endif

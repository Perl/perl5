
#ifdef __cplusplus
extern "C" {
#endif

#define WIN32_LEAN_AND_MEAN
#define WIN32IO_IS_STDIO
#define EXT
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <assert.h>
#include <errno.h>

#include "win32iop.h"

struct servent*
win32_savecopyservent(struct servent*d, struct servent*s, const char *proto)
{
    d->s_name = s->s_name;
    d->s_aliases = s->s_aliases;
    d->s_port = s->s_port;
    if (s->s_proto && strlen(s->s_proto))
	d->s_proto = s->s_proto;
    else if (proto && strlen(proto))
	d->s_proto = (char *)proto;
    else
	d->s_proto = "tcp";
   
    return d;
}

#ifdef __cplusplus
}
#endif


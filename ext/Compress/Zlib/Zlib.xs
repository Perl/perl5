/* Filename: Zlib.xs
 * Author  : Paul Marquess, <pmqs@cpan.org>
 * Created : 30 January 2005
 * Version : 1.40
 *
 *   Copyright (c) 1995-2005 Paul Marquess. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */

/* Part of this code is based on the file gzio.c */

/* gzio.c -- IO on .gz files
 * Copyright (C) 1995 Jean-loup Gailly.
 * For conditions of distribution and use, see copyright notice in zlib.h
 */



#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <zlib.h> 

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION	5
#define PERL_VERSION	PATCHLEVEL
#define PERL_SUBVERSION	SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef		sv_undef
#    define PL_na		na
#    define PL_curcop		curcop
#    define PL_compiling	compiling

#endif

#ifndef newSVuv
#    define newSVuv	newSViv
#endif

typedef struct di_stream {
    z_stream stream;
    uLong    bufsize; 
    uLong    bufinc; 
    SV *     dictionary ;
    uLong    dict_adler ;
    bool     deflateParams_out_valid ;
    Bytef    deflateParams_out_byte;
    int      Level;
    int      Method;
    int      WindowBits;
    int      MemLevel;
    int      Strategy;
} di_stream;

typedef di_stream * deflateStream ;
typedef di_stream * Compress__Zlib__deflateStream ;
typedef di_stream * inflateStream ;
typedef di_stream * Compress__Zlib__inflateStream ;

/* typedef gzFile Compress__Zlib__gzFile ; */
typedef struct gzType {
    gzFile gz ;
    SV *   buffer ;
    uLong   offset ;
    bool   closed ;
}  gzType ;

typedef gzType* Compress__Zlib__gzFile ; 



#define GZERRNO	"Compress::Zlib::gzerrno"

#define ZMALLOC(to, typ) ((to = (typ *)safemalloc(sizeof(typ))), \
                                Zero(to,1,typ))

#define adlerInitial adler32(0L, Z_NULL, 0)
#define crcInitial crc32(0L, Z_NULL, 0)

#if 1
static const char * const my_z_errmsg[] = {
    "need dictionary",     /* Z_NEED_DICT     2 */
    "stream end",          /* Z_STREAM_END    1 */
    "",                    /* Z_OK            0 */
    "file error",          /* Z_ERRNO        (-1) */
    "stream error",        /* Z_STREAM_ERROR (-2) */
    "data error",          /* Z_DATA_ERROR   (-3) */
    "insufficient memory", /* Z_MEM_ERROR    (-4) */
    "buffer error",        /* Z_BUF_ERROR    (-5) */
    "incompatible version",/* Z_VERSION_ERROR(-6) */
    ""};
#endif

#if defined(__SYMBIAN32__)
# define NO_WRITEABLE_DATA
#endif

#define TRACE_DEFAULT 0

#ifdef NO_WRITEABLE_DATA
#define trace TRACE_DEFAULT
#else
static int trace = TRACE_DEFAULT ;
#endif

/* Dodge PerlIO hiding of these functions. */
#undef printf

static void
#ifdef CAN_PROTOTYPE
SetGzErrorNo(int error_no)
#else
SetGzErrorNo(error_no)
int error_no ;
#endif
{
#ifdef dTHX    
    dTHX;
#endif    
    char * errstr ;
    SV * gzerror_sv = perl_get_sv(GZERRNO, FALSE) ;
  
    if (error_no == Z_ERRNO) {
        error_no = errno ;
        errstr = Strerror(errno) ;
    }
    else
        /* errstr = gzerror(fil, &error_no) ; */
        errstr = (char*) my_z_errmsg[2 - error_no]; 

    if (SvIV(gzerror_sv) != error_no) {
        sv_setiv(gzerror_sv, error_no) ;
        sv_setpv(gzerror_sv, errstr) ;
        SvIOK_on(gzerror_sv) ;
    }

}

static void
#ifdef CAN_PROTOTYPE
SetGzError(gzFile file)
#else
SetGzError(file)
gzFile file ;
#endif
{
    int error_no ;

    (void)gzerror(file, &error_no) ;
    SetGzErrorNo(error_no) ;
}

static void
#ifdef CAN_PROTOTYPE
DispHex(void * ptr, int length)
#else
DispHex(ptr, length)
    void * ptr;
    int length;
#endif
{
    char * p = (char*)ptr;
    int i;
    for (i = 0; i < length; ++i) {
        printf(" %02x", 0xFF & *(p+i));
    }
}


static void
#ifdef CAN_PROTOTYPE
DispStream(di_stream * s, char * message)
#else
DispStream(s, message)
    di_stream * s;
    char * message;
#endif
{

#if 0
    if (! trace)
        return ;
#endif

    printf("DispStream 0x%p - %s \n", s, message) ;

    if (!s)  {
	printf("    stream pointer is NULL\n");
    }
    else     {
	printf("    stream           0x%p\n", &(s->stream));
	printf("           zalloc    0x%p\n", s->stream.zalloc);
	printf("           zfree     0x%p\n", s->stream.zfree);
	printf("           opaque    0x%p\n", s->stream.opaque);
	if (s->stream.msg)
	    printf("           msg       %s\n", s->stream.msg);
	else
	    printf("           msg       \n");
	printf("           next_in   0x%p", s->stream.next_in);
    	if (s->stream.next_in) {
	    printf(" =>");
            DispHex(s->stream.next_in, 4);
	}
        printf("\n");

	printf("           next_out  0x%p", s->stream.next_out);
    	if (s->stream.next_out){
	    printf(" =>");
            DispHex(s->stream.next_out, 4);
	}
        printf("\n");

	printf("           avail_in  %ld\n", s->stream.avail_in);
	printf("           avail_out %ld\n", s->stream.avail_out);
	printf("           total_in  %ld\n", s->stream.total_in);
	printf("           total_out %ld\n", s->stream.total_out);
	printf("           adler     0x%lx\n", s->stream.adler);
	printf("           reserved  0x%lx\n", s->stream.reserved);
	printf("    bufsize          %ld\n", s->bufsize);
	printf("    dictionary       0x%p\n", s->dictionary);
	printf("    dict_adler       0x%ld\n", s->dict_adler);
	printf("\n");

    }
}


static di_stream *
#ifdef CAN_PROTOTYPE
InitStream(uLong bufsize)
#else
InitStream(bufsize)
    uLong bufsize ;
#endif
{
    di_stream *s ;

    ZMALLOC(s, di_stream) ;

    if (s)  {
        s->bufsize = bufsize ;
        s->bufinc  = bufsize ;
    }

    return s ;
    
}

#define SIZE 4096

static int
#ifdef CAN_PROTOTYPE
gzreadline(Compress__Zlib__gzFile file, SV * output)
#else
gzreadline(file, output)
  Compress__Zlib__gzFile file ;
  SV * output ;
#endif
{
#ifdef dTHX    
    dTHX;
#endif    
    SV * store = file->buffer ;
    char *nl = "\n"; 
    char *p;
    char *out_ptr = SvPVX(store) ;
    int n;

    while (1) {

	/* anything left from last time */
	if ((n = SvCUR(store))) {

    	    out_ptr = SvPVX(store) + file->offset ;
	    if ((p = ninstr(out_ptr, out_ptr + n - 1, nl, nl))) {
            /* if (rschar != 0777 && */
                /* p = ninstr(out_ptr, out_ptr + n - 1, rs, rs+rslen-1)) { */

         	sv_catpvn(output, out_ptr, p - out_ptr + 1);

		file->offset += (p - out_ptr + 1) ;
	        n = n - (p - out_ptr + 1);
	        SvCUR_set(store, n) ;
	        return SvCUR(output);
            }
	    else /* no EOL, so append the complete buffer */
         	sv_catpvn(output, out_ptr, n);
	    
	}


	SvCUR_set(store, 0) ;
	file->offset = 0 ;
        out_ptr = SvPVX(store) ;

	n = gzread(file->gz, out_ptr, SIZE) ;

	if (n <= 0) 
	    /* Either EOF or an error */
	    /* so return what we have so far else signal eof */
	    return (SvCUR(output)>0) ? SvCUR(output) : n ;

	SvCUR_set(store, n) ;
    }
}

static SV* 
#ifdef CAN_PROTOTYPE
deRef(SV * sv, char * string)
#else
deRef(sv, string)
SV * sv ;
char * string;
#endif
{
#ifdef dTHX    
    dTHX;
#endif    
    if (SvROK(sv)) {
	sv = SvRV(sv) ;
	switch(SvTYPE(sv)) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV:
                croak("%s: buffer parameter is not a SCALAR reference", string);
	}
	if (SvROK(sv))
	    croak("%s: buffer parameter is a reference to a reference", string) ;
    }

    if (!SvOK(sv)) { 
        sv = newSVpv("", 0);
    }	
    return sv ;
}

#include "constants.h"

MODULE = Compress::Zlib		PACKAGE = Compress::Zlib	PREFIX = Zip_

REQUIRE:	1.924
PROTOTYPES:	DISABLE

INCLUDE: constants.xs

BOOT:
    /* Check this version of zlib is == 1 */
    if (zlibVersion()[0] != '1')
	croak("Compress::Zlib needs zlib version 1.x\n") ;
	
    {
        /* Create the $gzerror scalar */
        SV * gzerror_sv = perl_get_sv(GZERRNO, GV_ADDMULTI) ;
        sv_setiv(gzerror_sv, 0) ;
        sv_setpv(gzerror_sv, "") ;
        SvIOK_on(gzerror_sv) ;
    }


#define Zip_zlib_version()	(char*)zlib_version
char*
Zip_zlib_version()

unsigned
ZLIB_VERNUM()
    CODE:
#ifdef ZLIB_VERNUM
        RETVAL = ZLIB_VERNUM ;
#else
        /* 1.1.4 => 0x1140 */
        RETVAL  = (ZLIB_VERSION[0] - '0') << 12 ;
        RETVAL += (ZLIB_VERSION[2] - '0') <<  8 ;
        RETVAL += (ZLIB_VERSION[4] - '0') <<  4 ;
#endif
    OUTPUT:
        RETVAL

    

void
DispStream(s, message=NULL)
  	Compress::Zlib::inflateStream	s
	char * 	message

Compress::Zlib::gzFile
gzopen_(path, mode)
	char *	path
	char *	mode
	CODE:
	gzFile	gz ;
	gz = gzopen(path, mode) ;
	if (gz) {
	    ZMALLOC(RETVAL, gzType) ;
    	    RETVAL->buffer = newSV(SIZE) ;
    	    SvPOK_only(RETVAL->buffer) ;
    	    SvCUR_set(RETVAL->buffer, 0) ; 
	    RETVAL->offset = 0 ;
	    RETVAL->gz = gz ;
	    RETVAL->closed = FALSE ;
	    SetGzErrorNo(0) ;
	}
	else {
	    RETVAL = NULL ;
	    SetGzErrorNo(errno ? Z_ERRNO : Z_MEM_ERROR) ;
	}
	OUTPUT:
	  RETVAL


Compress::Zlib::gzFile
gzdopen_(fh, mode, offset)
        int     fh
        char *  mode
        long    offset
	CODE:
        gzFile  gz ;
        if (offset != -1)
            lseek(fh, offset, 0) ; 
        gz = gzdopen(fh, mode) ;
        if (gz) {
	    ZMALLOC(RETVAL, gzType) ;
            RETVAL->buffer = newSV(SIZE) ;
            SvPOK_only(RETVAL->buffer) ;
            SvCUR_set(RETVAL->buffer, 0) ;
            RETVAL->offset = 0 ;
            RETVAL->gz = gz ;
	    RETVAL->closed = FALSE ;
	    SetGzErrorNo(0) ;
        }
        else {
            RETVAL = NULL ;
	    SetGzErrorNo(errno ? Z_ERRNO : Z_MEM_ERROR) ;
	}
        OUTPUT:
          RETVAL


MODULE = Compress::Zlib	PACKAGE = Compress::Zlib::gzFile PREFIX = Zip_

#define Zip_gzread(file, buf, len) gzread(file->gz, bufp, len)

int
Zip_gzread(file, buf, len=4096)
	Compress::Zlib::gzFile	file
	unsigned	len
	SV *		buf
	voidp		bufp = NO_INIT
	uLong		bufsize = 0 ;
	int		RETVAL = 0 ;
	CODE:
	if (SvREADONLY(buf) && PL_curcop != &PL_compiling)
            croak("gzread: buffer parameter is read-only");
        SvUPGRADE(buf, SVt_PV);
        SvPOK_only(buf);
        SvCUR_set(buf, 0);
	/* any left over from gzreadline ? */
	if ((bufsize = SvCUR(file->buffer)) > 0) {
	    uLong movesize ;
	
	    if (bufsize < len) {
		movesize = bufsize ;
	        len -= movesize ;
	    }
	    else {
	        movesize = len ;
	        len = 0 ;
	    }
	    RETVAL = movesize ;

       	    sv_catpvn(buf, SvPVX(file->buffer) + file->offset, movesize);

	    file->offset += movesize ;
	    SvCUR_set(file->buffer, bufsize - movesize) ;
	}

	if (len) {
	    bufp = (Byte*)SvGROW(buf, bufsize+len+1);
	    RETVAL = gzread(file->gz, ((Bytef*)bufp)+bufsize, len) ;
	    SetGzError(file->gz) ; 
            if (RETVAL >= 0) {
		RETVAL += bufsize ;
                SvCUR_set(buf, RETVAL) ;
                *SvEND(buf) = '\0';
            }
	}
	OUTPUT:
	   RETVAL
	   buf

int
gzreadline(file, buf)
	Compress::Zlib::gzFile	file
	SV *		buf
	int		RETVAL = 0;
	CODE:
	if (SvREADONLY(buf) && PL_curcop != &PL_compiling) 
            croak("gzreadline: buffer parameter is read-only"); 
        SvUPGRADE(buf, SVt_PV);
        SvPOK_only(buf);
	/* sv_setpvn(buf, "", SIZE) ; */
        SvGROW(buf, SIZE) ;
        SvCUR_set(buf, 0);
	RETVAL = gzreadline(file, buf) ;
	SetGzError(file->gz) ; 
	OUTPUT:
	  RETVAL
	  buf
	CLEANUP:
        if (RETVAL >= 0) {
            /* SvCUR(buf) = RETVAL; */
            /* Don't need to explicitly terminate with '\0', because
		sv_catpvn aready has */
        }

#define Zip_gzwrite(file, buf) gzwrite(file->gz, buf, (unsigned)len)
int
Zip_gzwrite(file, buf)
	Compress::Zlib::gzFile	file
	STRLEN		len = NO_INIT
	voidp 		buf = (voidp)SvPV(ST(1), len) ;
	CLEANUP:
	  SetGzError(file->gz) ;

#define Zip_gzflush(file, flush) gzflush(file->gz, flush) 
int
Zip_gzflush(file, flush)
	Compress::Zlib::gzFile	file
	int		flush
	CLEANUP:
	  SetGzError(file->gz) ;

#define Zip_gzclose(file) file->closed ? 0 : gzclose(file->gz)
int
Zip_gzclose(file)
	Compress::Zlib::gzFile		file
	CLEANUP:
	  file->closed = TRUE ;
	  SetGzErrorNo(RETVAL) ;


#define Zip_gzeof(file) gzeof(file->gz)
int
Zip_gzeof(file)
	Compress::Zlib::gzFile		file
	CODE:
#ifdef OLD_ZLIB
	croak("gzeof needs zlib 1.0.6 or better") ;
#else
	RETVAL = gzeof(file->gz);
#endif
	OUTPUT:
	    RETVAL


#define Zip_gzsetparams(file,l,s) gzsetparams(file->gz,l,s)
int
Zip_gzsetparams(file, level, strategy)
	Compress::Zlib::gzFile		file
	int		level
	int		strategy
	CODE:
#ifdef OLD_ZLIB
	croak("gzsetparams needs zlib 1.0.6 or better") ;
#else
	RETVAL = gzsetparams(file->gz, level, strategy);
#endif
	OUTPUT:
	    RETVAL

void
DESTROY(file)
	Compress::Zlib::gzFile		file
	CODE:
	    if (! file->closed)
	        Zip_gzclose(file) ;
	    SvREFCNT_dec(file->buffer) ;
	    safefree((char*)file) ;

#define Zip_gzerror(file) (char*)gzerror(file->gz, &errnum)

char *
Zip_gzerror(file)
	Compress::Zlib::gzFile	file
	int		errnum = NO_INIT
	CLEANUP:
	    sv_setiv(ST(0), errnum) ;
            SvPOK_on(ST(0)) ;



MODULE = Compress::Zlib	PACKAGE = Compress::Zlib	PREFIX = Zip_


#define Zip_adler32(buf, adler) adler32(adler, buf, (uInt)len)

uLong
Zip_adler32(buf, adler=adlerInitial)
        uLong    adler = NO_INIT
        STRLEN   len = NO_INIT
        Bytef *  buf = NO_INIT
	SV *	 sv = ST(0) ;
	INIT:
    	/* If the buffer is a reference, dereference it */
	sv = deRef(sv, "adler32") ;
	buf = (Byte*)SvPV(sv, len) ;

	if (items < 2)
	  adler = adlerInitial;
	else if (SvOK(ST(1)))
	  adler = SvUV(ST(1)) ;
	else
	  adler = adlerInitial;
 
#define Zip_crc32(buf, crc) crc32(crc, buf, (uInt)len)

uLong
Zip_crc32(buf, crc=crcInitial)
        uLong    crc = NO_INIT
        STRLEN   len = NO_INIT
        Bytef *  buf = NO_INIT
	SV *	 sv = ST(0) ;
	INIT:
    	/* If the buffer is a reference, dereference it */
	sv = deRef(sv, "crc32") ;
	buf = (Byte*)SvPV(sv, len) ;

	if (items < 2)
	  crc = crcInitial;
	else if (SvOK(ST(1)))
	  crc = SvUV(ST(1)) ;
	else
	  crc = crcInitial;

MODULE = Compress::Zlib PACKAGE = Compress::Zlib

void
_deflateInit(level, method, windowBits, memLevel, strategy, bufsize, dictionary)
    int	level
    int method
    int windowBits
    int memLevel
    int strategy
    uLong bufsize
    SV * dictionary
  PPCODE:

    int err ;
    deflateStream s ;

    if (trace)
        warn("in _deflateInit(level=%d, method=%d, windowBits=%d, memLevel=%d, strategy=%d, bufsize=%d\n",
	level, method, windowBits, memLevel, strategy, bufsize) ;
    if ((s = InitStream(bufsize)) ) {

        s->Level      = level;
        s->Method     = method;
        s->WindowBits = windowBits;
        s->MemLevel   = memLevel;
        s->Strategy   = strategy;

        err = deflateInit2(&(s->stream), level, 
			   method, windowBits, memLevel, strategy);

	/* Check if a dictionary has been specified */
	if (err == Z_OK && SvCUR(dictionary)) {
	    err = deflateSetDictionary(&(s->stream), (const Bytef*) SvPVX(dictionary), 
					SvCUR(dictionary)) ;
	    s->dict_adler = s->stream.adler ;
	}

        if (err != Z_OK) {
            Safefree(s) ;
            s = NULL ;
	}
        
    }
    else
        err = Z_MEM_ERROR ;

    XPUSHs(sv_setref_pv(sv_newmortal(), 
	"Compress::Zlib::deflateStream", (void*)s));
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;

void
_inflateInit(windowBits, bufsize, dictionary)
    int windowBits
    uLong bufsize
    SV * dictionary
  PPCODE:
 
    int err = Z_OK ;
    inflateStream s ;
 
    if (trace)
        warn("in _inflateInit(windowBits=%d, bufsize=%d, dictionary=%d\n",
                windowBits, bufsize, SvCUR(dictionary)) ;
    if ((s = InitStream(bufsize)) ) {

        s->WindowBits = windowBits;

        err = inflateInit2(&(s->stream), windowBits);
 
        if (err != Z_OK) {
            Safefree(s) ;
            s = NULL ;
	}
	else if (SvCUR(dictionary)) {
            /* Dictionary specified - take a copy for use in inflate */
	    s->dictionary = newSVsv(dictionary) ;
	}
    }
    else
	err = Z_MEM_ERROR ;

    XPUSHs(sv_setref_pv(sv_newmortal(), 
                   "Compress::Zlib::inflateStream", (void*)s));
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;
 


MODULE = Compress::Zlib PACKAGE = Compress::Zlib::deflateStream

void
DispStream(s, message=NULL)
  	Compress::Zlib::deflateStream	s
	char * 	message

void 
deflate (s, buf)
    Compress::Zlib::deflateStream	s
    SV *	buf
    uLong	outsize = NO_INIT 
    SV * 	output = NO_INIT
    int		err = 0;
  PPCODE:
  
    /* If the buffer is a reference, dereference it */
    buf = deRef(buf, "deflate") ;
 
    /* initialise the input buffer */
    s->stream.next_in = (Bytef*)SvPV(buf, *(STRLEN*)&s->stream.avail_in) ;
    /* s->stream.next_in = (Bytef*)SvPVX(buf); */
    s->stream.avail_in = SvCUR(buf) ;

    /* and the output buffer */
    /* output = sv_2mortal(newSVpv("", s->bufinc)) ; */
    output = sv_2mortal(newSV(s->bufinc)) ;
    SvPOK_only(output) ;
    SvCUR_set(output, 0) ; 
    outsize = s->bufinc ;
    s->stream.next_out = (Bytef*) SvPVX(output) ;
    s->stream.avail_out = outsize;

    /* Check for saved output from deflateParams */
    if (s->deflateParams_out_valid) {
	*(s->stream.next_out) = s->deflateParams_out_byte;
	++ s->stream.next_out;
	-- s->stream.avail_out ;
	s->deflateParams_out_valid = FALSE;
    }

    while (s->stream.avail_in != 0) {

        if (s->stream.avail_out == 0) {
            s->bufinc *= 2 ;
            SvGROW(output, outsize + s->bufinc) ;
            s->stream.next_out = (Bytef*) SvPVX(output) + outsize ;
            outsize += s->bufinc ;
            s->stream.avail_out = s->bufinc ;
        }
        err = deflate(&(s->stream), Z_NO_FLUSH);
        if (err != Z_OK) 
            break;
    }

    if (err == Z_OK) {
        SvPOK_only(output);
        SvCUR_set(output, outsize - s->stream.avail_out) ;
    }
    else
        output = &PL_sv_undef ;
    XPUSHs(output) ;
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;
  


void
flush(s, f=Z_FINISH)
    Compress::Zlib::deflateStream	s
    int	f
    uLong	outsize = NO_INIT
    SV * output = NO_INIT
    int err = Z_OK ;
  PPCODE:
  
    s->stream.avail_in = 0; /* should be zero already anyway */
  
    /* output = sv_2mortal(newSVpv("", s->bufinc)) ; */
    output = sv_2mortal(newSV(s->bufinc)) ;
    SvPOK_only(output) ;
    SvCUR_set(output, 0) ; 
    outsize = s->bufinc ;
    s->stream.next_out = (Bytef*) SvPVX(output) ;
    s->stream.avail_out = outsize;
      
    /* Check for saved output from deflateParams */
    if (s->deflateParams_out_valid) {
	*(s->stream.next_out) = s->deflateParams_out_byte;
	++ s->stream.next_out;
	-- s->stream.avail_out ;
	s->deflateParams_out_valid = FALSE;
    }

    for (;;) {
        if (s->stream.avail_out == 0) {
	    /* consumed all the available output, so extend it */
            s->bufinc *= 2 ;
	    SvGROW(output, outsize + s->bufinc) ;
            s->stream.next_out = (Bytef*)SvPVX(output) + outsize ;
	    outsize += s->bufinc ;
            s->stream.avail_out = s->bufinc ;
        }
        err = deflate(&(s->stream), f);
    
        /* deflate has finished flushing only when it hasn't used up
         * all the available space in the output buffer: 
         */
        if (s->stream.avail_out != 0 || err != Z_OK )
            break;
    }
  
    err =  (err == Z_STREAM_END ? Z_OK : err) ;
  
    if (err == Z_OK) {
        SvPOK_only(output);
        SvCUR_set(output, outsize - s->stream.avail_out) ;
    }
    else
        output = &PL_sv_undef ;
    XPUSHs(output) ;
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;

int
_deflateParams(s, flags, level, strategy, bufsize)
  	Compress::Zlib::deflateStream	s
	int 	flags
	int	level
	int	strategy
    	uLong	bufsize
    CODE:
	if (flags & 1)
	    s->Level = level ;
	if (flags & 2)
	    s->Strategy = strategy ;
        if (bufsize) {
            s->bufsize = bufsize; 
            s->bufinc  = bufsize; 
	}
        s->stream.avail_in = 0; 
        s->stream.next_out = &(s->deflateParams_out_byte) ;
        s->stream.avail_out = 1;
	RETVAL = deflateParams(&(s->stream), s->Level, s->Strategy);
	s->deflateParams_out_valid = 
		(RETVAL == Z_OK && s->stream.avail_out == 0) ;
    OUTPUT:
	RETVAL


int
get_Level(s)
        Compress::Zlib::deflateStream   s
    CODE:
	RETVAL = s->Level ;
    OUTPUT:
	RETVAL

int
get_Strategy(s)
        Compress::Zlib::deflateStream   s
    CODE:
	RETVAL = s->Strategy ;
    OUTPUT:
	RETVAL

void
DESTROY(s)
    Compress::Zlib::deflateStream	s
  CODE:
    deflateEnd(&s->stream) ;
    if (s->dictionary)
	SvREFCNT_dec(s->dictionary) ;
    Safefree(s) ;


uLong
dict_adler(s)
        Compress::Zlib::deflateStream   s
    CODE:
	RETVAL = s->dict_adler ;
    OUTPUT:
	RETVAL

uLong
total_in(s)
        Compress::Zlib::deflateStream   s
    CODE:
	RETVAL = s->stream.total_in ;
    OUTPUT:
	RETVAL

uLong
total_out(s)
        Compress::Zlib::deflateStream   s
    CODE:
	RETVAL = s->stream.total_out ;
    OUTPUT:
	RETVAL

char*
msg(s)
        Compress::Zlib::deflateStream   s
    CODE:
        RETVAL = s->stream.msg;
    OUTPUT:
	RETVAL


MODULE = Compress::Zlib PACKAGE = Compress::Zlib::inflateStream

void
DispStream(s, message=NULL)
  	Compress::Zlib::inflateStream	s
	char * 	message

void 
inflate (s, buf)
    Compress::Zlib::inflateStream	s
    SV *	buf
    uLong	outsize = NO_INIT 
    SV * 	output = NO_INIT
    int		err = Z_OK ;
  ALIAS:
    __unc_inflate = 1
  PPCODE:
  
    /* If the buffer is a reference, dereference it */
    buf = deRef(buf, "inflate") ;
    
    /* initialise the input buffer */
    s->stream.next_in = (Bytef*)SvPVX(buf) ;
    s->stream.avail_in = SvCUR(buf) ;
	
    /* and the output buffer */
    output = sv_2mortal(newSV(s->bufinc+1)) ;
    SvPOK_only(output) ;
    SvCUR_set(output, 0) ; 
    outsize = s->bufinc ;
    s->stream.next_out = (Bytef*) SvPVX(output)  ;
    s->stream.avail_out = outsize;

    while (1) {

        if (s->stream.avail_out == 0) {
            s->bufinc *= 2 ;
            SvGROW(output, outsize + s->bufinc+1) ;
            s->stream.next_out = (Bytef*) SvPVX(output) + outsize ;
            outsize += s->bufinc ;
            s->stream.avail_out = s->bufinc ;
        }

        err = inflate(&(s->stream), Z_SYNC_FLUSH);
	if (err == Z_BUF_ERROR) {
	    if (s->stream.avail_out == 0)
	        continue ;
	    if (s->stream.avail_in == 0) {
		err = Z_OK ;
	        break ;
	    }
	}

	if (err == Z_NEED_DICT && s->dictionary) {
	    s->dict_adler = s->stream.adler ;
            err = inflateSetDictionary(&(s->stream), 
	    				(const Bytef*)SvPVX(s->dictionary),
					SvCUR(s->dictionary));
	}
       
        if (err != Z_OK) 
            break;
    }

    if (err == Z_OK || err == Z_STREAM_END || err == Z_DATA_ERROR) {
	unsigned in ;
	
        SvPOK_only(output);
        SvCUR_set(output, outsize - s->stream.avail_out) ;
        *SvEND(output) = '\0';
    	
 	/* fix the input buffer */
	if (ix == 0) {
 	    in = s->stream.avail_in ;
 	    SvCUR_set(buf, in) ;
 	    if (in)
     	        Move(s->stream.next_in, SvPVX(buf), in, char) ;	
            *SvEND(buf) = '\0';
            SvSETMAGIC(buf);
	}
    }
    else
        output = &PL_sv_undef ;
    XPUSHs(output) ;
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;

int 
inflateSync (s, buf)
    Compress::Zlib::inflateStream	s
    SV *	buf
  CODE:
  
    /* If the buffer is a reference, dereference it */
    buf = deRef(buf, "inflateSync") ;
    
    /* initialise the input buffer */
    s->stream.next_in = (Bytef*)SvPVX(buf) ;
    s->stream.avail_in = SvCUR(buf) ;
	
    /* inflateSync doesn't create any output */
    s->stream.next_out = (Bytef*) NULL;
    s->stream.avail_out = 0;

    RETVAL = inflateSync(&(s->stream));
    {
 	/* fix the input buffer */
	unsigned in = s->stream.avail_in ;
	
 	SvCUR_set(buf, in) ;
 	if (in)
     	    Move(s->stream.next_in, SvPVX(buf), in, char) ;	
        *SvEND(buf) = '\0';
        SvSETMAGIC(buf);
    }
    OUTPUT:
	RETVAL

void
DESTROY(s)
    Compress::Zlib::inflateStream	s
  CODE:
    inflateEnd(&s->stream) ;
    if (s->dictionary)
	SvREFCNT_dec(s->dictionary) ;
    Safefree(s) ;


uLong
dict_adler(s)
        Compress::Zlib::inflateStream   s
    CODE:
	RETVAL = s->dict_adler ;
    OUTPUT:
	RETVAL

uLong
total_in(s)
        Compress::Zlib::inflateStream   s
    CODE:
	RETVAL = s->stream.total_in ;
    OUTPUT:
	RETVAL

uLong
total_out(s)
        Compress::Zlib::inflateStream   s
    CODE:
	RETVAL = s->stream.total_out ;
    OUTPUT:
	RETVAL

char*
msg(s)
	Compress::Zlib::inflateStream   s
    CODE:
        RETVAL = s->stream.msg;
    OUTPUT:
	RETVAL



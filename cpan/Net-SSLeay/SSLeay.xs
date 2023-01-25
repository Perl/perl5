/* SSLeay.xs - Perl module for using Eric Young's implementation of SSL
 *
 * Copyright (c) 1996-2003 Sampo Kellomäki <sampo@iki.fi>
 * Copyright (c) 2005-2010 Florian Ragwitz <rafl@debian.org>
 * Copyright (c) 2005-2018 Mike McCauley <mikem@airspayce.com>
 * Copyright (c) 2018- Chris Novakovic <chris@chrisn.me.uk>
 * Copyright (c) 2018- Tuure Vartiainen <vartiait@radiatorsoftware.com>
 * Copyright (c) 2018- Heikki Vatiainen <hvn@radiatorsoftware.com>
 * 
 * All rights reserved.
 *
 * Change data removed. See Changes
 *
 * This module is released under the terms of the Artistic License 2.0. For
 * details, see the LICENSE file.
 */

/* ####
 * #### PLEASE READ THE FOLLOWING RULES BEFORE YOU START EDITING THIS FILE! ####
 * ####
 *
 * Function naming conventions:
 *
 * 1/ never change the already existing function names (all calling convention) in a way
 *    that may cause backward incompatibility (e.g. add ALIAS with old name if necessary)
 *
 * 2/ it is recommended to keep the original openssl function names for functions that are:
 *
 *    1:1 wrappers to the original openssl functions
 *    see for example: X509_get_issuer_name(cert) >> Net::SSLeay::X509_get_issuer_name($cert)
 *
 *    nearly 1:1 wrappers implementing only necessary "glue" e.g. buffer handling
 *    see for example: RAND_seed(buf,len) >> Net::SSLeay::RAND_seed($buf)
 *
 * 3/ OpenSSL functions starting with "SSL_" are added into SSLeay.xs with "SLL_" prefix
 *    (e.g. SSL_CTX_new) but keep in mind that they will be available in Net::SSLeay without
 *    "SSL_" prefix (e.g. Net::SSLeay::CTX_new) - keep this for all new functions
 *
 * 4/ The names of functions which do not fit rule 2/ (which means they implement some non
 *    trivial code around original openssl function or do more complex tasks) should be
 *    prefixed with "P_" - see for example: P_ASN1_TIME_set_isotime
 *
 * 5/ Exceptions from rules above:
 *    functions that are part or wider set of already existing function not following this rule
 *    for example: there already exists: PEM_get_string_X509_CRL + PEM_get_string_X509_REQ and you want
 *    to add PEM_get_string_SOMETHING - then no need to follow 3/ (do not prefix with "P_")
 *
 * Support for different Perl versions, libssl implementations, platforms, and compilers:
 *
 * 1/ Net-SSLeay has a version support policy for Perl and OpenSSL/LibreSSL (described in the
 *    "Prerequisites" section in the README file). The test suite must pass when run on any
 *    of those version combinations.
 *
 * 2/ Fix all compiler warnings - we expect 100% clean build
 *
 * 3/ If you add a function which is available since certain openssl version
 *    use proper #ifdefs to assure that SSLeay.xs will compile also with older versions
 *    which are missing this function
 *
 * 4/ Even warnings arising from different use of "const" in different openssl versions
 *    needs to be hanled with #ifdefs - see for example: X509_NAME_add_entry_by_txt
 *
 * 5/ avoid using global C variables (it is very likely to break thread-safetyness)
 *    use rather global MY_CXT structure
 *
 * 6/ avoid using any UNIX/POSIX specific functions, keep in mind that SSLeay.xs must
 *    compile also on non-UNIX platforms like MS Windows and others
 *
 * 7/ avoid using c++ comments "//" (or other c++ features accepted by some c compiler)
 *    even if your compiler can handle them without warnings
 *
 * Passing test suite:
 *
 * 1/ any changes to SSLeay.xs must not introduce a failure of existing test suite
 *
 * 2/ it is strongly recommended to create test(s) for newly added function(s), especially
 *    when the new function is not only a 1:1 wrapper but contains a complex code
 *
 * 3/ it is mandatory to add a documentation for all newly added functions into SSLeay.pod
 *    otherwise t/local/02_pod_coverage.t fail (and you will be asked to add some doc into
 *    your patch)
 *
 * Preferred code layout:
 *
 * 1/ for simple 1:1 XS wrappers use:
 *
 *    a/ functions with short "signature" (short list of args):
 *
 *    long
 *    SSL_set_tmp_dh(SSL *ssl,DH *dh)
 *
 *    b/ functions with long "signature" (long list of args):
 *       simply when approach a/ does not fit to 120 columns
 *
 *    void
 *    SSL_any_functions(library_flag,function_name,reason,file_name,line)
 *            int library_flag
 *            int function_name
 *            int reason
 *            char *file_name
 *            int line
 *
 * 2/ for XS functions with full implementation use identation like this:
 *
 *    int
 *    RAND_bytes(buf, num)
 *            SV *buf
 *            int num
 *        PREINIT:
 *            int rc;
 *            unsigned char *random;
 *        CODE:
 *            / * some code here * /
 *            RETVAL = rc;
 *        OUTPUT:
 *            RETVAL
 *
 *
 * Runtime debugging:
 *
 * with TRACE(level,fmt,...) you can output debug messages.
 * it behaves the same as
 *   warn sprintf($msg,...) if $Net::SSLeay::trace>=$level
 * would do in Perl (e.g. it is using also the $Net::SSLeay::trace variable)
 *
 *
 * THE LAST RULE:
 *
 * The fact that some parts of SSLeay.xs do not follow the rules above is not 
 * a reason why any new code can also break these rules in the same way
 *
 */

/* Prevent warnings about strncpy from Windows compilers */
#define _CRT_SECURE_NO_DEPRECATE

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdarg.h>
#ifdef USE_PPPORT_H
#  define NEED_newRV_noinc
#  define NEED_sv_2pv_flags
#  define NEED_my_snprintf
#  include "ppport.h"
#endif
#ifdef __cplusplus
}
#endif

/* OpenSSL-0.9.3a has some strange warning about this in
 *    openssl/des.h
 */
#undef _

/* Sigh: openssl 1.0 has
 typedef void *BLOCK;
which conflicts with perls
 typedef struct block BLOCK;
*/
#define BLOCK OPENSSL_BLOCK
#include <openssl/err.h>
#include <openssl/lhash.h>
#include <openssl/rand.h>
#include <openssl/buffer.h>
#include <openssl/ssl.h>
#include <openssl/pkcs12.h>
#ifndef OPENSSL_NO_COMP
#include <openssl/comp.h>    /* openssl-0.9.6a forgets to include this */
#endif
#ifndef OPENSSL_NO_MD2
#include <openssl/md2.h>
#endif
#ifndef OPENSSL_NO_MD4
#include <openssl/md4.h>
#endif
#ifndef OPENSSL_NO_MD5
#include <openssl/md5.h>     /* openssl-SNAP-20020227 does not automatically include this */
#endif
#if OPENSSL_VERSION_NUMBER >= 0x00905000L
#include <openssl/ripemd.h>
#endif
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
/* requires 0.9.7+ */
#ifndef OPENSSL_NO_ENGINE
#include <openssl/engine.h>
#endif
#endif
#ifdef OPENSSL_FIPS
#include <openssl/fips.h>
#endif
#if OPENSSL_VERSION_NUMBER >= 0x10000000L
#include <openssl/ocsp.h>
#endif
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#include <openssl/provider.h>
#endif
#undef BLOCK

/* Beginning with OpenSSL 3.0.0-alpha17, SSL_CTX_get_options() and
 * related functions return uint64_t instead of long. For this reason
 * constant() in constant.c and Net::SSLeay must also be able to
 * return 64bit constants. However, this creates a problem with Perls
 * that have only 32 bit integers. The define below helps with
 * handling this API change.
 */
#if (OPENSSL_VERSION_NUMBER < 0x30000000L) || defined(NET_SSLEAY_32BIT_INT_PERL)
#define NET_SSLEAY_32BIT_CONSTANTS
#endif

/* Debugging output - to enable use:
 *
 * perl Makefile.PL DEFINE=-DSHOW_XS_DEBUG
 * make
 *
 */

#ifdef SHOW_XS_DEBUG
#define PR1(s) fprintf(stderr,s);
#define PR2(s,t) fprintf(stderr,s,t);
#define PR3(s,t,u) fprintf(stderr,s,t,u);
#define PR4(s,t,u,v) fprintf(stderr,s,t,u,v);
#else
#define PR1(s)
#define PR2(s,t)
#define PR3(s,t,u)
#define PR4(s,t,u,v)
#endif

static void TRACE(int level,char *msg,...) {
    va_list args;
    SV *trace = get_sv("Net::SSLeay::trace",0);
    if (trace && SvIOK(trace) && SvIV(trace)>=level) {
	char buf[4096];
	va_start(args,msg);
	vsnprintf(buf,4095,msg,args);
	warn("%s",buf);
	va_end(args);
    }
}

#include "constants.c"

/* ============= thread-safety related stuff ============== */

#define MY_CXT_KEY "Net::SSLeay::_guts" XS_VERSION

typedef struct {
    HV* global_cb_data;
    UV tid;
} my_cxt_t;
START_MY_CXT

#ifdef USE_ITHREADS
static perl_mutex LIB_init_mutex;
#if OPENSSL_VERSION_NUMBER < 0x10100000L
static perl_mutex *GLOBAL_openssl_mutex = NULL;
#endif
#endif
static int LIB_initialized;

UV get_my_thread_id(void) /* returns threads->tid() value */
{
    dSP;
    UV tid = 0;
#ifdef USE_ITHREADS
    int count = 0;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("threads", 0)));
    PUTBACK;
    count = call_method("tid", G_SCALAR|G_EVAL);
    SPAGAIN;
    /* Caution: recent perls do not appear support threads->tid() */
    if (SvTRUE(ERRSV) || count != 1)
    {
      /* if compatible threads not loaded or an error occurs return 0 */
      tid = 0;
    }
    else
      tid = (UV)POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
#endif

    return tid;
}

/* IMPORTANT NOTE:
 * openssl locking was implemented according to http://www.openssl.org/docs/crypto/threads.html
 * we implement both static and dynamic locking as described on URL above
 * locking is supported when OPENSSL_THREADS macro is defined which means openssl-0.9.7 or newer
 * we intentionally do not implement cleanup of openssl's threading as it causes troubles
 * with apache-mpm-worker+mod_perl+mod_ssl+net-ssleay
 */
#if defined(USE_ITHREADS) && defined(OPENSSL_THREADS)


#if OPENSSL_VERSION_NUMBER < 0x10100000L
static void openssl_locking_function(int mode, int type, const char *file, int line)
{
    PR3("openssl_locking_function %d %d\n", mode, type);

    if (!GLOBAL_openssl_mutex) return;
    if (mode & CRYPTO_LOCK)
      MUTEX_LOCK(&GLOBAL_openssl_mutex[type]);
    else
      MUTEX_UNLOCK(&GLOBAL_openssl_mutex[type]);
}

#if OPENSSL_VERSION_NUMBER < 0x10000000L
static unsigned long openssl_threadid_func(void)
{
    dMY_CXT;
    return (unsigned long)(MY_CXT.tid);
}
#else
void openssl_threadid_func(CRYPTO_THREADID *id)
{
    dMY_CXT;
    CRYPTO_THREADID_set_numeric(id, (unsigned long)(MY_CXT.tid));
}
#endif

struct CRYPTO_dynlock_value
{
    perl_mutex mutex;
};

struct CRYPTO_dynlock_value * openssl_dynlocking_create_function (const char *file, int line)
{
    struct CRYPTO_dynlock_value *retval;
    New(0, retval, 1, struct CRYPTO_dynlock_value);
    if (!retval) return NULL;
    MUTEX_INIT(&retval->mutex);
    return retval;
}

void openssl_dynlocking_lock_function (int mode, struct CRYPTO_dynlock_value *l, const char *file, int line)
{
    if (!l) return;
    if (mode & CRYPTO_LOCK)
      MUTEX_LOCK(&l->mutex);
    else
      MUTEX_UNLOCK(&l->mutex);
}

void openssl_dynlocking_destroy_function (struct CRYPTO_dynlock_value *l, const char *file, int line)
{
    if (!l) return;
    MUTEX_DESTROY(&l->mutex);
    Safefree(l);
}
#endif

void openssl_threads_init(void)
{
    int i;

    PR1("STARTED: openssl_threads_init\n");

#if OPENSSL_VERSION_NUMBER < 0x10100000L
    /* initialize static locking */
    if ( !CRYPTO_get_locking_callback() ) {
#if OPENSSL_VERSION_NUMBER < 0x10000000L
        if ( !CRYPTO_get_id_callback() ) {
#else
        if ( !CRYPTO_THREADID_get_callback() ) {
#endif
            PR2("openssl_threads_init static locking %d\n", CRYPTO_num_locks());
            New(0, GLOBAL_openssl_mutex, CRYPTO_num_locks(), perl_mutex);
            if (!GLOBAL_openssl_mutex) return;
            for (i=0; i<CRYPTO_num_locks(); i++) MUTEX_INIT(&GLOBAL_openssl_mutex[i]);
            CRYPTO_set_locking_callback((void (*)(int,int,const char *,int))openssl_locking_function);

#ifndef WIN32
            /* no need for threadid_func() on Win32 */
#if OPENSSL_VERSION_NUMBER < 0x10000000L
            CRYPTO_set_id_callback(openssl_threadid_func);
#else
            CRYPTO_THREADID_set_callback(openssl_threadid_func);
#endif
#endif
        }
    }

    /* initialize dynamic locking */
    if ( !CRYPTO_get_dynlock_create_callback() &&
         !CRYPTO_get_dynlock_lock_callback() &&
         !CRYPTO_get_dynlock_destroy_callback() ) {
        PR1("openssl_threads_init dynamic locking\n");
        CRYPTO_set_dynlock_create_callback(openssl_dynlocking_create_function);
        CRYPTO_set_dynlock_lock_callback(openssl_dynlocking_lock_function);
        CRYPTO_set_dynlock_destroy_callback(openssl_dynlocking_destroy_function);
    }
#endif 
}

#endif

/* ============= typedefs to agument TYPEMAP ============== */

typedef void callback_no_ret(void);
typedef RSA * cb_ssl_int_int_ret_RSA(SSL * ssl,int is_export, int keylength);
typedef DH * cb_ssl_int_int_ret_DH(SSL * ssl,int is_export, int keylength);

typedef STACK_OF(X509_NAME) X509_NAME_STACK;

typedef int perl_filehandle_t;

/* ======= special handler used by EVP_MD_do_all_sorted ======= */

#if OPENSSL_VERSION_NUMBER >= 0x1000000fL
static void handler_list_md_fn(const EVP_MD *m, const char *from, const char *to, void *arg)
{
  /* taken from apps/dgst.c */
  const char *mname;
  if (!m) return;                                           /* Skip aliases */
  mname = OBJ_nid2ln(EVP_MD_type(m));
  if (strcmp(from, mname)) return;                          /* Skip shortnames */
#if OPENSSL_VERSION_NUMBER < 0x10100000L
  if (EVP_MD_flags(m) & EVP_MD_FLAG_PKEY_DIGEST) return;    /* Skip clones */
#endif
  if (strchr(mname, ' ')) mname= EVP_MD_name(m);
  av_push(arg, newSVpv(mname,0));
}
#endif

/* ============= callbacks - basic info =============
 *
 * PLEASE READ THIS BEFORE YOU ADD ANY NEW CALLBACK!!
 *
 * There are basically 2 types of callbacks used in SSLeay:
 *
 * 1/ "one-time" callbacks - these are created+used+destroyed within one perl function implemented in XS.
 *    These callbacks use a special C structure simple_cb_data_t to pass necessary data.
 *    There are 2 related helper functions: simple_cb_data_new() + simple_cb_data_free()
 *    For example see implementation of these functions:
 *    - RSA_generate_key
 *    - PEM_read_bio_PrivateKey
 *
 * 2/ "advanced" callbacks - these are setup/destroyed by one function but used by another function. These
 *    callbacks use global hash MY_CXT.global_cb_data to store perl functions + data to be uset at callback time.
 *    There are 2 related helper functions: cb_data_advanced_put() + cb_data_advanced_get() for manipulating
 *    global hash MY_CXT.global_cb_data which work like this:
 *        cb_data_advanced_put(<pointer>, "data_name", dataSV)
 *        >>>
 *        global_cb_data->{"ptr_<pointer>"}->{"data_name"} = dataSV)
 *    or
 *        data = cb_data_advanced_get(<pointer>, "data_name")
 *        >>>
 *        my $data = global_cb_data->{"ptr_<pointer>"}->{"data_name"}
 *    For example see implementation of these functions:
 *    - SSL_CTX_set_verify
 *    - SSL_set_verify
 *    - SSL_CTX_set_cert_verify_callback
 *    - SSL_CTX_set_default_passwd_cb
 *    - SSL_CTX_set_default_passwd_cb_userdata
 *    - SSL_set_session_secret_cb
 *
 * If you want to add a new callback:
 * - you very likely need a new function "your_callback_name_invoke()"
 * - decide whether your case fits case 1/ or 2/ (and implement likewise existing functions)
 * - try to avoid adding a new style of callback implementation (or ask Net::SSLeay maintainers before)
 *
 */

/* ============= callback stuff - generic functions============== */

struct _ssleay_cb_t {
    SV* func;
    SV* data;
};
typedef struct _ssleay_cb_t simple_cb_data_t;

simple_cb_data_t* simple_cb_data_new(SV* func, SV* data)
{
    simple_cb_data_t* cb;
    New(0, cb, 1, simple_cb_data_t);
    if (cb) {
        SvREFCNT_inc(func);
        SvREFCNT_inc(data);
        cb->func = func;
        cb->data = (data == &PL_sv_undef) ? NULL : data;
    }
    return cb;
}

void simple_cb_data_free(simple_cb_data_t* cb)
{
    if (cb) {
        if (cb->func) {
            SvREFCNT_dec(cb->func);
            cb->func = NULL;
        }
        if (cb->data) {
            SvREFCNT_dec(cb->data);
            cb->data = NULL;
        }
    }
    Safefree(cb);
}

int cb_data_advanced_put(const void *ptr, const char* data_name, SV* data)
{
    HV * L2HV;
    SV ** svtmp;
    int len;
    char key_name[500];
    dMY_CXT;

    len = my_snprintf(key_name, sizeof(key_name), "ptr_%p", ptr);
    if (len == sizeof(key_name)) return 0; /* error  - key_name too short*/

    /* get or create level-2 hash */
    svtmp = hv_fetch(MY_CXT.global_cb_data, key_name, strlen(key_name), 0);
    if (svtmp == NULL) {
        L2HV = newHV();
        hv_store(MY_CXT.global_cb_data, key_name, strlen(key_name), newRV_noinc((SV*)L2HV), 0);
    }
    else {
        if (!SvOK(*svtmp) || !SvROK(*svtmp)) return 0;
#if defined(MUTABLE_PTR)
        L2HV = (HV*)MUTABLE_PTR(SvRV(*svtmp));
#else
        L2HV = (HV*)(SvRV(*svtmp));
#endif
    }

    /* first delete already stored value */
    hv_delete(L2HV, data_name, strlen(data_name), G_DISCARD);
    if (data!=NULL) {
        if (SvOK(data))
            hv_store(L2HV, data_name, strlen(data_name), data, 0);
        else
            /* we're not storing data so discard it */
            SvREFCNT_dec(data);
    }

    return 1;
}

SV* cb_data_advanced_get(const void *ptr, const char* data_name)
{
    HV * L2HV;
    SV ** svtmp;
    int len;
    char key_name[500];
    dMY_CXT;

    len = my_snprintf(key_name, sizeof(key_name), "ptr_%p", ptr);
    if (len == sizeof(key_name)) return &PL_sv_undef; /* return undef on error - key_name too short*/

    /* get level-2 hash */
    svtmp = hv_fetch(MY_CXT.global_cb_data, key_name, strlen(key_name), 0);
    if (svtmp == NULL)  return &PL_sv_undef;
    if (!SvOK(*svtmp))  return &PL_sv_undef;
    if (!SvROK(*svtmp)) return &PL_sv_undef;
#if defined(MUTABLE_PTR)
    L2HV = (HV*)MUTABLE_PTR(SvRV(*svtmp));
#else
    L2HV = (HV*)(SvRV(*svtmp));
#endif

    /* get stored data */
    svtmp = hv_fetch(L2HV, data_name, strlen(data_name), 0);
    if (svtmp == NULL) return &PL_sv_undef;
    if (!SvOK(*svtmp)) return &PL_sv_undef;

    return *svtmp;
}

int cb_data_advanced_drop(const void *ptr)
{
    int len;
    char key_name[500];
    dMY_CXT;

    len = my_snprintf(key_name, sizeof(key_name), "ptr_%p", ptr);
    if (len == sizeof(key_name)) return 0; /* error  - key_name too short*/

    hv_delete(MY_CXT.global_cb_data, key_name, strlen(key_name), G_DISCARD);
    return 1;
}

/* ============= callback stuff - invoke functions ============== */

static int ssleay_verify_callback_invoke (int ok, X509_STORE_CTX* x509_store)
{
    dSP;
    SSL* ssl;
    int count = -1, res;
    SV *cb_func;

    PR1("STARTED: ssleay_verify_callback_invoke\n");
    ssl = X509_STORE_CTX_get_ex_data(x509_store, SSL_get_ex_data_X509_STORE_CTX_idx());
    cb_func = cb_data_advanced_get(ssl, "ssleay_verify_callback!!func");
    
    if (!SvOK(cb_func)) {
        SSL_CTX* ssl_ctx = SSL_get_SSL_CTX(ssl);
        cb_func = cb_data_advanced_get(ssl_ctx, "ssleay_verify_callback!!func");
     }
 
    if (!SvOK(cb_func))
        croak("Net::SSLeay: verify_callback called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PR2("verify callback glue ok=%d\n", ok);

    PUSHMARK(sp);
    EXTEND( sp, 2 );
    PUSHs( sv_2mortal(newSViv(ok)) );
    PUSHs( sv_2mortal(newSViv(PTR2IV(x509_store))) );
    PUTBACK;

    PR1("About to call verify callback.\n");
    count = call_sv(cb_func, G_SCALAR);
    PR1("Returned from verify callback.\n");

    SPAGAIN;

    if (count != 1)
        croak ( "Net::SSLeay: verify_callback perl function did not return a scalar.\n");

    res = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

static int ssleay_ctx_passwd_cb_invoke(char *buf, int size, int rwflag, void *userdata)
{
    dSP;
    int count = -1;
    char *res;
    SV *cb_func, *cb_data;

    PR1("STARTED: ssleay_ctx_passwd_cb_invoke\n");
    cb_func = cb_data_advanced_get(userdata, "ssleay_ctx_passwd_cb!!func");
    cb_data = cb_data_advanced_get(userdata, "ssleay_ctx_passwd_cb!!data");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ctx_passwd_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(rwflag)));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    count = call_sv( cb_func, G_SCALAR );

    SPAGAIN;

    if (count != 1)
        croak("Net::SSLeay: ssleay_ctx_passwd_cb_invoke perl function did not return a scalar.\n");

    res = POPp;

    if (res == NULL) {
        *buf = '\0';
    } else {
        strncpy(buf, res, size);
        buf[size - 1] = '\0';
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return strlen(buf);
}

#if OPENSSL_VERSION_NUMBER >= 0x1010006fL /* In OpenSSL 1.1.0 but actually called for $ssl from 1.1.0f */
#ifndef LIBRESSL_VERSION_NUMBER
#ifndef OPENSSL_IS_BORINGSSL
static int ssleay_ssl_passwd_cb_invoke(char *buf, int size, int rwflag, void *userdata)
{
    dSP;
    int count = -1;
    char *res;
    SV *cb_func, *cb_data;

    PR1("STARTED: ssleay_ssl_passwd_cb_invoke\n");
    cb_func = cb_data_advanced_get(userdata, "ssleay_ssl_passwd_cb!!func");
    cb_data = cb_data_advanced_get(userdata, "ssleay_ssl_passwd_cb!!data");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ssl_passwd_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(rwflag)));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    count = call_sv( cb_func, G_SCALAR );

    SPAGAIN;

    if (count != 1)
        croak("Net::SSLeay: ssleay_ssl_passwd_cb_invoke perl function did not return a scalar.\n");

    res = POPp;

    if (res == NULL) {
        *buf = '\0';
    } else {
        strncpy(buf, res, size);
        buf[size - 1] = '\0';
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return strlen(buf);
}
#endif /* !BoringSSL */
#endif /* !LibreSSL */
#endif /* >= 1.1.0f */

int ssleay_ctx_cert_verify_cb_invoke(X509_STORE_CTX* x509_store_ctx, void* data)
{
    dSP;
    int count = -1;
    int res;
    SV * cb_func, *cb_data;
    void *ptr;
    SSL *ssl;

    PR1("STARTED: ssleay_ctx_cert_verify_cb_invoke\n");
#if OPENSSL_VERSION_NUMBER < 0x0090700fL
    ssl = X509_STORE_CTX_get_ex_data(x509_store_ctx, SSL_get_ex_data_X509_STORE_CTX_idx());
    ptr = (void*) SSL_get_SSL_CTX(ssl);
#else
    ssl = NULL;
    ptr = (void*) data;
#endif

    cb_func = cb_data_advanced_get(ptr, "ssleay_ctx_cert_verify_cb!!func");
    cb_data = cb_data_advanced_get(ptr, "ssleay_ctx_cert_verify_cb!!data");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ctx_cert_verify_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(x509_store_ctx))));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    count = call_sv(cb_func, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Net::SSLeay: ssleay_ctx_cert_verify_cb_invoke perl function did not return a scalar.\n");

    res = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)

int tlsext_servername_callback_invoke(SSL *ssl, int *ad, void *arg)
{
    dSP;
    int count = -1;
    int res;
    SV * cb_func, *cb_data;

    PR1("STARTED: tlsext_servername_callback_invoke\n");

    cb_func = cb_data_advanced_get(arg, "tlsext_servername_callback!!func");
    cb_data = cb_data_advanced_get(arg, "tlsext_servername_callback!!data");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: tlsext_servername_callback_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    count = call_sv(cb_func, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Net::SSLeay: tlsext_servername_callback_invoke perl function did not return a scalar.\n");

    res = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10000000L && !defined(OPENSSL_NO_TLSEXT)

int tlsext_status_cb_invoke(SSL *ssl, void *arg)
{
    dSP;
    SV *cb_func, *cb_data;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);
    int len,res,nres = -1;
    const unsigned char *p = NULL;
    OCSP_RESPONSE *ocsp_response = NULL;

    cb_func = cb_data_advanced_get(ctx, "tlsext_status_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "tlsext_status_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
	croak ("Net::SSLeay: tlsext_status_cb_invoke called, but not set to point to any perl function.\n");

    len = SSL_get_tlsext_status_ocsp_resp(ssl, &p);
    if (p) ocsp_response = d2i_OCSP_RESPONSE(NULL, &p, len);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    PUSHs( sv_2mortal(newSViv(PTR2IV(ocsp_response))) );
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    nres = call_sv(cb_func, G_SCALAR);
    if (ocsp_response) OCSP_RESPONSE_free(ocsp_response);

    SPAGAIN;

    if (nres != 1)
	croak("Net::SSLeay: tlsext_status_cb_invoke perl function did not return a scalar.\n");

    res = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

int session_ticket_ext_cb_invoke(SSL *ssl, const unsigned char *data, int len, void *arg)
{
    dSP;
    SV *cb_func, *cb_data;
    int res,nres = -1;

    cb_func = cb_data_advanced_get(arg, "session_ticket_ext_cb!!func");
    cb_data = cb_data_advanced_get(arg, "session_ticket_ext_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
	croak ("Net::SSLeay: session_ticket_ext_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSVpvn((const char *)data, len)));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    nres = call_sv(cb_func, G_SCALAR);

    SPAGAIN;

    if (nres != 1)
	croak("Net::SSLeay: session_ticket_ext_cb_invoke perl function did not return a scalar.\n");

    res = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

#endif

#if defined(SSL_F_SSL_SET_HELLO_EXTENSION) || defined(SSL_F_SSL_SET_SESSION_TICKET_EXT)

int ssleay_session_secret_cb_invoke(SSL* s, void* secret, int *secret_len,
                                    STACK_OF(SSL_CIPHER) *peer_ciphers,
                                    const SSL_CIPHER **cipher, void *arg)
{
    dSP;
    int count = -1, res, i;
    AV *ciphers = newAV();
    SV *pref_cipher = sv_newmortal();
    SV * cb_func, *cb_data;
    SV * secretsv;

    PR1("STARTED: ssleay_session_secret_cb_invoke\n");
    cb_func = cb_data_advanced_get(arg, "ssleay_session_secret_cb!!func");
    cb_data = cb_data_advanced_get(arg, "ssleay_session_secret_cb!!data");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ctx_passwd_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    secretsv = sv_2mortal( newSVpv(secret, *secret_len));
    XPUSHs(secretsv);
    for (i=0; i<sk_SSL_CIPHER_num(peer_ciphers); i++) {
        const SSL_CIPHER *c = sk_SSL_CIPHER_value(peer_ciphers,i);
        av_store(ciphers, i, sv_2mortal(newSVpv(SSL_CIPHER_get_name(c), 0)));
    }
    XPUSHs(sv_2mortal(newRV_inc((SV*)ciphers)));
    XPUSHs(sv_2mortal(newRV_inc(pref_cipher)));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));

    PUTBACK;

    count = call_sv( cb_func, G_SCALAR );

    SPAGAIN;

    if (count != 1)
        croak ("Net::SSLeay: ssleay_session_secret_cb_invoke perl function did not return a scalar.\n");

    res = POPi;
    if (res) {
        /* See if there is a preferred cipher selected, if so it is an index into the stack */
        if (SvIOK(pref_cipher))
            *cipher = sk_SSL_CIPHER_value(peer_ciphers, SvIV(pref_cipher));

#if OPENSSL_VERSION_NUMBER >= 0x10100000L
	{
	    /* Use any new master secret set by the callback function in secret */
	    STRLEN newsecretlen;
	    char* newsecretdata = SvPV(secretsv, newsecretlen);
	    memcpy(secret, newsecretdata, newsecretlen);
	}
#endif
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10000000L && !defined(OPENSSL_NO_PSK)
#define NET_SSLEAY_CAN_PSK_CLIENT_CALLBACK

unsigned int ssleay_set_psk_client_callback_invoke(SSL *ssl, const char *hint,
                                                   char *identity, unsigned int max_identity_len,
                                                   unsigned char *psk, unsigned int max_psk_len)
{
    dSP;
    int count = -1;
    char *identity_val, *psk_val;
    unsigned int psk_len = 0;
    BIGNUM *psk_bn = NULL;
    SV * cb_func;
    SV * hintsv;
    /* this n_a is required for building with old perls: */
    STRLEN n_a;

    PR1("STARTED: ssleay_set_psk_client_callback_invoke\n");
    cb_func = cb_data_advanced_get(ssl, "ssleay_set_psk_client_callback!!func");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_set_psk_client_callback_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    if (hint != NULL) {
      hintsv = sv_2mortal( newSVpv(hint, strlen(hint)));
      XPUSHs(hintsv);
    }

    PUTBACK;

    count = call_sv( cb_func, G_ARRAY );

    SPAGAIN;

    if (count != 2)
        croak ("Net::SSLeay: ssleay_set_psk_client_callback_invoke perl function did not return 2 values.\n");

    psk_val = POPpx;
    identity_val = POPpx;

    my_snprintf(identity, max_identity_len, "%s", identity_val);

    if (BN_hex2bn(&psk_bn, psk_val) > 0) {
        if (BN_num_bytes(psk_bn) <= max_psk_len) {
            psk_len = BN_bn2bin(psk_bn, psk);
        }
        BN_free(psk_bn);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return psk_len;
}

unsigned int ssleay_ctx_set_psk_client_callback_invoke(SSL *ssl, const char *hint,
                                                       char *identity, unsigned int max_identity_len,
                                                       unsigned char *psk, unsigned int max_psk_len)
{
    dSP;
    SSL_CTX *ctx;
    int count = -1;
    char *identity_val, *psk_val;
    unsigned int psk_len = 0;
    BIGNUM *psk_bn = NULL;
    SV * cb_func;
    SV * hintsv;
    /* this n_a is required for building with old perls: */
    STRLEN n_a;

    ctx = SSL_get_SSL_CTX(ssl);

    PR1("STARTED: ssleay_ctx_set_psk_client_callback_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "ssleay_ctx_set_psk_client_callback!!func");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ctx_set_psk_client_callback_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    if (hint != NULL) {
      hintsv = sv_2mortal( newSVpv(hint, strlen(hint)));
      XPUSHs(hintsv);
    }

    PUTBACK;

    count = call_sv( cb_func, G_ARRAY );

    SPAGAIN;

    if (count != 2)
        croak ("Net::SSLeay: ssleay_ctx_set_psk_client_callback_invoke perl function did not return 2 values.\n");

    psk_val = POPpx;
    identity_val = POPpx;

    my_snprintf(identity, max_identity_len, "%s", identity_val);

    if (BN_hex2bn(&psk_bn, psk_val) > 0) {
        if (BN_num_bytes(psk_bn) <= max_psk_len) {
            psk_len = BN_bn2bin(psk_bn, psk);
        }
        BN_free(psk_bn);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return psk_len;
}

#endif

#if (OPENSSL_VERSION_NUMBER >= 0x10001000L && !defined(OPENSSL_NO_NEXTPROTONEG)) || (OPENSSL_VERSION_NUMBER >= 0x10002000L && !defined(OPENSSL_NO_TLSEXT))

int next_proto_helper_AV2protodata(AV * list, unsigned char *out)
{
    int i, last_index, ptr = 0;
    last_index = av_len(list);
    if (last_index<0) return 0;
    for(i=0; i<=last_index; i++) {
        char *p = SvPV_nolen(*av_fetch(list, i, 0));
        size_t len = strlen(p);
        if (len>255) return 0;
        if (out) {
            /* if out == NULL we only calculate the length of output */
            out[ptr] = (unsigned char)len;
            strncpy((char*)out+ptr+1, p, len);
        }
        ptr += strlen(p) + 1;
    }
    return ptr;
}

int next_proto_helper_protodata2AV(AV * list, const unsigned char *in, unsigned int inlen)
{
    unsigned int i = 0;
    unsigned char il;
    if (!list || inlen<2) return 0;   
    while (i<inlen) {
        il = in[i++];
        if (i+il > inlen) return 0;
        av_push(list, newSVpv((const char*)in+i, il));
        i += il;
    }
    return 1;
}

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10001000L && !defined(OPENSSL_NO_NEXTPROTONEG) && !defined(LIBRESSL_VERSION_NUMBER)

int next_proto_select_cb_invoke(SSL *ssl, unsigned char **out, unsigned char *outlen,
                                const unsigned char *in, unsigned int inlen, void *arg)
{
    SV *cb_func, *cb_data;
    unsigned char *next_proto_data;
    size_t next_proto_len;
    int next_proto_status;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);
    /* this n_a is required for building with old perls: */
    STRLEN n_a;

    PR1("STARTED: next_proto_select_cb_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "next_proto_select_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "next_proto_select_cb!!data");
    /* clear last_status value = store undef */
    cb_data_advanced_put(ssl, "next_proto_select_cb!!last_status", NULL);
    cb_data_advanced_put(ssl, "next_proto_select_cb!!last_negotiated", NULL);

    if (SvROK(cb_func) && (SvTYPE(SvRV(cb_func)) == SVt_PVCV)) {
        int count = -1;
        AV *list = newAV();
        SV *tmpsv;
        dSP;
        
        if (!next_proto_helper_protodata2AV(list, in, inlen)) return SSL_TLSEXT_ERR_ALERT_FATAL;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
        XPUSHs(sv_2mortal(newRV_inc((SV*)list)));
        XPUSHs(sv_2mortal(newSVsv(cb_data)));
        PUTBACK;
        count = call_sv( cb_func, G_ARRAY );
        SPAGAIN;
        if (count != 2)
            croak ("Net::SSLeay: next_proto_select_cb_invoke perl function did not return 2 values.\n");
        next_proto_data = (unsigned char*)POPpx;
        next_proto_status = POPi;

        next_proto_len = strlen((const char*)next_proto_data);
        if (next_proto_len<=255) {
          /* store last_status + last_negotiated into global hash */
          cb_data_advanced_put(ssl, "next_proto_select_cb!!last_status", newSViv(next_proto_status));
          tmpsv = newSVpv((const char*)next_proto_data, next_proto_len);
          cb_data_advanced_put(ssl, "next_proto_select_cb!!last_negotiated", tmpsv);
          *out = (unsigned char *)SvPVX(tmpsv);
          *outlen = next_proto_len;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return next_proto_len>255 ? SSL_TLSEXT_ERR_ALERT_FATAL : SSL_TLSEXT_ERR_OK;
    }
    else if (SvROK(cb_data) && (SvTYPE(SvRV(cb_data)) == SVt_PVAV)) {
        next_proto_len = next_proto_helper_AV2protodata((AV*)SvRV(cb_data), NULL);
        Newx(next_proto_data, next_proto_len, unsigned char);
        if (!next_proto_data) return SSL_TLSEXT_ERR_ALERT_FATAL;
        next_proto_len = next_proto_helper_AV2protodata((AV*)SvRV(cb_data), next_proto_data);

        next_proto_status = SSL_select_next_proto(out, outlen, in, inlen, next_proto_data, next_proto_len);
        Safefree(next_proto_data);
        if (next_proto_status != OPENSSL_NPN_NEGOTIATED) {
            *outlen = *in;
            *out = (unsigned char *)in+1;
        }

        /* store last_status + last_negotiated into global hash */
        cb_data_advanced_put(ssl, "next_proto_select_cb!!last_status", newSViv(next_proto_status));
        cb_data_advanced_put(ssl, "next_proto_select_cb!!last_negotiated", newSVpv((const char*)*out, *outlen));
        return SSL_TLSEXT_ERR_OK;
    }
    return SSL_TLSEXT_ERR_ALERT_FATAL;
}

int next_protos_advertised_cb_invoke(SSL *ssl, const unsigned char **out, unsigned int *outlen, void *arg_unused)
{
    SV *cb_func, *cb_data;
    unsigned char *protodata = NULL;
    unsigned short protodata_len = 0;
    SV *tmpsv;
    AV *tmpav;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    PR1("STARTED: next_protos_advertised_cb_invoke");
    cb_func = cb_data_advanced_get(ctx, "next_protos_advertised_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "next_protos_advertised_cb!!data");

    if (SvROK(cb_func) && (SvTYPE(SvRV(cb_func)) == SVt_PVCV)) {
        int count = -1;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
        XPUSHs(sv_2mortal(newSVsv(cb_data)));
        PUTBACK;
        count = call_sv( cb_func, G_SCALAR );
        SPAGAIN;
        if (count != 1)
            croak ("Net::SSLeay: next_protos_advertised_cb_invoke perl function did not return scalar value.\n");
        tmpsv = POPs;
        if (SvOK(tmpsv) && SvROK(tmpsv) && (SvTYPE(SvRV(tmpsv)) == SVt_PVAV)) {
            tmpav = (AV*)SvRV(tmpsv);
            protodata_len = next_proto_helper_AV2protodata(tmpav, NULL);
            Newx(protodata, protodata_len, unsigned char);
            if (protodata) next_proto_helper_AV2protodata(tmpav, protodata);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    else if (SvROK(cb_data) && (SvTYPE(SvRV(cb_data)) == SVt_PVAV)) {
        tmpav = (AV*)SvRV(cb_data);
        protodata_len = next_proto_helper_AV2protodata(tmpav, NULL);
        Newx(protodata, protodata_len, unsigned char);
        if (protodata) next_proto_helper_AV2protodata(tmpav, protodata);
    }    
    if (protodata) {
        tmpsv = newSVpv((const char*)protodata, protodata_len);
        Safefree(protodata);
        cb_data_advanced_put(ssl, "next_protos_advertised_cb!!last_advertised", tmpsv);
        *out = (unsigned char *)SvPVX(tmpsv);
        *outlen = protodata_len;
        return SSL_TLSEXT_ERR_OK;
    }
    return SSL_TLSEXT_ERR_ALERT_FATAL;
}

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10002000L && !defined(OPENSSL_NO_TLSEXT)

int alpn_select_cb_invoke(SSL *ssl, const unsigned char **out, unsigned char *outlen,
                                const unsigned char *in, unsigned int inlen, void *arg)
{
    SV *cb_func, *cb_data;
    unsigned char *alpn_data;
    size_t alpn_len;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    PR1("STARTED: alpn_select_cb_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "alpn_select_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "alpn_select_cb!!data");

    if (SvROK(cb_func) && (SvTYPE(SvRV(cb_func)) == SVt_PVCV)) {
        int count = -1;
        AV *list = newAV();
        SV *tmpsv;
        SV *alpn_data_sv;
        dSP;

        if (!next_proto_helper_protodata2AV(list, in, inlen)) return SSL_TLSEXT_ERR_ALERT_FATAL;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
        XPUSHs(sv_2mortal(newRV_inc((SV*)list)));
        XPUSHs(sv_2mortal(newSVsv(cb_data)));
        PUTBACK;
        count = call_sv( cb_func, G_ARRAY );
        SPAGAIN;
        if (count != 1)
            croak ("Net::SSLeay: alpn_select_cb perl function did not return exactly 1 value.\n");
        alpn_data_sv = POPs;
        if (SvOK(alpn_data_sv)) {
          alpn_data = (unsigned char*)SvPV_nolen(alpn_data_sv);
          alpn_len = strlen((const char*)alpn_data);
          if (alpn_len <= 255) {
            tmpsv = newSVpv((const char*)alpn_data, alpn_len);
            *out = (unsigned char *)SvPVX(tmpsv);
            *outlen = alpn_len;
          }
        } else {
          alpn_data = NULL;
          alpn_len = 0;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;

        if (alpn_len>255) return SSL_TLSEXT_ERR_ALERT_FATAL;
        return alpn_data ? SSL_TLSEXT_ERR_OK : SSL_TLSEXT_ERR_NOACK;
    }
    else if (SvROK(cb_data) && (SvTYPE(SvRV(cb_data)) == SVt_PVAV)) {
        int status;

        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(cb_data), NULL);
        Newx(alpn_data, alpn_len, unsigned char);
        if (!alpn_data) return SSL_TLSEXT_ERR_ALERT_FATAL;
        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(cb_data), alpn_data);

        /* This is the same function that is used for NPN. */
        status = SSL_select_next_proto((unsigned char **)out, outlen, in, inlen, alpn_data, alpn_len);
        Safefree(alpn_data);
        if (status != OPENSSL_NPN_NEGOTIATED) {
            *outlen = *in;
            *out = in+1;
        }
        return status == OPENSSL_NPN_NEGOTIATED ? SSL_TLSEXT_ERR_OK : SSL_TLSEXT_ERR_NOACK;
    }
    return SSL_TLSEXT_ERR_ALERT_FATAL;
}

#endif

int pem_password_cb_invoke(char *buf, int bufsize, int rwflag, void *data) {
    dSP;
    char *str;
    int count = -1;
    size_t str_len = 0;
    simple_cb_data_t* cb = (simple_cb_data_t*)data;
    /* this n_a is required for building with old perls: */
    STRLEN n_a;

    PR1("STARTED: pem_password_cb_invoke\n");
    if (cb->func && SvOK(cb->func)) {
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);

        XPUSHs(sv_2mortal( newSViv(bufsize-1) ));
        XPUSHs(sv_2mortal( newSViv(rwflag) ));
        if (cb->data) XPUSHs( cb->data );

        PUTBACK;

        count = call_sv( cb->func, G_SCALAR );

        SPAGAIN;

        buf[0] = 0; /* start with an empty password */
        if (count != 1) {
            croak("Net::SSLeay: pem_password_cb_invoke perl function did not return a scalar.\n");
        }
        else {
            str = POPpx;
            str_len = strlen(str);
            if (str_len+1 < bufsize) {
                strcpy(buf, str);
            }
            else {
                str_len = 0;
                warn("Net::SSLeay: pem_password_cb_invoke password too long\n");
            }
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return str_len;
}

void ssleay_RSA_generate_key_cb_invoke(int i, int n, void* data)
{
    dSP;
    int count = -1;
    simple_cb_data_t* cb = (simple_cb_data_t*)data;

    /* PR1("STARTED: ssleay_RSA_generate_key_cb_invoke\n"); / * too noisy */
    if (cb->func && SvOK(cb->func)) {
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);

        XPUSHs(sv_2mortal( newSViv(i) ));
        XPUSHs(sv_2mortal( newSViv(n) ));
        if (cb->data) XPUSHs( cb->data );

        PUTBACK;

        count = call_sv( cb->func, G_VOID|G_DISCARD );

        if (count != 0)
            croak ("Net::SSLeay: ssleay_RSA_generate_key_cb_invoke "
                   "perl function did return something in void context.\n");

        SPAGAIN;
        FREETMPS;
        LEAVE;
    }
}

void ssleay_info_cb_invoke(const SSL *ssl, int where, int ret)
{
    dSP;
    SV *cb_func, *cb_data;

    cb_func = cb_data_advanced_get((void*)ssl, "ssleay_info_cb!!func");
    cb_data = cb_data_advanced_get((void*)ssl, "ssleay_info_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
	croak ("Net::SSLeay: ssleay_info_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSViv(where)) );
    XPUSHs(sv_2mortal(newSViv(ret)) );
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void ssleay_ctx_info_cb_invoke(const SSL *ssl, int where, int ret)
{
    dSP;
    SV *cb_func, *cb_data;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    cb_func = cb_data_advanced_get(ctx, "ssleay_ctx_info_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "ssleay_ctx_info_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
	croak ("Net::SSLeay: ssleay_ctx_info_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSViv(where)) );
    XPUSHs(sv_2mortal(newSViv(ret)) );
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void ssleay_msg_cb_invoke(int write_p, int version, int content_type, const void *buf, size_t len, SSL *ssl, void *arg)
{
    dSP;
    SV *cb_func, *cb_data;

    cb_func = cb_data_advanced_get(ssl, "ssleay_msg_cb!!func");
    cb_data = cb_data_advanced_get(ssl, "ssleay_msg_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
    croak ("Net::SSLeay: ssleay_msg_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(write_p)));
    XPUSHs(sv_2mortal(newSViv(version)));
    XPUSHs(sv_2mortal(newSViv(content_type)));
    XPUSHs(sv_2mortal(newSVpv((const char*)buf, len)));
    XPUSHs(sv_2mortal(newSViv(len)));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void ssleay_ctx_msg_cb_invoke(int write_p, int version, int content_type, const void *buf, size_t len, SSL *ssl, void *arg)
{
    dSP;
    SV *cb_func, *cb_data;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    cb_func = cb_data_advanced_get(ctx, "ssleay_ctx_msg_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "ssleay_ctx_msg_cb!!data");

    if ( ! SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
    croak ("Net::SSLeay: ssleay_ctx_msg_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(write_p)));
    XPUSHs(sv_2mortal(newSViv(version)));
    XPUSHs(sv_2mortal(newSViv(content_type)));
    XPUSHs(sv_2mortal(newSVpv((const char*)buf, len)));
    XPUSHs(sv_2mortal(newSViv(len)));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSVsv(cb_data)));
    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}

/* 
 * Support for tlsext_ticket_key_cb_invoke was already in 0.9.8 but it was
 * broken in various ways during the various 1.0.0* versions.
 * Better enable it only starting with 1.0.1.
*/
#if defined(SSL_CTRL_SET_TLSEXT_TICKET_KEY_CB) && OPENSSL_VERSION_NUMBER >= 0x10001000L && !defined(OPENSSL_NO_TLSEXT)
#define NET_SSLEAY_CAN_TICKET_KEY_CB

int tlsext_ticket_key_cb_invoke(
    SSL *ssl,
    unsigned char *key_name,
    unsigned char *iv,
    EVP_CIPHER_CTX *ectx,
    HMAC_CTX *hctx,
    int enc
){

    dSP;
    int count,usable_rv_count,hmac_key_len = 0;
    SV *cb_func, *cb_data;
    STRLEN svlen;
    unsigned char key[48];  /* key[0..15] aes, key[16..32] or key[16..48] hmac */
    unsigned char name[16];
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    PR1("STARTED: tlsext_ticket_key_cb_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "tlsext_ticket_key_cb!!func");
    cb_data = cb_data_advanced_get(ctx, "tlsext_ticket_key_cb!!data");

    if (!SvROK(cb_func) || (SvTYPE(SvRV(cb_func)) != SVt_PVCV))
	croak("callback must be a code reference");

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSVsv(cb_data)));

    if (!enc) {
	/* call as getkey(data,this_name) -> (key,current_name) */
	XPUSHs(sv_2mortal(newSVpv((const char *)key_name,16)));
    } else {
	/* call as getkey(data) -> (key,current_name) */
    }

    PUTBACK;

    count = call_sv( cb_func, G_ARRAY );

    SPAGAIN;

    if (count>2)
	croak("too much return values - only (name,key) should be returned");

    usable_rv_count = 0;
    if (count>0) {
	SV *sname = POPs;
	if (SvOK(sname)) {
	    unsigned char *pname = (unsigned char *)SvPV(sname,svlen);
	    if (svlen > 16)
		croak("name must be at at most 16 bytes, got %d",(int)svlen);
	    if (svlen == 0)
		croak("name should not be empty");
	    OPENSSL_cleanse(name, 16);
	    memcpy(name,pname,svlen);
	    usable_rv_count++;
	}
    }
    if (count>1) {
	SV *skey = POPs;
	if (SvOK(skey)) {
	    unsigned char *pkey = (unsigned char *)SvPV(skey,svlen);
	    if (svlen != 32 && svlen != 48)
		croak("key must be 32 or 48 random bytes, got %d",(int)svlen);
	    hmac_key_len = (int)svlen - 16;
	    memcpy(key,pkey,(int)svlen);
	    usable_rv_count++;
	}
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if (!enc && usable_rv_count == 0) {
	TRACE(2,"no key returned for ticket");
	return 0;
    }
    if (usable_rv_count != 2)
	croak("key functions needs to return (key,name)");

    if (enc) {
	/* encrypt ticket information with given key */
	RAND_bytes(iv, 16);
	EVP_EncryptInit_ex(ectx, EVP_aes_128_cbc(), NULL, key, iv);
	HMAC_Init_ex(hctx,key+16,hmac_key_len,EVP_sha256(),NULL);
	memcpy(key_name,name,16);
	return 1;

    } else {
	HMAC_Init_ex(hctx,key+16,hmac_key_len,EVP_sha256(),NULL);
	EVP_DecryptInit_ex(ectx, EVP_aes_128_cbc(), NULL, key, iv);

	if (memcmp(name,key_name,16) == 0)
	    return 1;  /* current key was used */
	else 
	    return 2;  /* different key was used, need to be renewed */
    }
}

#endif

int ssleay_ssl_ctx_sess_new_cb_invoke(struct ssl_st *ssl, SSL_SESSION *sess)
{
    dSP;
    int count, remove;
    SSL_CTX *ctx;
    SV *cb_func;

    PR1("STARTED: ssleay_ssl_ctx_sess_new_cb_invoke\n");
    ctx = SSL_get_SSL_CTX(ssl);
    cb_func = cb_data_advanced_get(ctx, "ssleay_ssl_ctx_sess_new_cb!!func");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ssl_ctx_sess_new_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(sess))));
    PUTBACK;

    count = call_sv(cb_func, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Net::SSLeay: ssleay_ssl_ctx_sess_new_cb_invoke perl function did not return a scalar\n");

    remove = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return remove;
}

void ssleay_ssl_ctx_sess_remove_cb_invoke(SSL_CTX *ctx, SSL_SESSION *sess)
{
    dSP;
    SV *cb_func;

    PR1("STARTED: ssleay_ssl_ctx_sess_remove_cb_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "ssleay_ssl_ctx_sess_remove_cb!!func");

    if(!SvOK(cb_func))
        croak ("Net::SSLeay: ssleay_ssl_ctx_sess_remove_cb_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ctx))));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(sess))));
    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;

    PUTBACK;
    FREETMPS;
    LEAVE;
}

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
int ossl_provider_do_all_cb_invoke(OSSL_PROVIDER *provider, void *cbdata) {
    dSP;
    int ret = 1;
    int count = -1;
    simple_cb_data_t *cb = cbdata;

    PR1("STARTED: ossl_provider_do_all_cb_invoke\n");
    if (cb->func && SvOK(cb->func)) {
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(PTR2IV(provider))));
        if (cb->data) XPUSHs(cb->data);

        PUTBACK;

        count = call_sv(cb->func, G_SCALAR);

        SPAGAIN;

        if (count != 1)
          croak("Net::SSLeay: ossl_provider_do_all_cb_invoke perl function did not return a scalar\n");

        ret = POPi;

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    return ret;
}
#endif

#if OPENSSL_VERSION_NUMBER >= 0x10101001 && !defined(LIBRESSL_VERSION_NUMBER)
void ssl_ctx_keylog_cb_func_invoke(const SSL *ssl, const char *line)
{
    dSP;
    SV *cb_func, *cb_data;
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);

    PR1("STARTED: ssl_ctx_keylog_cb_func_invoke\n");
    cb_func = cb_data_advanced_get(ctx, "ssleay_ssl_ctx_keylog_callback!!func");

    if(!SvOK(cb_func))
	croak ("Net::SSLeay: ssl_ctx_keylog_cb_func_invoke called, but not set to point to any perl function.\n");

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(ssl))));
    XPUSHs(sv_2mortal(newSVpv(line, 0)));

    PUTBACK;

    call_sv(cb_func, G_VOID);

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}
#endif

/* ============= end of callback stuff, begin helper functions ============== */

time_t ASN1_TIME_timet(ASN1_TIME *asn1t, time_t *gmtoff) {
    struct tm t;
    const char *p = (const char*) asn1t->data;
    size_t msec = 0, tz = 0, i, l;
    time_t result;
    int adj = 0;

    if (asn1t->type == V_ASN1_UTCTIME) {
	if (asn1t->length<12 || asn1t->length>17) return 0;
	if (asn1t->length>12) tz = 12;
    } else {
	if (asn1t->length<14) return 0;
	if (asn1t->length>14) {
	    if (p[14] == '.') {
		msec = 14;
		for(i=msec+1;i<asn1t->length && p[i]>='0' && p[i]<='9';i++) ;
		if (i<asn1t->length) tz = i;
	    } else {
		tz = 14;
	    }
	}
    }

    l = msec ? msec : tz ? tz : asn1t->length;
    for(i=0;i<l;i++) {
	if (p[i]<'0' || p[i]>'9') return 0;
    }

    /* extract data and time */
    OPENSSL_cleanse(&t, sizeof(t));
    if (asn1t->type == V_ASN1_UTCTIME) { /* YY - two digit year */
	t.tm_year = (p[0]-'0')*10 + (p[1]-'0');
	if (t.tm_year < 70) t.tm_year += 100;
	i=2;
    } else { /* YYYY */
	t.tm_year = (p[0]-'0')*1000 + (p[1]-'0')*100 + (p[2]-'0')*10 + p[3]-'0';
	t.tm_year -= 1900;
	i=4;
    }
    t.tm_mon  = (p[i+0]-'0')*10 + (p[i+1]-'0') -1; /* MM, starts with 0 in tm */
    t.tm_mday = (p[i+2]-'0')*10 + (p[i+3]-'0');    /* DD */
    t.tm_hour = (p[i+4]-'0')*10 + (p[i+5]-'0');    /* hh */
    t.tm_min  = (p[i+6]-'0')*10 + (p[i+7]-'0');    /* mm */
    t.tm_sec  = (p[i+8]-'0')*10 + (p[i+9]-'0');    /* ss */

    /* skip msec, because time_t does not support it */

    if (tz) {
	/* TZ is 'Z' or [+-]DDDD and after TZ the string must stop*/
	if (p[tz] == 'Z') {
	    if (asn1t->length>tz+1 ) return 0;
	} else if (asn1t->length<tz+5 || (p[tz]!='-' && p[tz]!='+')) {
	    return 0;
	} else {
	    if (asn1t->length>tz+5 ) return 0;
	    for(i=tz+1;i<tz+5;i++) {
		if (p[i]<'0' || p[i]>'9') return 0;
	    }
	    adj = ((p[tz+1]-'0')*10 + (p[tz+2]-'0'))*3600
		+ ((p[tz+3]-'0')*10 + (p[tz+4]-'0'))*60;
	    if (p[tz]=='+') adj*= -1; /* +0500: subtract 5 hours to get UTC */
	}
    }

    result = mktime(&t);
    if (result == -1) return 0; /* broken time */
    result += adj;
    if (gmtoff && *gmtoff == -1) {
	*gmtoff = result - mktime(gmtime(&result));
	result += *gmtoff;
    } else {
	result += result - mktime(gmtime(&result));
    }
    return result;
}

X509 * find_issuer(X509 *cert,X509_STORE *store, STACK_OF(X509) *chain) {
    int i;
    X509 *issuer = NULL;

    /* search first in the chain */
    if (chain) {
	for(i=0;i<sk_X509_num(chain);i++) {
	    if ( X509_check_issued(sk_X509_value(chain,i),cert) == X509_V_OK ) {
		TRACE(2,"found issuer in chain");
		issuer = X509_dup(sk_X509_value(chain,i));
	    }
	}
    }
    /* if not in the chain it might be in the store */
    if ( !issuer && store ) {
	X509_STORE_CTX *stx = X509_STORE_CTX_new();
	if (stx && X509_STORE_CTX_init(stx,store,cert,NULL)) {
	    int ok = X509_STORE_CTX_get1_issuer(&issuer,stx,cert);
	    if (ok<0) {
		int err = ERR_get_error();
		if(err) {
		    TRACE(2,"failed to get issuer: %s",ERR_error_string(err,NULL));
		} else {
		    TRACE(2,"failed to get issuer: unknown error");
		}
	    } else if (ok == 0 ) {
		TRACE(2,"failed to get issuer(0)");
	    } else {
		TRACE(2,"got issuer");
	    }
	}
	if (stx) X509_STORE_CTX_free(stx);
    }
    return issuer;
}

SV* bn2sv(BIGNUM* p_bn)
{
    return p_bn != NULL
        ? sv_2mortal(newSViv((IV) BN_dup(p_bn)))
        : &PL_sv_undef;
}

/* ============= end of helper functions ============== */

MODULE = Net::SSLeay		PACKAGE = Net::SSLeay          PREFIX = SSL_

PROTOTYPES: ENABLE

BOOT:
    {
    MY_CXT_INIT;
    LIB_initialized = 0;
#ifdef USE_ITHREADS
    MUTEX_INIT(&LIB_init_mutex);
#ifdef OPENSSL_THREADS
    /* If we running under ModPerl, we dont need our own thread locking because
     * perl threads are not supported under mod-perl, and we can fall back to the thread
     * locking built in to mod-ssl      
     */
     if (!hv_fetch(get_hv("ENV", 1), "MOD_PERL", 8, 0))
	openssl_threads_init();
#endif
#endif
    /* initialize global shared callback data hash */
    MY_CXT.global_cb_data = newHV();
    MY_CXT.tid = get_my_thread_id();
#ifdef USE_ITHREADS
    PR3("BOOT: tid=%lu my_perl=%p\n", MY_CXT.tid, my_perl);
#else
    PR1("BOOT:\n");
#endif
    }

void
CLONE(...)
CODE:
    MY_CXT_CLONE;
    /* reset all callback related data as we want to prevent 
     * cross-thread callbacks
     * TODO: later somebody can make the global hash MY_CXT.global_cb_data
     * somehow shared between threads
     */
    MY_CXT.global_cb_data = newHV();
    MY_CXT.tid = get_my_thread_id();
#ifdef USE_ITHREADS
    PR3("CLONE: tid=%lu my_perl=%p\n", MY_CXT.tid, my_perl);
#else
    PR1("CLONE: but USE_ITHREADS not defined\n");
#endif

#ifdef NET_SSLEAY_32BIT_CONSTANTS
double
constant(name)
        char * name
    CODE:
        errno = 0;
        RETVAL = constant(name, strlen(name));
    OUTPUT:
        RETVAL

#else

uint64_t
constant(name)
        char * name
    CODE:
        errno = 0;
        RETVAL = constant(name, strlen(name));
    OUTPUT:
        RETVAL

#endif

int
hello()
        CODE:
        PR1("\tSSLeay Hello World!\n");
        RETVAL = 1;
        OUTPUT:
        RETVAL

#define REM0 "============= version related functions =============="

unsigned long
SSLeay()

const char *
SSLeay_version(type=SSLEAY_VERSION)
        int type

#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)

unsigned long
OpenSSL_version_num()

const char *
OpenSSL_version(t=OPENSSL_VERSION)
        int t

#endif /* OpenSSL 1.1.0 */

#if (OPENSSL_VERSION_MAJOR >= 3)

unsigned int
OPENSSL_version_major()

unsigned int
OPENSSL_version_minor()

unsigned int
OPENSSL_version_patch()

const char *
OPENSSL_version_pre_release()

const char *
OPENSSL_version_build_metadata()

const char *
OPENSSL_info(int t)

#endif

#define REM1 "============= SSL CONTEXT functions =============="

SSL_CTX *
SSL_CTX_new()
     CODE:
     RETVAL = SSL_CTX_new (SSLv23_method());
     OUTPUT:
     RETVAL


#if OPENSSL_VERSION_NUMBER < 0x10100000L
#ifndef OPENSSL_NO_SSL2 

SSL_CTX *
SSL_CTX_v2_new()
     CODE:
     RETVAL = SSL_CTX_new (SSLv2_method());
     OUTPUT:
     RETVAL

#endif
#endif
#ifndef OPENSSL_NO_SSL3

SSL_CTX *
SSL_CTX_v3_new()
     CODE:
     RETVAL = SSL_CTX_new (SSLv3_method());
     OUTPUT:
     RETVAL

#endif

SSL_CTX *
SSL_CTX_v23_new()
     CODE:
     RETVAL = SSL_CTX_new (SSLv23_method());
     OUTPUT:
     RETVAL

SSL_CTX *
SSL_CTX_tlsv1_new()
     CODE:
     RETVAL = SSL_CTX_new (TLSv1_method());
     OUTPUT:
     RETVAL

#ifdef SSL_TXT_TLSV1_1

SSL_CTX *
SSL_CTX_tlsv1_1_new()
     CODE:
     RETVAL = SSL_CTX_new (TLSv1_1_method());
     OUTPUT:
     RETVAL

#endif

#ifdef SSL_TXT_TLSV1_2

SSL_CTX *
SSL_CTX_tlsv1_2_new()
     CODE:
     RETVAL = SSL_CTX_new (TLSv1_2_method());
     OUTPUT:
     RETVAL

#endif

SSL_CTX *
SSL_CTX_new_with_method(meth)
     SSL_METHOD * meth
     CODE:
     RETVAL = SSL_CTX_new (meth);
     OUTPUT:
     RETVAL

void
SSL_CTX_free(ctx)
        SSL_CTX * ctx
     CODE:
        SSL_CTX_free(ctx);
        cb_data_advanced_drop(ctx); /* clean callback related data from global hash */

int
SSL_CTX_add_session(ctx,ses)
     SSL_CTX *          ctx
     SSL_SESSION *      ses

int
SSL_CTX_remove_session(ctx,ses)
     SSL_CTX *          ctx
     SSL_SESSION *      ses

void
SSL_CTX_flush_sessions(ctx,tm)
     SSL_CTX *          ctx
     long               tm

int
SSL_CTX_set_default_verify_paths(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_load_verify_locations(ctx,CAfile,CApath)
     SSL_CTX * ctx
     char * CAfile
     char * CApath
     CODE:
     RETVAL = SSL_CTX_load_verify_locations (ctx,
					     CAfile?(*CAfile?CAfile:NULL):NULL,
					     CApath?(*CApath?CApath:NULL):NULL
					     );
     OUTPUT:
     RETVAL

void
SSL_CTX_set_verify(ctx,mode,callback=&PL_sv_undef)
        SSL_CTX * ctx
        int mode
        SV * callback
    CODE:

    /* Former versions of SSLeay checked if the callback was a true boolean value
     * and didn't call it if it was false. Therefor some people set the callback
     * to '0' if they don't want to use it (IO::Socket::SSL for example). Therefor
     * we don't execute the callback if it's value isn't something true to retain
     * backwards compatibility.
     */

    if (callback==NULL || !SvOK(callback) || !SvTRUE(callback)) {
        SSL_CTX_set_verify(ctx, mode, NULL);
        cb_data_advanced_put(ctx, "ssleay_verify_callback!!func", NULL);
    } else {
        cb_data_advanced_put(ctx, "ssleay_verify_callback!!func", newSVsv(callback));
        SSL_CTX_set_verify(ctx, mode, &ssleay_verify_callback_invoke);
    }

#if OPENSSL_VERSION_NUMBER >= 0x10100001L && !defined(LIBRESSL_VERSION_NUMBER)

void
SSL_CTX_set_security_level(SSL_CTX * ctx, int level)

int
SSL_CTX_get_security_level(SSL_CTX * ctx)

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10101007L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_CTX_set_num_tickets(SSL_CTX *ctx, size_t num_tickets)

size_t
SSL_CTX_get_num_tickets(SSL_CTX *ctx)

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10101003L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_CTX_set_ciphersuites(SSL_CTX *ctx, const char *str)

#endif

#if OPENSSL_VERSION_NUMBER >= 0x1010100fL && !defined(LIBRESSL_VERSION_NUMBER) /* OpenSSL 1.1.1 */

void
SSL_CTX_set_post_handshake_auth(SSL_CTX *ctx, int val)

#endif

void
SSL_CTX_sess_set_new_cb(ctx, callback)
        SSL_CTX * ctx
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_sess_set_new_cb(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ssl_ctx_sess_new_cb!!func", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ssl_ctx_sess_new_cb!!func", newSVsv(callback));
            SSL_CTX_sess_set_new_cb(ctx, &ssleay_ssl_ctx_sess_new_cb_invoke);
        }

void
SSL_CTX_sess_set_remove_cb(ctx, callback)
        SSL_CTX * ctx
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_sess_set_remove_cb(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ssl_ctx_sess_remove_cb!!func", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ssl_ctx_sess_remove_cb!!func", newSVsv(callback));
            SSL_CTX_sess_set_remove_cb(ctx, &ssleay_ssl_ctx_sess_remove_cb_invoke);
        }

int
SSL_get_error(s,ret)
     SSL *              s
     int ret

#define REM10 "============= SSL functions =============="

SSL *
SSL_new(ctx)
     SSL_CTX *	        ctx

void
SSL_free(s)
        SSL * s
     CODE:
        SSL_free(s);
        cb_data_advanced_drop(s); /* clean callback related data from global hash */

#if 0 /* this seems to be gone in 0.9.0 */
void
SSL_debug(file)
       char *  file

#endif

int
SSL_accept(s)
     SSL *   s

void
SSL_clear(s)
     SSL *   s

int
SSL_connect(s)
     SSL *   s


#if defined(WIN32)

int
SSL_set_fd(s,fd)
     SSL *   s
     perl_filehandle_t     fd
     CODE:
     RETVAL = SSL_set_fd(s,_get_osfhandle(fd));
     OUTPUT:
     RETVAL

int
SSL_set_rfd(s,fd)
     SSL *   s
     perl_filehandle_t     fd
     CODE:
     RETVAL = SSL_set_rfd(s,_get_osfhandle(fd));
     OUTPUT:
     RETVAL

int
SSL_set_wfd(s,fd)
     SSL *   s
     perl_filehandle_t     fd
     CODE:
     RETVAL = SSL_set_wfd(s,_get_osfhandle(fd));
     OUTPUT:
     RETVAL

#else

int
SSL_set_fd(s,fd)
     SSL *   s
     perl_filehandle_t     fd

int
SSL_set_rfd(s,fd)
     SSL *   s
     perl_filehandle_t     fd

int
SSL_set_wfd(s,fd)
     SSL *   s
     perl_filehandle_t     fd

#endif

int
SSL_get_fd(s)
     SSL *   s

void
SSL_read(s,max=32768)
	SSL *   s
	int     max
    PREINIT:
	char *buf;
	int got;
	int succeeded = 1;
    PPCODE:
	New(0, buf, max, char);

	got = SSL_read(s, buf, max);
	if (got <= 0 && SSL_ERROR_ZERO_RETURN != SSL_get_error(s, got))
	       succeeded = 0;

	/* If in list context, return 2-item list:
	 *   first return value:  data gotten, or undef on error (got<0)
	 *   second return value: result from SSL_read()
	 */
	if (GIMME_V==G_ARRAY) {
	    EXTEND(SP, 2);
	    PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, got) : newSV(0)));
	    PUSHs(sv_2mortal(newSViv(got)));

	/* If in scalar or void context, return data gotten, or undef on error. */
	} else {
	    EXTEND(SP, 1);
	    PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, got) : newSV(0)));
	}

	Safefree(buf);

void
SSL_peek(s,max=32768)
	SSL *   s
	int     max
    PREINIT:
	char *buf;
	int got;
	int succeeded = 1;
    PPCODE:
	New(0, buf, max, char);

	got = SSL_peek(s, buf, max);
	if (got <= 0 && SSL_ERROR_ZERO_RETURN != SSL_get_error(s, got))
	       succeeded = 0;

	/* If in list context, return 2-item list:
	 *   first return value:  data gotten, or undef on error (got<0)
	 *   second return value: result from SSL_peek()
	 */
	if (GIMME_V==G_ARRAY) {
	    EXTEND(SP, 2);
	    PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, got) : newSV(0)));
	    PUSHs(sv_2mortal(newSViv(got)));
	    
	    /* If in scalar or void context, return data gotten, or undef on error. */
	} else {
	    EXTEND(SP, 1);
	    PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, got) : newSV(0)));
	}
	Safefree(buf);

#if OPENSSL_VERSION_NUMBER >= 0x1010100fL && !defined(LIBRESSL_VERSION_NUMBER) /* OpenSSL 1.1.1 */

void
SSL_read_ex(s,max=32768)
	SSL *   s
	int     max
    PREINIT:
	char *buf;
	size_t readbytes;
	int succeeded;
    PPCODE:
	Newx(buf, max, char);

	succeeded = SSL_read_ex(s, buf, max, &readbytes);

	/* Return 2-item list:
	 *   first return value:  data gotten, or undef on error
	 *   second return value: result from SSL_read_ex()
	 */
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, readbytes) : newSV(0)));
	PUSHs(sv_2mortal(newSViv(succeeded)));

	Safefree(buf);


void
SSL_peek_ex(s,max=32768)
	SSL *   s
	int     max
    PREINIT:
	char *buf;
	size_t readbytes;
	int succeeded;
    PPCODE:
	Newx(buf, max, char);

	succeeded = SSL_peek_ex(s, buf, max, &readbytes);

	/* Return 2-item list:
	 *   first return value:  data gotten, or undef on error
	 *   second return value: result from SSL_peek_ex()
	 */
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(succeeded ? newSVpvn(buf, readbytes) : newSV(0)));
	PUSHs(sv_2mortal(newSViv(succeeded)));

	Safefree(buf);

void
SSL_write_ex(s,buf)
	SSL *   s
    PREINIT:
	STRLEN len;
	size_t written;
	int succeeded;
    INPUT:
	char *  buf = SvPV( ST(1), len);
    PPCODE:
	succeeded = SSL_write_ex(s, buf, len, &written);

	/* Return 2-item list:
	 *   first return value:  data gotten, or undef on error
	 *   second return value: result from SSL_read_ex()
	 */
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSVuv(written)));
	PUSHs(sv_2mortal(newSViv(succeeded)));

#endif

int
SSL_write(s,buf)
     SSL *   s
     PREINIT:
     STRLEN len;
     INPUT:
     char *  buf = SvPV( ST(1), len);
     CODE:
     RETVAL = SSL_write (s, buf, (int)len);
     OUTPUT:
     RETVAL

int
SSL_write_partial(s,from,count,buf)
     SSL *   s
     int     from
     int     count
     PREINIT:
     STRLEN ulen;
     IV len;
     INPUT:
     char *  buf = SvPV( ST(3), ulen);
     CODE:
      /*
     if (SvROK( ST(3) )) {
       SV* t = SvRV( ST(3) );
       buf = SvPV( t, len);
     } else
       buf = SvPV( ST(3), len);
       */
     PR4("write_partial from=%d count=%d len=%lu\n",from,count,ulen);
     /*PR2("buf='%s'\n",&buf[from]); / * too noisy */
     len = (IV)ulen;
     len -= from;
     if (len < 0) {
       croak("from beyound end of buffer");
       RETVAL = -1;
     } else
       RETVAL = SSL_write (s, &(buf[from]), (count<=len)?count:len);
     OUTPUT:
     RETVAL

int
SSL_use_RSAPrivateKey(s,rsa)
     SSL *              s
     RSA *              rsa

int
SSL_use_RSAPrivateKey_ASN1(s,d,len)
     SSL *              s
     unsigned char *    d
     long               len

int
SSL_use_RSAPrivateKey_file(s,file,type)
     SSL *              s
     char *             file
     int                type

int
SSL_CTX_use_RSAPrivateKey_file(ctx,file,type)
     SSL_CTX *          ctx
     char *             file
     int                type

int
SSL_use_PrivateKey(s,pkey)
     SSL *              s
     EVP_PKEY *         pkey

int
SSL_use_PrivateKey_ASN1(pk,s,d,len)
     int                pk
     SSL *              s
     unsigned char *    d
     long               len

int
SSL_use_PrivateKey_file(s,file,type)
     SSL *              s
     char *             file
     int                type

int
SSL_CTX_use_PrivateKey_file(ctx,file,type)
     SSL_CTX *          ctx
     char *             file
     int                type

int
SSL_use_certificate(s,x)
     SSL *              s
     X509 *             x

int
SSL_use_certificate_ASN1(s,d,len)
     SSL *              s
     unsigned char *    d
     long               len

int
SSL_use_certificate_file(s,file,type)
     SSL *              s
     char *             file
     int                type

int
SSL_CTX_use_certificate_file(ctx,file,type)
     SSL_CTX *          ctx
     char *             file
     int                type

const char *
SSL_state_string(s)
     SSL *              s

const char *
SSL_rstate_string(s)
     SSL *              s

const char *
SSL_state_string_long(s)
     SSL *              s

const char *
SSL_rstate_string_long(s)
     SSL *              s


long
SSL_get_time(ses)
     SSL_SESSION *      ses

long
SSL_set_time(ses,t)
     SSL_SESSION *      ses
     long               t

long
SSL_get_timeout(ses)
     SSL_SESSION *      ses

long
SSL_set_timeout(ses,t)
     SSL_SESSION *      ses
     long               t

void
SSL_copy_session_id(to,from)
     SSL *              to
     SSL *              from

void
SSL_set_read_ahead(s,yes=1)
     SSL *              s
     int                yes

int
SSL_get_read_ahead(s)
     SSL *              s

int
SSL_pending(s)
     SSL *              s

#if OPENSSL_VERSION_NUMBER >= 0x1010000fL && !defined(LIBRESSL_VERSION_NUMBER) /* OpenSSL 1.1.0 */

int
SSL_has_pending(s)
     SSL *              s

#endif

int
SSL_CTX_set_cipher_list(s,str)
     SSL_CTX *              s
     char *             str

void
SSL_get_ciphers(s)
        SSL *              s
    PREINIT:
        STACK_OF(SSL_CIPHER) *sk = NULL;
        const SSL_CIPHER *c;
        int i;
    PPCODE:
        sk = SSL_get_ciphers(s);
        if( sk == NULL ) {
            XSRETURN_EMPTY;
        }
        for (i=0; i<sk_SSL_CIPHER_num(sk); i++) {
            c = sk_SSL_CIPHER_value(sk, i);
            XPUSHs(sv_2mortal(newSViv(PTR2IV(c))));
        }

const char *
SSL_get_cipher_list(s,n)
     SSL *              s
     int                n

int
SSL_set_cipher_list(s,str)
     SSL *              s
     char *       str

const char *
SSL_get_cipher(s)
     SSL *              s

void
SSL_get_shared_ciphers(s,ignored_param1=0,ignored_param2=0)
        SSL *s
        int ignored_param1
        int ignored_param2
    PREINIT:
        char buf[8192];
    CODE:
        ST(0) = sv_newmortal();   /* undef to start with */
        if(SSL_get_shared_ciphers(s, buf, sizeof(buf)))
            sv_setpvn(ST(0), buf, strlen(buf));

X509 *
SSL_get_peer_certificate(s)
     SSL *              s

void
SSL_get_peer_cert_chain(s)
     SSL *              s
    PREINIT:
        STACK_OF(X509) *chain = NULL;
        X509 *x;
	int i;
    PPCODE:
	chain = SSL_get_peer_cert_chain(s);
	if( chain == NULL ) {
	    XSRETURN_EMPTY;
	}
	for (i=0; i<sk_X509_num(chain); i++) {
	    x = sk_X509_value(chain, i);
	    XPUSHs(sv_2mortal(newSViv(PTR2IV(x))));
	}

void
SSL_set_verify(s,mode,callback)
        SSL * s
        int mode
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_verify(s, mode, NULL);
            cb_data_advanced_put(s, "ssleay_verify_callback!!func", NULL);
        }
        else {
            cb_data_advanced_put(s, "ssleay_verify_callback!!func", newSVsv(callback));
            SSL_set_verify(s, mode, &ssleay_verify_callback_invoke);
        }

void
SSL_set_bio(s,rbio,wbio)
     SSL *              s
     BIO *              rbio
     BIO *              wbio

BIO *
SSL_get_rbio(s)
     SSL *              s

BIO *
SSL_get_wbio(s)
     SSL *              s


SSL_SESSION *
SSL_SESSION_new()

int
SSL_SESSION_print(fp,ses)
     BIO *              fp
     SSL_SESSION *      ses

void
SSL_SESSION_free(ses)
     SSL_SESSION *      ses

#if OPENSSL_VERSION_NUMBER >= 0x10101001L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_SESSION_is_resumable(ses)
     SSL_SESSION *      ses

SSL_SESSION *
SSL_SESSION_dup(sess)
     SSL_SESSION * sess

#endif
#if OPENSSL_VERSION_NUMBER >= 0x1010100fL && !defined(LIBRESSL_VERSION_NUMBER) /* OpenSSL 1.1.1 */

void
SSL_set_post_handshake_auth(SSL *ssl, int val)

int
SSL_verify_client_post_handshake(SSL *ssl)

#endif

void
i2d_SSL_SESSION(sess)
	SSL_SESSION * sess
    PPCODE:
	STRLEN len;
	unsigned char *pc,*pi;
	if (!(len = i2d_SSL_SESSION(sess,NULL))) croak("invalid SSL_SESSION");
	Newx(pc,len,unsigned char);
	if (!pc) croak("out of memory");
	pi = pc;
	i2d_SSL_SESSION(sess,&pi);
	XPUSHs(sv_2mortal(newSVpv((char*)pc,len)));
	Safefree(pc);


SSL_SESSION *
d2i_SSL_SESSION(pv)
	SV *pv
    CODE:
	RETVAL = NULL;
	if (SvPOK(pv)) {
	    const unsigned char *p;
	    STRLEN len;
	    p = (unsigned char*)SvPV(pv,len);
	    RETVAL = d2i_SSL_SESSION(NULL,&p,len);
	}
    OUTPUT:
	RETVAL

#if (OPENSSL_VERSION_NUMBER >= 0x10100004L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)

int
SSL_SESSION_up_ref(sess)
     SSL_SESSION * sess

#endif

int
SSL_set_session(to,ses)
     SSL *              to
     SSL_SESSION *      ses

#define REM30 "SSLeay-0.9.0 defines these as macros. I expand them here for safety's sake"

SSL_SESSION *
SSL_get_session(s)
	SSL *              s
	ALIAS:
		SSL_get0_session = 1

SSL_SESSION *
SSL_get1_session(s)
     SSL *              s

X509 *
SSL_get_certificate(s)
     SSL *              s

SSL_CTX *
SSL_get_SSL_CTX(s)
     SSL *              s

#if OPENSSL_VERSION_NUMBER >= 0x0090806fL

SSL_CTX *
SSL_set_SSL_CTX(SSL *ssl, SSL_CTX* ctx)

#endif

long
SSL_ctrl(ssl,cmd,larg,parg)
	 SSL * ssl
	 int cmd
	 long larg
	 char * parg

long
SSL_CTX_ctrl(ctx,cmd,larg,parg)
    SSL_CTX * ctx
    int cmd
    long larg
    char * parg

#ifdef NET_SSLEAY_32BIT_CONSTANTS

long
SSL_get_options(ssl)
     SSL *          ssl

long
SSL_set_options(ssl,op)
     SSL *          ssl
     long	    op

long
SSL_CTX_get_options(ctx)
     SSL_CTX *      ctx

long
SSL_CTX_set_options(ctx,op)
     SSL_CTX *      ctx
     long	    op

#else

uint64_t
SSL_get_options(ssl)
     SSL *          ssl

uint64_t
SSL_set_options(ssl,op)
     SSL *          ssl
     uint64_t	    op

uint64_t
SSL_CTX_get_options(ctx)
     SSL_CTX *      ctx

uint64_t
SSL_CTX_set_options(ctx,op)
     SSL_CTX *      ctx
     uint64_t	    op

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10000000L

struct lhash_st_SSL_SESSION *
SSL_CTX_sessions(ctx)
     SSL_CTX *          ctx

#else

LHASH *
SSL_CTX_sessions(ctx)
     SSL_CTX *          ctx
     CODE:
    /* NOTE: This should be deprecated. Corresponding macro was removed from ssl.h as of 0.9.2 */
     if (ctx == NULL) croak("NULL SSL context passed as argument.");
     RETVAL = ctx -> sessions;
     OUTPUT:
     RETVAL

#endif

unsigned long
SSL_CTX_sess_number(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_connect(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_connect_good(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_connect_renegotiate(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_accept(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_accept_renegotiate(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_accept_good(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_hits(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_cb_hits(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_misses(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_timeouts(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_cache_full(ctx)
     SSL_CTX *          ctx

int
SSL_CTX_sess_get_cache_size(ctx)
     SSL_CTX *          ctx

long
SSL_CTX_sess_set_cache_size(ctx,size)
     SSL_CTX *          ctx
     int                size

int
SSL_want(s)
     SSL *              s

 # OpenSSL 1.1.1 documents SSL_in_init and the related functions as
 # returning 0 or 1. However, older versions and e.g. LibreSSL may
 # return other values than 1 which we fold to 1.
int
SSL_in_before(s)
     SSL *              s
     CODE:
     RETVAL = SSL_in_before(s) == 0 ? 0 : 1;
     OUTPUT:
     RETVAL

int
SSL_is_init_finished(s)
     SSL *              s
     CODE:
     RETVAL = SSL_is_init_finished(s) == 0 ? 0 : 1;
     OUTPUT:
     RETVAL

int
SSL_in_init(s)
     SSL *              s
     CODE:
     RETVAL = SSL_in_init(s) == 0 ? 0 : 1;
     OUTPUT:
     RETVAL

int
SSL_in_connect_init(s)
     SSL *              s
     CODE:
     RETVAL = SSL_in_connect_init(s) == 0 ? 0 : 1;
     OUTPUT:
     RETVAL

int
SSL_in_accept_init(s)
     SSL *              s
     CODE:
     RETVAL = SSL_in_accept_init(s) == 0 ? 0 : 1;
     OUTPUT:
     RETVAL

#if OPENSSL_VERSION_NUMBER < 0x10100000L
int
SSL_state(s)
     SSL *              s

int
SSL_get_state(ssl)
     SSL *	ssl
  CODE:
  RETVAL = SSL_state(ssl);
  OUTPUT:
  RETVAL


#else
int
SSL_state(s)
     SSL *              s
     CODE:
     RETVAL = SSL_get_state(s);
     OUTPUT:
     RETVAL


int
SSL_get_state(s)
     SSL *              s

#endif
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)

long
SSL_set_tlsext_host_name(SSL *ssl, const char *name)

const char *
SSL_get_servername(const SSL *s, int type=TLSEXT_NAMETYPE_host_name) 

int
SSL_get_servername_type(const SSL *s) 

void
SSL_CTX_set_tlsext_servername_callback(ctx,callback=&PL_sv_undef,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
        SV * data
    CODE:
    if (callback==NULL || !SvOK(callback)) {
        SSL_CTX_set_tlsext_servername_callback(ctx, NULL);
        SSL_CTX_set_tlsext_servername_arg(ctx, NULL);
        cb_data_advanced_put(ctx, "tlsext_servername_callback!!data", NULL);
        cb_data_advanced_put(ctx, "tlsext_servername_callback!!func", NULL);
    } else {
        cb_data_advanced_put(ctx, "tlsext_servername_callback!!data", newSVsv(data));
        cb_data_advanced_put(ctx, "tlsext_servername_callback!!func", newSVsv(callback));
        SSL_CTX_set_tlsext_servername_callback(ctx, &tlsext_servername_callback_invoke);
        SSL_CTX_set_tlsext_servername_arg(ctx, (void*)ctx);
    }

#endif

#if OPENSSL_VERSION_NUMBER >= 0x1010006fL /* In OpenSSL 1.1.0 but actually called for $ssl starting from 1.1.0f */
#ifndef LIBRESSL_VERSION_NUMBER
#ifndef OPENSSL_IS_BORINGSSL
void
SSL_set_default_passwd_cb(ssl,callback=&PL_sv_undef)
        SSL * ssl
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_default_passwd_cb(ssl, NULL);
            SSL_set_default_passwd_cb_userdata(ssl, NULL);
            cb_data_advanced_put(ssl, "ssleay_ssl_passwd_cb!!func", NULL);
        }
        else {
            cb_data_advanced_put(ssl, "ssleay_ssl_passwd_cb!!func", newSVsv(callback));
            SSL_set_default_passwd_cb_userdata(ssl, (void*)ssl);
            SSL_set_default_passwd_cb(ssl, &ssleay_ssl_passwd_cb_invoke);
        }

void
SSL_set_default_passwd_cb_userdata(ssl,data=&PL_sv_undef)
        SSL * ssl
        SV * data
    CODE:
        /* SSL_set_default_passwd_cb_userdata is set in SSL_set_default_passwd_cb */
        if (data==NULL || !SvOK(data)) {
            cb_data_advanced_put(ssl, "ssleay_ssl_passwd_cb!!data", NULL);
        }
        else {
            cb_data_advanced_put(ssl, "ssleay_ssl_passwd_cb!!data", newSVsv(data));
        }

#endif /* !BoringSSL */
#endif /* !LibreSSL */
#endif /* >= 1.1.0f */

#if OPENSSL_VERSION_NUMBER >= 0x10100001L && !defined(LIBRESSL_VERSION_NUMBER)

void
SSL_set_security_level(SSL * ssl, int level)

int
SSL_get_security_level(SSL * ssl)

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10101007L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_set_num_tickets(SSL *ssl, size_t num_tickets)

size_t
SSL_get_num_tickets(SSL *ssl)

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10101003L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_set_ciphersuites(SSL *ssl, const char *str)

#endif

const BIO_METHOD *
BIO_f_ssl()

const BIO_METHOD *
BIO_s_mem()

unsigned long
ERR_get_error()

unsigned long
ERR_peek_error()

void
ERR_put_error(lib,func,reason,file,line)
     int                lib
     int                func
     int                reason
     char *             file
     int                line

void
ERR_clear_error()

char *
ERR_error_string(error,buf=NULL)
     unsigned long      error
     char *             buf
     CODE:
     RETVAL = ERR_error_string(error,buf);
     OUTPUT:
     RETVAL

void
SSL_load_error_strings()

void
ERR_load_crypto_strings()

int
SSL_FIPS_mode_set(int onoff)
       CODE:
#ifdef USE_ITHREADS
               MUTEX_LOCK(&LIB_init_mutex);
#endif
#ifdef OPENSSL_FIPS
               RETVAL = FIPS_mode_set(onoff);
               if (!RETVAL) 
	       {
		   ERR_load_crypto_strings();
		   ERR_print_errors_fp(stderr);
               }
#else
               RETVAL = 1;
               fprintf(stderr, "SSL_FIPS_mode_set not available: OpenSSL not compiled with FIPS support\n");
#endif
#ifdef USE_ITHREADS
               MUTEX_UNLOCK(&LIB_init_mutex);
#endif
       OUTPUT:
       RETVAL


int
SSL_library_init()
	ALIAS:
		SSLeay_add_ssl_algorithms  = 1
		OpenSSL_add_ssl_algorithms = 2
		add_ssl_algorithms         = 3
	CODE:
#ifdef USE_ITHREADS
		MUTEX_LOCK(&LIB_init_mutex);
#endif
		RETVAL = 0;
		if (!LIB_initialized) {
			RETVAL = SSL_library_init();
			LIB_initialized = 1;
		}
#ifdef USE_ITHREADS
		MUTEX_UNLOCK(&LIB_init_mutex);
#endif
	OUTPUT:
	RETVAL

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
#define REM5 "NOTE: requires 0.9.7+"
#ifndef OPENSSL_NO_ENGINE

void
ENGINE_load_builtin_engines()

void
ENGINE_register_all_complete()

ENGINE*
ENGINE_by_id(id)
	char * id

int
ENGINE_set_default(e, flags)
        ENGINE * e
        int flags

#endif /* OPENSSL_NO_ENGINE */
#endif

void
ERR_load_SSL_strings()

void
ERR_load_RAND_strings()

int
RAND_bytes(buf, num)
    SV *buf
    int num
    PREINIT:
        int rc;
        unsigned char *random;
    CODE:
        New(0, random, num, unsigned char);
        rc = RAND_bytes(random, num);
        sv_setpvn(buf, (const char*)random, num);
        Safefree(random);
        RETVAL = rc;
    OUTPUT:
        RETVAL

#if OPENSSL_VERSION_NUMBER >= 0x10101001L && !defined(LIBRESSL_VERSION_NUMBER)

int
RAND_priv_bytes(buf, num)
    SV *buf
    int num
    PREINIT:
        int rc;
        unsigned char *random;
    CODE:
        New(0, random, num, unsigned char);
        rc = RAND_priv_bytes(random, num);
        sv_setpvn(buf, (const char*)random, num);
        Safefree(random);
        RETVAL = rc;
    OUTPUT:
        RETVAL

#endif

int
RAND_pseudo_bytes(buf, num)
    SV *buf
    int num
    PREINIT:
        int rc;
        unsigned char *random;
    CODE:
        New(0, random, num, unsigned char);
        rc = RAND_pseudo_bytes(random, num);
        sv_setpvn(buf, (const char*)random, num);
        Safefree(random);
        RETVAL = rc;
    OUTPUT:
        RETVAL

void
RAND_add(buf, num, entropy)
    SV *buf
    int num
    double entropy
    PREINIT:
        STRLEN len;
    CODE:
        RAND_add((const void *)SvPV(buf, len), num, entropy);

int
RAND_poll()

int
RAND_status()

SV *
RAND_file_name(num)
    size_t num
    PREINIT:
        char *buf;
    CODE:
        Newxz(buf, num, char);
        if (!RAND_file_name(buf, num)) {
            Safefree(buf);
            XSRETURN_UNDEF;
        }
        RETVAL = newSVpv(buf, 0);
        Safefree(buf);
    OUTPUT:
        RETVAL

void
RAND_seed(buf)
     PREINIT:
     STRLEN len;
     INPUT:
     char *  buf = SvPV( ST(1), len);
     CODE:
     RAND_seed (buf, (int)len);

void
RAND_cleanup()

int
RAND_load_file(file_name, how_much)
     char *  file_name
     int     how_much

int
RAND_write_file(file_name)
     char *  file_name

#define REM40 "Minimal X509 stuff..., this is a bit ugly and should be put in its own modules Net::SSLeay::X509.pm"

#if (OPENSSL_VERSION_NUMBER >= 0x1000200fL && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2050000fL)

int
X509_check_host(X509 *cert, const char *name, unsigned int flags = 0, SV *peername = &PL_sv_undef)
    PREINIT:
        char *c_peername = NULL;
    CODE:
        RETVAL = X509_check_host(cert, name, 0, flags, (items == 4) ? &c_peername : NULL);
        if (items == 4)
            sv_setpv(peername, c_peername);
    OUTPUT:
        RETVAL
    CLEANUP:
        if (c_peername)
            OPENSSL_free(c_peername);

int
X509_check_email(X509 *cert, const char *address, unsigned int flags = 0)
    CODE:
        RETVAL = X509_check_email(cert, address, 0, flags);
    OUTPUT:
        RETVAL

int
X509_check_ip(X509 *cert, SV *address, unsigned int flags = 0)
    PREINIT:
        unsigned char *c_address;
        size_t addresslen;
    CODE:
        c_address = (unsigned char *)SvPV(address, addresslen);
        RETVAL = X509_check_ip(cert, c_address, addresslen, flags);
    OUTPUT:
        RETVAL

int
X509_check_ip_asc(X509 *cert, const char *address, unsigned int flags = 0)

#endif

X509_NAME*
X509_get_issuer_name(cert)
     X509 *      cert

X509_NAME*
X509_get_subject_name(cert)
     X509 *      cert

void *
X509_get_ex_data(cert,idx)
     X509 *  cert
     int     idx

int
X509_get_ex_new_index(argl,argp=NULL,new_func=NULL,dup_func=NULL,free_func=NULL)
     long argl
     void *  argp
     CRYPTO_EX_new *   new_func
     CRYPTO_EX_dup *   dup_func
     CRYPTO_EX_free *  free_func

void *
X509_get_app_data(cert)
     X509 *  cert
  CODE:
     RETVAL = X509_get_ex_data(cert,0);
  OUTPUT:
     RETVAL

int
X509_set_ex_data(cert,idx,data)
     X509 *  cert
     int     idx
     void *  data

int
X509_set_app_data(cert,arg)
     X509 *  cert
     char *  arg
  CODE:
     RETVAL = X509_set_ex_data(cert,0,arg);
  OUTPUT:
     RETVAL

int
X509_set_issuer_name(X509 *x, X509_NAME *name)

int
X509_set_subject_name(X509 *x, X509_NAME *name)

int
X509_set_version(X509 *x, long version)

int
X509_set_pubkey(X509 *x, EVP_PKEY *pkey)

long
X509_get_version(X509 *x)

EVP_PKEY *
X509_get_pubkey(X509 *x)

ASN1_INTEGER *
X509_get_serialNumber(X509 *x)

#if (OPENSSL_VERSION_NUMBER >= 0x1010000fL && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2080100fL)

const ASN1_INTEGER *
X509_get0_serialNumber(const X509 *x)

#endif

int
X509_set_serialNumber(X509 *x, ASN1_INTEGER *serial)

int
X509_certificate_type(X509 *x, EVP_PKEY *pubkey=NULL);

int
X509_sign(X509 *x, EVP_PKEY *pkey, const EVP_MD *md)

int
X509_verify(X509 *x, EVP_PKEY *r)

X509_NAME *
X509_NAME_new()

unsigned long
X509_NAME_hash(X509_NAME *name)

void
X509_NAME_oneline(name)
	X509_NAME *    name
	PREINIT:
	char * buf;
	CODE:
	ST(0) = sv_newmortal();   /* Undefined to start with */
	if ((buf = X509_NAME_oneline(name, NULL, 0))) {
		sv_setpvn( ST(0), buf, strlen(buf));
		OPENSSL_free(buf); /* mem was allocated by openssl */
	}

void
X509_NAME_print_ex(name,flags=XN_FLAG_RFC2253,utf8_decode=0)
        X509_NAME * name
        unsigned long flags
        int utf8_decode
    PREINIT:
        char * buf;
        BIO * bp;
        int n, i, ident=0;
    CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp) {
            if (X509_NAME_print_ex(bp, name, ident, flags)) {
                n = BIO_ctrl_pending(bp);
                New(0, buf, n, char);
                if (buf) {
                    i = BIO_read(bp,buf,n);
                    if (i>=0 && i<=n) {
                        sv_setpvn(ST(0), buf, i);
                        if (utf8_decode) sv_utf8_decode(ST(0));
                    }
                    Safefree(buf);
                }
            }
            BIO_free(bp);
        }

void
X509_NAME_get_text_by_NID(name,nid)
	X509_NAME *    name
	int nid
	PREINIT:
	char* buf;
	int length;
	CODE:
	ST(0) = sv_newmortal();   /* Undefined to start with */
	length = X509_NAME_get_text_by_NID(name, nid, NULL, 0);

       if (length>=0) {
               New(0, buf, length+1, char);
               if (X509_NAME_get_text_by_NID(name, nid, buf, length + 1)>=0)
                       sv_setpvn( ST(0), buf, length);
               Safefree(buf);
       }

#if OPENSSL_VERSION_NUMBER >= 0x0090500fL
#define REM17 "requires 0.9.5+"

int
X509_NAME_add_entry_by_NID(name,nid,type,bytes,loc=-1,set=0)
        X509_NAME *name
        int nid
        int type
        int loc
        int set
    PREINIT:
        STRLEN len;
    INPUT:
        unsigned char *bytes = (unsigned char *)SvPV(ST(3), len);
    CODE:
        RETVAL = X509_NAME_add_entry_by_NID(name,nid,type,bytes,len,loc,set);
    OUTPUT:
        RETVAL

int
X509_NAME_add_entry_by_OBJ(name,obj,type,bytes,loc=-1,set=0)
        X509_NAME *name
        ASN1_OBJECT *obj
        int type
        int loc
        int set
    PREINIT:
        STRLEN len;
    INPUT:
        unsigned char *bytes = (unsigned char *)SvPV(ST(3), len);
    CODE:
        RETVAL = X509_NAME_add_entry_by_OBJ(name,obj,type,bytes,len,loc,set);
    OUTPUT:
        RETVAL

int
X509_NAME_add_entry_by_txt(name,field,type,bytes,loc=-1,set=0)
        X509_NAME *name
        char *field
        int type
        int loc
        int set
    PREINIT:
        STRLEN len;
    INPUT:
        unsigned char *bytes = (unsigned char *)SvPV(ST(3), len);
    CODE:
        RETVAL = X509_NAME_add_entry_by_txt(name,field,type,bytes,len,loc,set);
    OUTPUT:
        RETVAL

#endif

int
X509_NAME_cmp(const X509_NAME *a, const X509_NAME *b)

int
X509_NAME_entry_count(X509_NAME *name)

X509_NAME_ENTRY *
X509_NAME_get_entry(X509_NAME *name, int loc)

ASN1_STRING *
X509_NAME_ENTRY_get_data(X509_NAME_ENTRY *ne)

ASN1_OBJECT *
X509_NAME_ENTRY_get_object(X509_NAME_ENTRY *ne)

void
X509_CRL_free(X509_CRL *x)

X509_CRL *
X509_CRL_new()

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
#define REM19 "requires 0.9.7+"

int
X509_CRL_set_version(X509_CRL *x, long version)

int
X509_CRL_set_issuer_name(X509_CRL *x, X509_NAME *name)

int
X509_CRL_set_lastUpdate(X509_CRL *x, ASN1_TIME *tm)

int
X509_CRL_set_nextUpdate(X509_CRL *x, ASN1_TIME *tm)

int
X509_CRL_sort(X509_CRL *x)

#endif

long
X509_CRL_get_version(X509_CRL *x)

X509_NAME *
X509_CRL_get_issuer(X509_CRL *x)

ASN1_TIME *
X509_CRL_get_lastUpdate(X509_CRL *x)

ASN1_TIME *
X509_CRL_get_nextUpdate(X509_CRL *x)

int
X509_CRL_verify(X509_CRL *a, EVP_PKEY *r)

int
X509_CRL_sign(X509_CRL *x, EVP_PKEY *pkey, const EVP_MD *md)

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
#define REM20 "requires 0.9.7+"

int
P_X509_CRL_set_serial(crl,crl_number)
        X509_CRL *crl
        ASN1_INTEGER * crl_number;
    CODE:
        RETVAL = 0;
        if (crl && crl_number)
            if (X509_CRL_add1_ext_i2d(crl, NID_crl_number, crl_number, 0, 0)) RETVAL = 1;
    OUTPUT:
        RETVAL

ASN1_INTEGER *
P_X509_CRL_get_serial(crl)
        X509_CRL *crl
    INIT:
        int i;
    CODE:
        RETVAL = (ASN1_INTEGER *)X509_CRL_get_ext_d2i(crl, NID_crl_number, &i, NULL);
        if (!RETVAL || i==-1) XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

void
P_X509_CRL_add_revoked_serial_hex(crl,serial_hex,rev_time,reason_code=0,comp_time=NULL)
        X509_CRL *crl
        char * serial_hex
        ASN1_TIME *rev_time
        long reason_code
        ASN1_TIME *comp_time
    PREINIT:
        BIGNUM *bn = NULL;
        ASN1_INTEGER *sn;
        X509_REVOKED *rev;
        ASN1_ENUMERATED *rsn = NULL;
        int rv;
    PPCODE:
        rv=0;
        rev = X509_REVOKED_new();
        if (rev) {
            if (BN_hex2bn(&bn, serial_hex)) {
                sn = BN_to_ASN1_INTEGER(bn, NULL);
                if (sn) {
                    X509_REVOKED_set_serialNumber(rev, sn);
                    ASN1_INTEGER_free(sn);
                    rv = 1;
                }
                BN_free(bn);
            }
        }
        if (!rv) XSRETURN_IV(0);

        if (!rev_time) XSRETURN_IV(0);
        if (!X509_REVOKED_set_revocationDate(rev, rev_time)) XSRETURN_IV(0);

        if(reason_code) {
            rv = 0;
            rsn = ASN1_ENUMERATED_new();
            if (rsn) {
                if (ASN1_ENUMERATED_set(rsn, reason_code))
                    if (X509_REVOKED_add1_ext_i2d(rev, NID_crl_reason, rsn, 0, 0))
                        rv=1;
                ASN1_ENUMERATED_free(rsn);
            }
            if (!rv) XSRETURN_IV(0);
        }

        if(comp_time) {
            X509_REVOKED_add1_ext_i2d(rev, NID_invalidity_date, comp_time, 0, 0);
        }

        if(!X509_CRL_add0_revoked(crl, rev)) XSRETURN_IV(0);
        XSRETURN_IV(1);

#endif

X509_REQ *
X509_REQ_new()

void
X509_REQ_free(X509_REQ *x)

X509_NAME *
X509_REQ_get_subject_name(X509_REQ *x)

int
X509_REQ_set_subject_name(X509_REQ *x, X509_NAME *name)

int
X509_REQ_set_pubkey(X509_REQ *x, EVP_PKEY *pkey)

EVP_PKEY *
X509_REQ_get_pubkey(X509_REQ *x)

int
X509_REQ_sign(X509_REQ *x, EVP_PKEY *pk, const EVP_MD *md)

int
X509_REQ_verify(X509_REQ *x, EVP_PKEY *r)

int
X509_REQ_set_version(X509_REQ *x, long version)

long
X509_REQ_get_version(X509_REQ *x)

int
X509_REQ_get_attr_count(const X509_REQ *req);

int
X509_REQ_get_attr_by_NID(const X509_REQ *req, int nid, int lastpos=-1)

int
X509_REQ_get_attr_by_OBJ(const X509_REQ *req, ASN1_OBJECT *obj, int lastpos=-1)

int
X509_REQ_add1_attr_by_NID(req,nid,type,bytes)
        X509_REQ *req
        int nid
        int type
    PREINIT:
        STRLEN len;
    INPUT:
        unsigned char *bytes = (unsigned char *)SvPV(ST(3), len);
    CODE:
        RETVAL = X509_REQ_add1_attr_by_NID(req,nid,type,bytes,len);
    OUTPUT:
        RETVAL

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
#define REM21 "requires 0.9.7+"

void
P_X509_REQ_get_attr(req,n)
        X509_REQ *req
        int n
    INIT:
        X509_ATTRIBUTE * att;
        int count, i;
        ASN1_STRING * s;
	ASN1_TYPE * t;
    PPCODE:
        att = X509_REQ_get_attr(req,n);
	count = X509_ATTRIBUTE_count(att);
	for (i=0; i<count; i++) {
	    t = X509_ATTRIBUTE_get0_type(att, i);
	    s = t->value.asn1_string;
            XPUSHs(sv_2mortal(newSViv(PTR2IV(s))));
	}

#endif

int
P_X509_REQ_add_extensions(x,...)
        X509_REQ *x
    PREINIT:
        int i=1;
        int nid;
        char *data;
        X509_EXTENSION *ex;
        STACK_OF(X509_EXTENSION) *stack;
    CODE:
        if (items>1) {
            RETVAL = 1;
            stack = sk_X509_EXTENSION_new_null();
            while(i+1<items) {
                nid = SvIV(ST(i));
                data = SvPV_nolen(ST(i+1));
                i+=2;
                ex = X509V3_EXT_conf_nid(NULL, NULL, nid, data);
                if (ex)
                    sk_X509_EXTENSION_push(stack, ex);
                else
                    RETVAL = 0;
            }
            X509_REQ_add_extensions(x, stack);
            sk_X509_EXTENSION_pop_free(stack, X509_EXTENSION_free);
        }
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

int
P_X509_add_extensions(x,ca_cert,...)
        X509 *x
        X509 *ca_cert
    PREINIT:
        int i=2;
        int nid;
        char *data;
        X509_EXTENSION *ex;
        X509V3_CTX ctx;
    CODE:
        if (items>1) {
            RETVAL = 1;
            while(i+1<items) {
                nid = SvIV(ST(i));
                data = SvPV_nolen(ST(i+1));
                i+=2;
                X509V3_set_ctx(&ctx, ca_cert, x, NULL, NULL, 0);
                ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, data);
                if (ex) {
                    X509_add_ext(x,ex,-1);
                    X509_EXTENSION_free(ex);
                }
                else {
                    warn("failure during X509V3_EXT_conf_nid() for nid=%d\n", nid);
                    ERR_print_errors_fp(stderr);
                    RETVAL = 0;
                }
            }
        }
        else
            RETVAL = 0;
    OUTPUT:
            RETVAL

int
P_X509_CRL_add_extensions(x,ca_cert,...)
        X509_CRL *x
        X509 *ca_cert
    PREINIT:
        int i=2;
        int nid;
        char *data;
        X509_EXTENSION *ex;
        X509V3_CTX ctx;
    CODE:
        if (items>1) {
            RETVAL = 1;
            while(i+1<items) {
                nid = SvIV(ST(i));
                data = SvPV_nolen(ST(i+1));
                i+=2;
                X509V3_set_ctx(&ctx, ca_cert, NULL, NULL, x, 0);
                ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, data);
                if (ex) {
                    X509_CRL_add_ext(x,ex,-1);
                    X509_EXTENSION_free(ex);
                }
                else {
                    warn("failure during X509V3_EXT_conf_nid() for nid=%d\n", nid);
                    ERR_print_errors_fp(stderr);
                    RETVAL = 0;
                }
            }
        }
        else
            RETVAL = 0;
    OUTPUT:
            RETVAL

void
P_X509_copy_extensions(x509_req,x509,override=1)
        X509_REQ *x509_req
        X509 *x509
        int override
    PREINIT:
        STACK_OF(X509_EXTENSION) *exts = NULL;
        X509_EXTENSION *ext, *tmpext;
        ASN1_OBJECT *obj;
        int i, idx, ret = 1;
    PPCODE:
        if (!x509 || !x509_req) XSRETURN_IV(0);
        exts = X509_REQ_get_extensions(x509_req);
        for(i = 0; i < sk_X509_EXTENSION_num(exts); i++) {
            ext = sk_X509_EXTENSION_value(exts, i);
            obj = X509_EXTENSION_get_object(ext);
            idx = X509_get_ext_by_OBJ(x509, obj, -1);
            /* Does extension exist? */
            if (idx != -1) {
                if (override) continue; /* don't override existing extension */
                /* Delete all extensions of same type */
                do {
                    tmpext = X509_get_ext(x509, idx);
                    X509_delete_ext(x509, idx);
                    X509_EXTENSION_free(tmpext);
                    idx = X509_get_ext_by_OBJ(x509, obj, -1);
                } while (idx != -1);
            }
            if (!X509_add_ext(x509, ext, -1)) ret = 0;
        }
        sk_X509_EXTENSION_pop_free(exts, X509_EXTENSION_free);
        XSRETURN_IV(ret);

X509 *
X509_STORE_CTX_get_current_cert(x509_store_ctx)
     X509_STORE_CTX * 	x509_store_ctx

#if (OPENSSL_VERSION_NUMBER >= 0x10100005L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL) /* OpenSSL 1.1.0-pre5, LibreSSL 2.7.0 */

X509 *
X509_STORE_CTX_get0_cert(x509_store_ctx)
    X509_STORE_CTX *x509_store_ctx

#endif

STACK_OF(X509) *
X509_STORE_CTX_get1_chain(x509_store_ctx)
    X509_STORE_CTX *x509_store_ctx


int
X509_STORE_CTX_get_ex_new_index(argl,argp=NULL,new_func=NULL,dup_func=NULL,free_func=NULL)
     long argl
     void *  argp
     CRYPTO_EX_new *   new_func
     CRYPTO_EX_dup *   dup_func
     CRYPTO_EX_free *  free_func

void *
X509_STORE_CTX_get_ex_data(x509_store_ctx,idx)
     X509_STORE_CTX * x509_store_ctx
     int idx

void *
X509_STORE_CTX_get_app_data(x509_store_ctx)
     X509_STORE_CTX *  x509_store_ctx
  CODE:
  RETVAL = X509_STORE_CTX_get_ex_data(x509_store_ctx,0);
  OUTPUT:
  RETVAL

void
X509_get_fingerprint(cert,type)
		X509 * 	cert
		char *	type
	PREINIT:
		const EVP_MD *digest_tp = NULL;
		unsigned char digest[EVP_MAX_MD_SIZE];
		unsigned int dsz, k = 0;
		char text[EVP_MAX_MD_SIZE * 3 + 1];
	CODE:
#ifndef OPENSSL_NO_MD5
		if (!k && !strcmp(type,"md5")) {
		 	k = 1; digest_tp = EVP_md5();
		}
#endif
		if (!k && !strcmp(type,"sha1")) {
			k = 1; digest_tp = EVP_sha1();
		}
#if OPENSSL_VERSION_NUMBER >= 0x0090800fL
#ifndef OPENSSL_NO_SHA256
		if (!k && !strcmp(type,"sha256")) {
			k = 1; digest_tp = EVP_sha256();
		}
#endif
#endif
		if (!k && !strcmp(type,"ripemd160")) {
			k = 1; digest_tp = EVP_ripemd160();
		}
		if (!k)	/* Default digest */
			digest_tp = EVP_sha1();
		if ( digest_tp == NULL ) {
			/* Out of memory */
			XSRETURN_UNDEF;
		}
		if (!X509_digest(cert, digest_tp, digest, &dsz)) {
			/* Out of memory */
			XSRETURN_UNDEF;
		}
		text[0] = '\0';
		for(k=0; k<dsz; k++) {
			sprintf(&text[strlen(text)], "%02X:", digest[k]);
		}
		text[strlen(text)-1] = '\0';
		ST(0) = sv_newmortal();   /* Undefined to start with */
		sv_setpvn( ST(0), text, strlen(text));

void
X509_get_subjectAltNames(cert)
	X509 *      cert
	PPCODE:
	int                    i, j, count = 0;
	X509_EXTENSION         *subjAltNameExt = NULL;
	STACK_OF(GENERAL_NAME) *subjAltNameDNs = NULL;
	GENERAL_NAME           *subjAltNameDN  = NULL;
	int                    num_gnames;
	if (  (i = X509_get_ext_by_NID(cert, NID_subject_alt_name, -1)) >= 0
		&& (subjAltNameExt = X509_get_ext(cert, i))
		&& (subjAltNameDNs = X509V3_EXT_d2i(subjAltNameExt)))
	{
		num_gnames = sk_GENERAL_NAME_num(subjAltNameDNs);

		for (j = 0; j < num_gnames; j++)
                {
		     subjAltNameDN = sk_GENERAL_NAME_value(subjAltNameDNs, j);

                     switch (subjAltNameDN->type)
                     {
                     case GEN_OTHERNAME:
                         EXTEND(SP, 2);
                         count++;
                         PUSHs(sv_2mortal(newSViv(subjAltNameDN->type)));
                         PUSHs(sv_2mortal(newSVpv((const char*)ASN1_STRING_data(subjAltNameDN->d.otherName->value->value.utf8string), ASN1_STRING_length(subjAltNameDN->d.otherName->value->value.utf8string))));
                         break;

                     case GEN_EMAIL:
                     case GEN_DNS:
                     case GEN_URI:
                         EXTEND(SP, 2);
                         count++;
                         PUSHs(sv_2mortal(newSViv(subjAltNameDN->type)));
                         PUSHs(sv_2mortal(newSVpv((const char*)ASN1_STRING_data(subjAltNameDN->d.ia5), ASN1_STRING_length(subjAltNameDN->d.ia5))));
                         break;

                     case GEN_DIRNAME:
                         {
                         char * buf = X509_NAME_oneline(subjAltNameDN->d.dirn, NULL, 0);
                         EXTEND(SP, 2);
                         count++;
                         PUSHs(sv_2mortal(newSViv(subjAltNameDN->type)));
                         PUSHs(sv_2mortal(newSVpv((buf), strlen((buf)))));
                         }
                         break;

                     case GEN_RID:
                         {
			 char buf[2501]; /* Much more than what's suggested on OBJ_obj2txt manual page */
                         int len = OBJ_obj2txt(buf, sizeof(buf), subjAltNameDN->d.rid, 1);
			 if (len < 0 || len > (int)((sizeof(buf) - 1)))
			   break; /* Skip bad or overly long RID */
                         EXTEND(SP, 2);
                         count++;
                         PUSHs(sv_2mortal(newSViv(subjAltNameDN->type)));
                         PUSHs(sv_2mortal(newSVpv(buf, 0)));
                         }
                         break;

                     case GEN_IPADD:
                         EXTEND(SP, 2);
                         count++;
                         PUSHs(sv_2mortal(newSViv(subjAltNameDN->type)));
                         PUSHs(sv_2mortal(newSVpv((const char*)subjAltNameDN->d.ip->data, subjAltNameDN->d.ip->length)));
                         break;

                     }
		}
		sk_GENERAL_NAME_pop_free(subjAltNameDNs, GENERAL_NAME_free);
	}
	XSRETURN(count * 2);

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL

void
P_X509_get_crl_distribution_points(cert)
        X509 * cert
    INIT:
        GENERAL_NAMES *gnames;
        GENERAL_NAME *gn;
        STACK_OF(DIST_POINT) *points;
        DIST_POINT *p;
        int i, j;
    PPCODE:
        points = X509_get_ext_d2i(cert, NID_crl_distribution_points, NULL, NULL);
        if (points)
        for (i = 0; i < sk_DIST_POINT_num(points); i++) {
            p = sk_DIST_POINT_value(points, i);
            if (!p->distpoint)
                continue;
            if (p->distpoint->type == 0) {
                /* full name */
                gnames = p->distpoint->name.fullname;
                for (j = 0; j < sk_GENERAL_NAME_num(gnames); j++) {
                    gn = sk_GENERAL_NAME_value(gnames, j);

                    if (gn->type == GEN_URI) {
                        XPUSHs(sv_2mortal(newSVpv((char*)ASN1_STRING_data(gn->d.ia5),ASN1_STRING_length(gn->d.ia5))));
                    }
                }
            }
            else {
                /* relative name - not supported */
                /* XXX-TODO: the code below is just an idea; do not enable it without proper test case
                BIO *bp;
                char *buf;
                int n;
                X509_NAME ntmp;
                ntmp.entries = p->distpoint->name.relativename;
                bp = BIO_new(BIO_s_mem());
                if (bp) {
                    X509_NAME_print_ex(bp, &ntmp, 0, XN_FLAG_RFC2253);
                    n = BIO_ctrl_pending(bp);
                    New(0, buf, n, char);
                    if (buf) {
                        j = BIO_read(bp,buf,n);
                        if (j>=0 && j<=n) XPUSHs(sv_2mortal(newSVpvn(buf,j)));
                        Safefree(buf);
                    }
                    BIO_free(bp);
                }
                */
            }
        }

void
P_X509_get_ocsp_uri(cert)
	X509 * cert
    PPCODE:
	AUTHORITY_INFO_ACCESS *info;
	int i;
	info = X509_get_ext_d2i(cert, NID_info_access, NULL, NULL);
	if (!info) XSRETURN_UNDEF;

	for (i = 0; i < sk_ACCESS_DESCRIPTION_num(info); i++) {
	    ACCESS_DESCRIPTION *ad = sk_ACCESS_DESCRIPTION_value(info, i);
	    if (OBJ_obj2nid(ad->method) == NID_ad_OCSP
		&& ad->location->type == GEN_URI) {
		XPUSHs(sv_2mortal(newSVpv(
		    (char*)ASN1_STRING_data(ad->location->d.uniformResourceIdentifier),
		    ASN1_STRING_length(ad->location->d.uniformResourceIdentifier)
		)));
		if (GIMME == G_SCALAR) break; /* get only first */
	    }
	}


void
P_X509_get_ext_key_usage(cert,format=0)
        X509 * cert
        int format
    PREINIT:
        EXTENDED_KEY_USAGE *extusage;
        int i, nid;
        char buffer[100]; /* openssl doc: a buffer length of 80 should be more than enough to handle any OID encountered in practice */
        ASN1_OBJECT *o;
    PPCODE:
        extusage = X509_get_ext_d2i(cert, NID_ext_key_usage, NULL, NULL);
        for(i = 0; i < sk_ASN1_OBJECT_num(extusage); i++) {
           o = sk_ASN1_OBJECT_value(extusage,i);
           nid = OBJ_obj2nid(o);
           OBJ_obj2txt(buffer, sizeof(buffer)-1, o, 1);
           if(format==0)
               XPUSHs(sv_2mortal(newSVpv(buffer,0)));          /* format 0: oid */
           else if(format==1 && nid>0)
               XPUSHs(sv_2mortal(newSViv(nid)));               /* format 1: nid */
           else if(format==2 && nid>0)
               XPUSHs(sv_2mortal(newSVpv(OBJ_nid2sn(nid),0))); /* format 2: shortname */
           else if(format==3 && nid>0)
               XPUSHs(sv_2mortal(newSVpv(OBJ_nid2ln(nid),0))); /* format 3: longname */
        }

#endif

void
P_X509_get_key_usage(cert)
        X509 * cert
    INIT:
        ASN1_BIT_STRING * u;
    PPCODE:
        u = X509_get_ext_d2i(cert, NID_key_usage, NULL, NULL);
        if (u) {
            if (ASN1_BIT_STRING_get_bit(u,0)) XPUSHs(sv_2mortal(newSVpv("digitalSignature",0)));
            if (ASN1_BIT_STRING_get_bit(u,1)) XPUSHs(sv_2mortal(newSVpv("nonRepudiation",0)));
            if (ASN1_BIT_STRING_get_bit(u,2)) XPUSHs(sv_2mortal(newSVpv("keyEncipherment",0)));
            if (ASN1_BIT_STRING_get_bit(u,3)) XPUSHs(sv_2mortal(newSVpv("dataEncipherment",0)));
            if (ASN1_BIT_STRING_get_bit(u,4)) XPUSHs(sv_2mortal(newSVpv("keyAgreement",0)));
            if (ASN1_BIT_STRING_get_bit(u,5)) XPUSHs(sv_2mortal(newSVpv("keyCertSign",0)));
            if (ASN1_BIT_STRING_get_bit(u,6)) XPUSHs(sv_2mortal(newSVpv("cRLSign",0)));
            if (ASN1_BIT_STRING_get_bit(u,7)) XPUSHs(sv_2mortal(newSVpv("encipherOnly",0)));
            if (ASN1_BIT_STRING_get_bit(u,8)) XPUSHs(sv_2mortal(newSVpv("decipherOnly",0)));
        }

void
P_X509_get_netscape_cert_type(cert)
        X509 * cert
    INIT:
        ASN1_BIT_STRING * u;
    PPCODE:
        u = X509_get_ext_d2i(cert, NID_netscape_cert_type, NULL, NULL);
        if (u) {
            if (ASN1_BIT_STRING_get_bit(u,0)) XPUSHs(sv_2mortal(newSVpv("client",0)));
            if (ASN1_BIT_STRING_get_bit(u,1)) XPUSHs(sv_2mortal(newSVpv("server",0)));
            if (ASN1_BIT_STRING_get_bit(u,2)) XPUSHs(sv_2mortal(newSVpv("email",0)));
            if (ASN1_BIT_STRING_get_bit(u,3)) XPUSHs(sv_2mortal(newSVpv("objsign",0)));
            if (ASN1_BIT_STRING_get_bit(u,4)) XPUSHs(sv_2mortal(newSVpv("reserved",0)));
            if (ASN1_BIT_STRING_get_bit(u,5)) XPUSHs(sv_2mortal(newSVpv("sslCA",0)));
            if (ASN1_BIT_STRING_get_bit(u,6)) XPUSHs(sv_2mortal(newSVpv("emailCA",0)));
            if (ASN1_BIT_STRING_get_bit(u,7)) XPUSHs(sv_2mortal(newSVpv("objCA",0)));
        }

int
X509_get_ext_by_NID(x,nid,loc=-1)
	X509* x
	int nid
	int loc

X509_EXTENSION *
X509_get_ext(x,loc)
	X509* x
	int loc

int
X509_EXTENSION_get_critical(X509_EXTENSION *ex)

ASN1_OCTET_STRING *
X509_EXTENSION_get_data(X509_EXTENSION *ne)

ASN1_OBJECT *
X509_EXTENSION_get_object(X509_EXTENSION *ex)

int
X509_get_ext_count(X509 *x)

int
X509_CRL_get_ext_count(X509_CRL *x)

int
X509_CRL_get_ext_by_NID(x,ni,loc=-1)
        X509_CRL* x
        int ni
        int loc

X509_EXTENSION *
X509_CRL_get_ext(x,loc)
   X509_CRL* x
   int loc

void
X509V3_EXT_print(ext,flags=0,utf8_decode=0)
        X509_EXTENSION * ext
        unsigned long flags
        int utf8_decode
    PREINIT:
        BIO * bp;
        char * buf;
        int i, n;
        int indent=0;
    CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp) {
            if(X509V3_EXT_print(bp,ext,flags,indent)) {
                n = BIO_ctrl_pending(bp);
                New(0, buf, n, char);
                if (buf) {
                    i = BIO_read(bp,buf,n);
                    if (i>=0 && i<=n) {
                        sv_setpvn(ST(0), buf, i);
                        if (utf8_decode) sv_utf8_decode(ST(0));
                    }
                    Safefree(buf);
                }
            }
            BIO_free(bp);
        }

void *
X509V3_EXT_d2i(ext)
	X509_EXTENSION *ext

X509_STORE_CTX *
X509_STORE_CTX_new()

int
X509_STORE_CTX_init(ctx, store=NULL, x509=NULL, chain=NULL)
     X509_STORE_CTX * ctx
     X509_STORE * store
     X509 * x509
     STACK_OF(X509) * chain

void
X509_STORE_CTX_free(ctx)
     X509_STORE_CTX * ctx

int
X509_verify_cert(x509_store_ctx)
     X509_STORE_CTX * 	x509_store_ctx
    
int
X509_STORE_CTX_get_error(x509_store_ctx)
     X509_STORE_CTX * 	x509_store_ctx

int
X509_STORE_CTX_get_error_depth(x509_store_ctx)
     X509_STORE_CTX * 	x509_store_ctx

int
X509_STORE_CTX_set_ex_data(x509_store_ctx,idx,data)
     X509_STORE_CTX *   x509_store_ctx
     int idx
     void * data

int
X509_STORE_CTX_set_app_data(x509_store_ctx,arg)
     X509_STORE_CTX *  x509_store_ctx
     char *  arg
  CODE:
  RETVAL = X509_STORE_CTX_set_ex_data(x509_store_ctx,0,arg);
  OUTPUT:
  RETVAL

void
X509_STORE_CTX_set_error(x509_store_ctx,s)
     X509_STORE_CTX * x509_store_ctx
     int s

void
X509_STORE_CTX_set_cert(x509_store_ctx,x)
     X509_STORE_CTX * x509_store_ctx
     X509 * x

X509_STORE *
X509_STORE_new()

void
X509_STORE_free(store)
    X509_STORE * store

X509_LOOKUP *
X509_STORE_add_lookup(store, method)
    X509_STORE * store
    X509_LOOKUP_METHOD * method

int
X509_STORE_add_cert(ctx, x)
    X509_STORE *ctx
    X509 *x

int
X509_STORE_add_crl(ctx, x)
    X509_STORE *ctx
    X509_CRL *x

#if OPENSSL_VERSION_NUMBER >= 0x0090800fL

void
X509_STORE_set_flags(ctx, flags)
    X509_STORE *ctx
    long flags

void
X509_STORE_set_purpose(ctx, purpose)
    X509_STORE *ctx
    int purpose

void
X509_STORE_set_trust(ctx, trust)
    X509_STORE *ctx
    int trust

int
X509_STORE_set1_param(ctx, pm)
    X509_STORE *ctx
    X509_VERIFY_PARAM *pm

#endif

X509_LOOKUP_METHOD *
X509_LOOKUP_hash_dir()

void
X509_LOOKUP_add_dir(lookup, dir, type)
    X509_LOOKUP * lookup
    char * dir
    int type

int
X509_load_cert_file(ctx, file, type)
    X509_LOOKUP *ctx
    char *file
    int type

int
X509_load_crl_file(ctx, file, type)
    X509_LOOKUP *ctx
    char *file
    int type

int
X509_load_cert_crl_file(ctx, file, type)
    X509_LOOKUP *ctx
    char *file
    int type

const char *
X509_verify_cert_error_string(n)
    long n

ASN1_INTEGER *
ASN1_INTEGER_new()

void
ASN1_INTEGER_free(ASN1_INTEGER *i)

int
ASN1_INTEGER_set(ASN1_INTEGER *i, long val)

long
ASN1_INTEGER_get(ASN1_INTEGER *a)

void
P_ASN1_INTEGER_set_hex(i,str)
        ASN1_INTEGER * i
        char * str
    INIT:
        BIGNUM *bn;
        int rv = 1;
    PPCODE:
        bn = BN_new();
        if (!BN_hex2bn(&bn, str)) XSRETURN_IV(0);
        if (!BN_to_ASN1_INTEGER(bn, i)) rv = 0;
        BN_free(bn);
        XSRETURN_IV(rv);

void
P_ASN1_INTEGER_set_dec(i,str)
        ASN1_INTEGER * i
        char * str
    INIT:
        BIGNUM *bn;
        int rv = 1;
    PPCODE:
        bn = BN_new();
        if (!BN_dec2bn(&bn, str)) XSRETURN_IV(0);
        if (!BN_to_ASN1_INTEGER(bn, i)) rv = 0;
        BN_free(bn);
        XSRETURN_IV(rv);

void
P_ASN1_INTEGER_get_hex(i)
        ASN1_INTEGER * i
    INIT:
        BIGNUM *bn;
        char *result;
    PPCODE:
        bn = BN_new();
        if (!bn) XSRETURN_UNDEF;
        ASN1_INTEGER_to_BN(i, bn);
        result = BN_bn2hex(bn);
        BN_free(bn);
        if (!result) XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv((const char*)result, strlen(result))));
        OPENSSL_free(result);

void
P_ASN1_INTEGER_get_dec(i)
        ASN1_INTEGER * i
    INIT:
        BIGNUM *bn;
        char *result;
    PPCODE:
        bn = BN_new();
        if (!bn) XSRETURN_UNDEF;
        ASN1_INTEGER_to_BN(i, bn);
        result = BN_bn2dec(bn);
        BN_free(bn);
        if (!result) XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv((const char*)result, strlen(result))));
        OPENSSL_free(result);

void
P_ASN1_STRING_get(s,utf8_decode=0)
        ASN1_STRING * s
        int utf8_decode
    PREINIT:
        SV * u8;
    PPCODE:
        u8 = newSVpv((const char*)ASN1_STRING_data(s), ASN1_STRING_length(s));
        if (utf8_decode) sv_utf8_decode(u8);
        XPUSHs(sv_2mortal(u8));

ASN1_TIME *
X509_get_notBefore(cert)
     X509 *	cert

ASN1_TIME *
X509_get_notAfter(cert)
     X509 *	cert

ASN1_TIME *
X509_gmtime_adj(s, adj)
     ASN1_TIME * s
     long adj

ASN1_TIME *
ASN1_TIME_set(s,t)
     ASN1_TIME *s
     time_t t

void
ASN1_TIME_free(s)
     ASN1_TIME *s

time_t
ASN1_TIME_timet(s)
     ASN1_TIME *s
     CODE:
     RETVAL = ASN1_TIME_timet(s,NULL);
     OUTPUT:
     RETVAL

ASN1_TIME *
ASN1_TIME_new()

void
P_ASN1_TIME_put2string(tm)
     ASN1_TIME * tm
     PREINIT:
     BIO *bp=NULL;
     int i=0;
     char buffer[256];
     ALIAS:
     P_ASN1_UTCTIME_put2string = 1
     CODE:
     ST(0) = sv_newmortal(); /* undef retval to start with */
     if (tm) {
         bp = BIO_new(BIO_s_mem());
         if (bp) {
             ASN1_TIME_print(bp,tm);
             i = BIO_read(bp,buffer,255);
             buffer[i] = '\0';
             if (i>0)
                 sv_setpvn(ST(0), buffer, i);
             BIO_free(bp);
         }
     }

#if OPENSSL_VERSION_NUMBER >= 0x0090705f
#define REM15 "NOTE: requires 0.9.7e+"

void
P_ASN1_TIME_get_isotime(tm)
     ASN1_TIME *tm
     PREINIT:
     ASN1_GENERALIZEDTIME *tmp = NULL;
     char buf[256];
     CODE:
     buf[0] = '\0';
     /* ASN1_TIME_to_generalizedtime is buggy on pre-0.9.7e */
     ASN1_TIME_to_generalizedtime(tm,&tmp);
     if (tmp) {
       if (ASN1_GENERALIZEDTIME_check(tmp)) {
         if (strlen((char*)tmp->data)>=14 && strlen((char*)tmp->data)<200) {
           strcpy (buf,"yyyy-mm-ddThh:mm:ss");
           strncpy(buf,   (char*)tmp->data,   4);
           strncpy(buf+5, (char*)tmp->data+4, 2);
           strncpy(buf+8, (char*)tmp->data+6, 2);
           strncpy(buf+11,(char*)tmp->data+8, 2);
           strncpy(buf+14,(char*)tmp->data+10,2);
           strncpy(buf+17,(char*)tmp->data+12,2);
           if (strlen((char*)tmp->data)>14) strcat(buf+19,(char*)tmp->data+14);
         }
       }
       ASN1_GENERALIZEDTIME_free(tmp);
     }
     ST(0) = sv_newmortal();
     sv_setpv(ST(0), buf);

void
P_ASN1_TIME_set_isotime(tm,str)
     ASN1_TIME *tm
     const char *str
     PREINIT:
     ASN1_TIME t;
     char buf[256];
     int i,rv;
     CODE:
     if (!tm) XSRETURN_UNDEF;
     /* we support only "2012-03-22T23:55:33" or "2012-03-22T23:55:33Z" or "2012-03-22T23:55:33<timezone>" */
     if (strlen(str) < 19) XSRETURN_UNDEF;
     for (i=0;  i<4;  i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     for (i=5;  i<7;  i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     for (i=8;  i<10; i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     for (i=11; i<13; i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     for (i=14; i<16; i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     for (i=17; i<19; i++) if ((str[i] > '9') || (str[i] < '0')) XSRETURN_UNDEF;
     strncpy(buf,    str,    4);
     strncpy(buf+4,  str+5,  2);
     strncpy(buf+6,  str+8,  2);
     strncpy(buf+8,  str+11, 2);
     strncpy(buf+10, str+14, 2);
     strncpy(buf+12, str+17, 2);
     buf[14] = '\0';
     if (strlen(str)>19 && strlen(str)<200) strcat(buf,str+19);

     /* WORKAROUND: ASN1_TIME_set_string() not available in 0.9.8 !!!*/
     /* in 1.0.0 we would simply: rv = ASN1_TIME_set_string(tm,buf); */
     t.length = strlen(buf);
     t.data = (unsigned char *)buf;
     t.flags = 0;
     t.type = V_ASN1_UTCTIME;
     if (!ASN1_TIME_check(&t)) {
        t.type = V_ASN1_GENERALIZEDTIME;
        if (!ASN1_TIME_check(&t)) XSRETURN_UNDEF;
     }
     tm->type = t.type;
     tm->flags = t.flags;
     if (!ASN1_STRING_set(tm,t.data,t.length)) XSRETURN_UNDEF;
     rv = 1;

     /* end of ASN1_TIME_set_string() reimplementation */

     ST(0) = sv_newmortal();
     sv_setiv(ST(0), rv); /* 1 = success, undef = failure */

#endif

int
EVP_PKEY_copy_parameters(to,from)
     EVP_PKEY *		to
     EVP_PKEY * 	from

EVP_PKEY *
EVP_PKEY_new()

void
EVP_PKEY_free(EVP_PKEY *pkey)

int
EVP_PKEY_assign_RSA(EVP_PKEY *pkey, RSA *key)

int
EVP_PKEY_bits(EVP_PKEY *pkey)

int
EVP_PKEY_size(EVP_PKEY *pkey)

#if OPENSSL_VERSION_NUMBER >= 0x1000000fL

int
EVP_PKEY_id(const EVP_PKEY *pkey)

#endif

void
PEM_get_string_X509(x509)
        X509 * x509
     PREINIT:
        BIO *bp;
        int i, n;
        char *buf;
     CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp && x509) {
            PEM_write_bio_X509(bp,x509);
            n = BIO_ctrl_pending(bp);
            New(0, buf, n, char);
            if (buf) {
                i = BIO_read(bp,buf,n);
                if (i>=0 && i<=n) sv_setpvn(ST(0), buf, i);
                Safefree(buf);
            }
            BIO_free(bp);
        }

void
PEM_get_string_X509_REQ(x509_req)
        X509_REQ * x509_req
    PREINIT:
        BIO *bp;
        int i, n;
        char *buf;
    CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp && x509_req) {
            PEM_write_bio_X509_REQ(bp,x509_req);
            n = BIO_ctrl_pending(bp);
            New(0, buf, n, char);
            if (buf) {
                i = BIO_read(bp,buf,n);
                if (i>=0 && i<=n) sv_setpvn(ST(0), buf, i);
                Safefree(buf);
            }
            BIO_free(bp);
        }

void
PEM_get_string_X509_CRL(x509_crl)
        X509_CRL * x509_crl
    PREINIT:
        BIO *bp;
        int i, n;
        char *buf;
    CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp && x509_crl) {
            PEM_write_bio_X509_CRL(bp,x509_crl);
            n = BIO_ctrl_pending(bp);
            New(0, buf, n, char);
            if (buf) {
                i = BIO_read(bp,buf,n);
                if (i>=0 && i<=n) sv_setpvn(ST(0), buf, i);
                Safefree(buf);
            }
            BIO_free(bp);
        }

void
PEM_get_string_PrivateKey(pk,passwd=NULL,enc_alg=NULL)
        EVP_PKEY * pk
        char * passwd
        const EVP_CIPHER * enc_alg
    PREINIT:
        BIO *bp;
        int i, n;
        char *buf;
        size_t passwd_len = 0;
        pem_password_cb * cb = NULL;
        void * u = NULL;
    CODE:
        ST(0) = sv_newmortal(); /* undef to start with */
        bp = BIO_new(BIO_s_mem());
        if (bp && pk) {
            if (passwd) passwd_len = strlen(passwd);
            if (passwd_len>0) {
                /* encrypted key */
                if (!enc_alg)
                    PEM_write_bio_PrivateKey(bp,pk,EVP_des_cbc(),(unsigned char *)passwd,passwd_len,cb,u);
                else
                    PEM_write_bio_PrivateKey(bp,pk,enc_alg,(unsigned char *)passwd,passwd_len,cb,u);
            }
            else {
                /* unencrypted key */
                PEM_write_bio_PrivateKey(bp,pk,NULL,(unsigned char *)passwd,passwd_len,cb,u);
            }
            n = BIO_ctrl_pending(bp);
            New(0, buf, n, char);
            if (buf) {
                i = BIO_read(bp,buf,n);
                if (i>=0 && i<=n) sv_setpvn(ST(0), buf, i);
                Safefree(buf);
            }
            BIO_free(bp);
        }

int
CTX_use_PKCS12_file(ctx, file, password=NULL)
        SSL_CTX *ctx
        char *file
        char *password
    PREINIT:
        PKCS12 *p12;
        EVP_PKEY *private_key;
        X509 *certificate;
        FILE *fp;
    CODE:
        RETVAL = 0;
        if ((fp = fopen (file, "rb"))) {
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
            OPENSSL_add_all_algorithms_noconf();
#else
            OpenSSL_add_all_algorithms();
#endif
            if ((p12 = d2i_PKCS12_fp(fp, NULL))) {
                if (PKCS12_parse(p12, password, &private_key, &certificate, NULL)) {
                    if (private_key) {
                        if (SSL_CTX_use_PrivateKey(ctx, private_key)) RETVAL = 1;
                        EVP_PKEY_free(private_key);
                    }
                    if (certificate) {
                        if (SSL_CTX_use_certificate(ctx, certificate)) RETVAL = 1;
                        X509_free(certificate);
                    }
                }
                PKCS12_free(p12);
            }
            if (!RETVAL) ERR_print_errors_fp(stderr);
            fclose(fp);
        }
    OUTPUT:
        RETVAL

void
P_PKCS12_load_file(file, load_chain=0, password=NULL)
        char *file
        int load_chain
        char *password
    PREINIT:
        PKCS12 *p12;
        EVP_PKEY *private_key = NULL;
        X509 *certificate = NULL;
        STACK_OF(X509) *cachain = NULL;
        X509 *x;
        FILE *fp;
        int i, result;
    PPCODE:
        if ((fp = fopen (file, "rb"))) {
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
            OPENSSL_add_all_algorithms_noconf();
#else
            OpenSSL_add_all_algorithms();
#endif
            if ((p12 = d2i_PKCS12_fp(fp, NULL))) {
                if(load_chain)
                    result= PKCS12_parse(p12, password, &private_key, &certificate, &cachain);
                else
                    result= PKCS12_parse(p12, password, &private_key, &certificate, NULL);
                if (result) {
                    if (private_key)
                        XPUSHs(sv_2mortal(newSViv(PTR2IV(private_key))));
                    else
                        XPUSHs(sv_2mortal(newSVpv(NULL,0))); /* undef */
                    if (certificate)
                        XPUSHs(sv_2mortal(newSViv(PTR2IV(certificate))));
                    else
                        XPUSHs(sv_2mortal(newSVpv(NULL,0))); /* undef */
                    if (cachain) {
                        for (i=0; i<sk_X509_num(cachain); i++) {
                            x = sk_X509_value(cachain, i);
                            XPUSHs(sv_2mortal(newSViv(PTR2IV(x))));
                        }
                        sk_X509_free(cachain);
                    }
                }
                PKCS12_free(p12);
            }
            fclose(fp);
        }

#ifndef OPENSSL_NO_MD2

void
MD2(data)
	PREINIT:
	STRLEN len;
	unsigned char md[MD2_DIGEST_LENGTH];
	unsigned char * ret;
	INPUT:
	unsigned char* data = (unsigned char *) SvPV( ST(0), len);
	CODE:
	ret = MD2(data,len,md);
	if (ret!=NULL) {
		XSRETURN_PVN((char *) md, MD2_DIGEST_LENGTH);
	} else {
		XSRETURN_UNDEF;
	}

#endif

#ifndef OPENSSL_NO_MD4

void
MD4(data)
	PREINIT:
	STRLEN len;
	unsigned char md[MD4_DIGEST_LENGTH];
	INPUT:
	unsigned char* data = (unsigned char *) SvPV( ST(0), len );
	CODE:
	if (MD4(data,len,md)) {
		XSRETURN_PVN((char *) md, MD4_DIGEST_LENGTH);
	} else {
		XSRETURN_UNDEF;
	}

#endif

#ifndef OPENSSL_NO_MD5

void
MD5(data)
     PREINIT:
     STRLEN len;
     unsigned char md[MD5_DIGEST_LENGTH];
     INPUT:
     unsigned char *  data = (unsigned char *) SvPV( ST(0), len);
     CODE:
     if (MD5(data,len,md)) {
	  XSRETURN_PVN((char *) md, MD5_DIGEST_LENGTH);
     } else {
	  XSRETURN_UNDEF;
     }

#endif

#if OPENSSL_VERSION_NUMBER >= 0x00905000L

void
RIPEMD160(data)
     PREINIT:
     STRLEN len;
     unsigned char md[RIPEMD160_DIGEST_LENGTH];
     INPUT:
     unsigned char *  data = (unsigned char *) SvPV( ST(0), len);
     CODE:
     if (RIPEMD160(data,len,md)) {
	  XSRETURN_PVN((char *) md, RIPEMD160_DIGEST_LENGTH);
     } else {
	  XSRETURN_UNDEF;
     }

#endif

#if !defined(OPENSSL_NO_SHA)

void
SHA1(data)
     PREINIT:
     STRLEN len;
     unsigned char md[SHA_DIGEST_LENGTH];
     INPUT:
     unsigned char *  data = (unsigned char *) SvPV( ST(0), len);
     CODE:
     if (SHA1(data,len,md)) {
	  XSRETURN_PVN((char *) md, SHA_DIGEST_LENGTH);
     } else {
	  XSRETURN_UNDEF;
     }

#endif
#if !defined(OPENSSL_NO_SHA256) && OPENSSL_VERSION_NUMBER >= 0x0090800fL

void
SHA256(data)
     PREINIT:
     STRLEN len;
     unsigned char md[SHA256_DIGEST_LENGTH];
     INPUT:
     unsigned char *  data = (unsigned char *) SvPV( ST(0), len);
     CODE:
     if (SHA256(data,len,md)) {
	  XSRETURN_PVN((char *) md, SHA256_DIGEST_LENGTH);
     } else {
	  XSRETURN_UNDEF;
     }

#endif
#if !defined(OPENSSL_NO_SHA512) && OPENSSL_VERSION_NUMBER >= 0x0090800fL

void
SHA512(data)
     PREINIT:
     STRLEN len;
     unsigned char md[SHA512_DIGEST_LENGTH];
     INPUT:
     unsigned char *  data = (unsigned char *) SvPV( ST(0), len);
     CODE:
     if (SHA512(data,len,md)) {
	  XSRETURN_PVN((char *) md, SHA512_DIGEST_LENGTH);
     } else {
	  XSRETURN_UNDEF;
     }

#endif

#ifndef OPENSSL_NO_SSL2
#if OPENSSL_VERSION_NUMBER < 0x10000000L

const SSL_METHOD *
SSLv2_method()

#endif
#endif

#ifndef OPENSSL_NO_SSL3

const SSL_METHOD *
SSLv3_method()

#endif

const SSL_METHOD *
SSLv23_method()

const SSL_METHOD *
SSLv23_server_method()

const SSL_METHOD *
SSLv23_client_method()

const SSL_METHOD *
TLSv1_method()

const SSL_METHOD *
TLSv1_server_method()

const SSL_METHOD *
TLSv1_client_method()

#ifdef SSL_TXT_TLSV1_1

const SSL_METHOD *
TLSv1_1_method()

const SSL_METHOD *
TLSv1_1_server_method()

const SSL_METHOD *
TLSv1_1_client_method()

#endif

#ifdef SSL_TXT_TLSV1_2

const SSL_METHOD *
TLSv1_2_method()

const SSL_METHOD *
TLSv1_2_server_method()

const SSL_METHOD *
TLSv1_2_client_method()

#endif


#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x20020002L)

const SSL_METHOD *
TLS_method()

const SSL_METHOD *
TLS_server_method()

const SSL_METHOD *
TLS_client_method()

#endif /* OpenSSL 1.1.0 or LibreSSL 2.2.2 */


#if  (OPENSSL_VERSION_NUMBER >= 0x10100002L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2060000fL)

int
SSL_CTX_set_min_proto_version(ctx, version)
     SSL_CTX *  ctx
     int        version

int
SSL_CTX_set_max_proto_version(ctx, version)
     SSL_CTX *  ctx
     int        version

int
SSL_set_min_proto_version(ssl, version)
     SSL *  ssl
     int    version

int
SSL_set_max_proto_version(ssl, version)
     SSL *  ssl
     int    version

#endif /* OpenSSL 1.1.0-pre2 or LibreSSL 2.6.0 */


#if OPENSSL_VERSION_NUMBER >= 0x1010007fL && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_CTX_get_min_proto_version(ctx)
     SSL_CTX *  ctx

int
SSL_CTX_get_max_proto_version(ctx)
     SSL_CTX *  ctx

int
SSL_get_min_proto_version(ssl)
     SSL *  ssl

int
SSL_get_max_proto_version(ssl)
     SSL *  ssl

#endif /* OpenSSL 1.1.0g */


#if OPENSSL_VERSION_NUMBER < 0x10000000L

int
SSL_set_ssl_method(ssl, method)
     SSL *         ssl
     SSL_METHOD *  method

#else

int
SSL_set_ssl_method(ssl, method)
     SSL *               ssl
     const SSL_METHOD *  method

#endif

const SSL_METHOD *
SSL_get_ssl_method(ssl)
     SSL *          ssl

#define REM_AUTOMATICALLY_GENERATED_1_09

BIO *
BIO_new_buffer_ssl_connect(ctx)
     SSL_CTX *	ctx

BIO *
BIO_new_file(filename,mode)
     char * filename
     char * mode

BIO *
BIO_new_ssl(ctx,client)
     SSL_CTX *	ctx
     int 	client

BIO *
BIO_new_ssl_connect(ctx)
     SSL_CTX *	ctx

BIO *
BIO_new(type)
     BIO_METHOD * type;

int
BIO_free(bio)
     BIO * bio;

void
BIO_read(s,max=32768)
	BIO *   s
	int max
	PREINIT:
	char *buf = NULL;
	int got;
	CODE:
	New(0, buf, max, char);
	ST(0) = sv_newmortal();   /* Undefined to start with */
	if ((got = BIO_read(s, buf, max)) >= 0)
		sv_setpvn( ST(0), buf, got);
	Safefree(buf);

int
BIO_write(s,buf)
     BIO *   s
     PREINIT:
     STRLEN len;
     INPUT:
     char *  buf = SvPV( ST(1), len);
     CODE:
     RETVAL = BIO_write (s, buf, (int)len);
     OUTPUT:
     RETVAL

int
BIO_eof(s)
     BIO *   s

int
BIO_pending(s)
     BIO *   s

int
BIO_wpending(s)
     BIO *   s

int
BIO_ssl_copy_session_id(to,from)
     BIO *	to
     BIO *	from

void
BIO_ssl_shutdown(ssl_bio)
     BIO *	ssl_bio

int
SSL_add_client_CA(ssl,x)
     SSL *	ssl
     X509 *	x

const char *
SSL_alert_desc_string(value)
     int 	value

const char *
SSL_alert_desc_string_long(value)
     int 	value

const char *
SSL_alert_type_string(value)
     int 	value

const char *
SSL_alert_type_string_long(value)
     int 	value

long
SSL_callback_ctrl(ssl,i,fp)
     SSL *  ssl
     int    i
     callback_no_ret * fp

int
SSL_check_private_key(ctx)
     SSL *	ctx

# /* buf and size were required with Net::SSLeay 1.88 and earlier. */
# /* With OpenSSL 0.9.8l and older compile can warn about discarded const. */
void
SSL_CIPHER_description(const SSL_CIPHER *cipher, char *unused_buf=NULL, int unused_size=0)
    PREINIT:
        char *description;
        char buf[512];
    PPCODE:
        description = SSL_CIPHER_description(cipher, buf, sizeof(buf));
        if(description == NULL) {
            XSRETURN_EMPTY;
        }
        XPUSHs(sv_2mortal(newSVpv(description, 0)));

const char *
SSL_CIPHER_get_name(const SSL_CIPHER *c)

int
SSL_CIPHER_get_bits(c, ...)
        const SSL_CIPHER *      c
    CODE:
        int alg_bits;
        RETVAL = SSL_CIPHER_get_bits(c, &alg_bits);
        if (items > 2) croak("SSL_CIPHER_get_bits: Need to call with one or two parameters");
        if (items > 1) sv_setsv(ST(1), sv_2mortal(newSViv(alg_bits)));
    OUTPUT:
        RETVAL

const char *
SSL_CIPHER_get_version(const SSL_CIPHER *cipher)

#ifndef OPENSSL_NO_COMP

int
SSL_COMP_add_compression_method(id,cm)
     int 	id
     COMP_METHOD *	cm

#endif

int
SSL_CTX_add_client_CA(ctx,x)
     SSL_CTX *	ctx
     X509 *	x

long
SSL_CTX_callback_ctrl(ctx,i,fp)
     SSL_CTX *  ctx
     int        i
     callback_no_ret * fp

int
SSL_CTX_check_private_key(ctx)
     SSL_CTX *	ctx

void *
SSL_CTX_get_ex_data(ssl,idx)
     SSL_CTX *	ssl
     int 	idx

int
SSL_CTX_get_quiet_shutdown(ctx)
     SSL_CTX *	ctx

long
SSL_CTX_get_timeout(ctx)
     SSL_CTX *	ctx

int
SSL_CTX_get_verify_depth(ctx)
     SSL_CTX *	ctx

int
SSL_CTX_get_verify_mode(ctx)
     SSL_CTX *	ctx

void
SSL_CTX_set_cert_store(ctx,store)
     SSL_CTX *     ctx
     X509_STORE *  store

X509_STORE *
SSL_CTX_get_cert_store(ctx)
     SSL_CTX *     ctx

void
SSL_CTX_set_cert_verify_callback(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
        SV * data
    CODE: 
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_cert_verify_callback(ctx, NULL, NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_cert_verify_cb!!func", NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_cert_verify_cb!!data", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ctx_cert_verify_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "ssleay_ctx_cert_verify_cb!!data", newSVsv(data));
#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
            SSL_CTX_set_cert_verify_callback(ctx, ssleay_ctx_cert_verify_cb_invoke, ctx);
#else
            SSL_CTX_set_cert_verify_callback(ctx, ssleay_ctx_cert_verify_cb_invoke, (char*)ctx);
#endif
        }

X509_NAME_STACK *
SSL_CTX_get_client_CA_list(ctx)
	SSL_CTX *ctx

void
SSL_CTX_set_client_CA_list(ctx,list)
     SSL_CTX *	ctx
     X509_NAME_STACK * list

void
SSL_CTX_set_default_passwd_cb(ctx,callback=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_default_passwd_cb(ctx, NULL);
            SSL_CTX_set_default_passwd_cb_userdata(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_passwd_cb!!func", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ctx_passwd_cb!!func", newSVsv(callback));
            SSL_CTX_set_default_passwd_cb_userdata(ctx, (void*)ctx);
            SSL_CTX_set_default_passwd_cb(ctx, &ssleay_ctx_passwd_cb_invoke);
        }

void 
SSL_CTX_set_default_passwd_cb_userdata(ctx,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * data
    CODE:
        /* SSL_CTX_set_default_passwd_cb_userdata is set in SSL_CTX_set_default_passwd_cb */
        if (data==NULL || !SvOK(data)) {
            cb_data_advanced_put(ctx, "ssleay_ctx_passwd_cb!!data", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ctx_passwd_cb!!data", newSVsv(data));
        }

int
SSL_CTX_set_ex_data(ssl,idx,data)
     SSL_CTX *	ssl
     int 	idx
     void *	data

int
SSL_CTX_set_purpose(s,purpose)
     SSL_CTX *	s
     int 	purpose

void
SSL_CTX_set_quiet_shutdown(ctx,mode)
     SSL_CTX *	ctx
     int 	mode

#if OPENSSL_VERSION_NUMBER < 0x10000000L

int
SSL_CTX_set_ssl_version(ctx,meth)
     SSL_CTX *	ctx
     SSL_METHOD *	meth

#else

int
SSL_CTX_set_ssl_version(ctx,meth)
     SSL_CTX *	ctx
     const SSL_METHOD *	meth

#endif

long
SSL_CTX_set_timeout(ctx,t)
     SSL_CTX *	ctx
     long 	t

int
SSL_CTX_set_trust(s,trust)
     SSL_CTX *	s
     int 	trust

void
SSL_CTX_set_verify_depth(ctx,depth)
     SSL_CTX *	ctx
     int 	depth

int
SSL_CTX_use_certificate(ctx,x)
     SSL_CTX *	ctx
     X509 *	x

int
SSL_CTX_use_certificate_chain_file(ctx,file)
     SSL_CTX *	ctx
     const char * file


#if OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_use_certificate_chain_file(ssl,file)
     SSL * ssl
     const char * file

#endif /* OpenSSL 1.1.0 */

int
SSL_CTX_use_PrivateKey(ctx,pkey)
     SSL_CTX *	ctx
     EVP_PKEY *	pkey

int
SSL_CTX_use_RSAPrivateKey(ctx,rsa)
     SSL_CTX *	ctx
     RSA *	rsa

int
SSL_do_handshake(s)
     SSL *	s

SSL *
SSL_dup(ssl)
     SSL *	ssl

const SSL_CIPHER *
SSL_get_current_cipher(s)
     SSL *	s

long
SSL_get_default_timeout(s)
     SSL *	s

void *
SSL_get_ex_data(ssl,idx)
     SSL *	ssl
     int 	idx

size_t
SSL_get_finished(ssl,buf,count=2*EVP_MAX_MD_SIZE)
        SSL *ssl
        SV  *buf
        size_t count
    PREINIT:
        unsigned char *finished;
        size_t finished_len;
    CODE:
        Newx(finished, count, unsigned char);
        finished_len = SSL_get_finished(ssl, finished, count);
        if (count > finished_len)
            count = finished_len;
        sv_setpvn(buf, (const char *)finished, count);
        Safefree(finished);
        RETVAL = finished_len;
    OUTPUT:
        RETVAL

size_t
SSL_get_peer_finished(ssl,buf,count=2*EVP_MAX_MD_SIZE)
        SSL *ssl
        SV  *buf
        size_t count
    PREINIT:
        unsigned char *finished;
        size_t finished_len;
    CODE:
        Newx(finished, count, unsigned char);
        finished_len = SSL_get_peer_finished(ssl, finished, count);
        if (count > finished_len)
            count = finished_len;
        sv_setpvn(buf, (const char *)finished, count);
        Safefree(finished);
        RETVAL = finished_len;
    OUTPUT:
        RETVAL

int
SSL_get_quiet_shutdown(ssl)
     SSL *	ssl

int
SSL_get_shutdown(ssl)
     SSL *	ssl

int
SSL_get_verify_depth(s)
     SSL *	s

int
SSL_get_verify_mode(s)
     SSL *	s

long
SSL_get_verify_result(ssl)
     SSL *	ssl

int
SSL_renegotiate(s)
     SSL *	s

#if OPENSSL_VERSION_NUMBER < 0x10000000L

int
SSL_SESSION_cmp(a,b)
     SSL_SESSION *	a
     SSL_SESSION *	b

#endif

void *
SSL_SESSION_get_ex_data(ss,idx)
     SSL_SESSION *	ss
     int 	idx

long
SSL_SESSION_get_time(s)
     SSL_SESSION *	s

long
SSL_SESSION_get_timeout(s)
     SSL_SESSION *	s

int
SSL_SESSION_print_fp(fp,ses)
     FILE *	fp
     SSL_SESSION *	ses

int
SSL_SESSION_set_ex_data(ss,idx,data)
     SSL_SESSION *	ss
     int 	idx
     void *	data

long
SSL_SESSION_set_time(s,t)
     SSL_SESSION *	s
     long 	t

long
SSL_SESSION_set_timeout(s,t)
     SSL_SESSION *	s
     long 	t

void
SSL_set_accept_state(s)
     SSL *	s

void
sk_X509_NAME_free(sk)
	X509_NAME_STACK *sk

int
sk_X509_NAME_num(sk)
	X509_NAME_STACK *sk

X509_NAME *
sk_X509_NAME_value(sk,i)
	X509_NAME_STACK *sk
	int i

X509_NAME_STACK *
SSL_get_client_CA_list(s)
	SSL *	s

void
SSL_set_client_CA_list(s,list)
     SSL *	s
     X509_NAME_STACK *  list

void
SSL_set_connect_state(s)
     SSL *	s

int
SSL_set_ex_data(ssl,idx,data)
     SSL *	ssl
     int 	idx
     void *	data


void
SSL_set_info_callback(ssl,callback,data=&PL_sv_undef)
        SSL * ssl
        SV  * callback
	SV  * data
    CODE: 
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_info_callback(ssl, NULL);
            cb_data_advanced_put(ssl, "ssleay_info_cb!!func", NULL);
            cb_data_advanced_put(ssl, "ssleay_info_cb!!data", NULL);
        } else {
            cb_data_advanced_put(ssl, "ssleay_info_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ssl, "ssleay_info_cb!!data", newSVsv(data));
            SSL_set_info_callback(ssl, ssleay_info_cb_invoke);
        }

void
SSL_CTX_set_info_callback(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
	SV * data
    CODE: 
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_info_callback(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_info_cb!!func", NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_info_cb!!data", NULL);
        } else {
            cb_data_advanced_put(ctx, "ssleay_ctx_info_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "ssleay_ctx_info_cb!!data", newSVsv(data));
            SSL_CTX_set_info_callback(ctx, ssleay_ctx_info_cb_invoke);
        }

void
SSL_set_msg_callback(ssl,callback,data=&PL_sv_undef)
        SSL * ssl
        SV * callback
    SV * data
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_msg_callback(ssl, NULL);
            cb_data_advanced_put(ssl, "ssleay_msg_cb!!func", NULL);
            cb_data_advanced_put(ssl, "ssleay_msg_cb!!data", NULL);
        } else {
            cb_data_advanced_put(ssl, "ssleay_msg_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ssl, "ssleay_msg_cb!!data", newSVsv(data));
            SSL_set_msg_callback(ssl, ssleay_msg_cb_invoke);
        }

void
SSL_CTX_set_msg_callback(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
    SV * data
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_msg_callback(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_msg_cb!!func", NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_msg_cb!!data", NULL);
        } else {
            cb_data_advanced_put(ctx, "ssleay_ctx_msg_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "ssleay_ctx_msg_cb!!data", newSVsv(data));
            SSL_CTX_set_msg_callback(ctx, ssleay_ctx_msg_cb_invoke);
        }


#if OPENSSL_VERSION_NUMBER >= 0x10101001 && !defined(LIBRESSL_VERSION_NUMBER)

void
SSL_CTX_set_keylog_callback(SSL_CTX *ctx, SV *callback)
    CODE:
	if (callback==NULL || !SvOK(callback)) {
	    SSL_CTX_set_keylog_callback(ctx, NULL);
	    cb_data_advanced_put(ctx, "ssleay_ssl_ctx_keylog_callback!!func", NULL);
	} else {
	    cb_data_advanced_put(ctx, "ssleay_ssl_ctx_keylog_callback!!func", newSVsv(callback));
	    SSL_CTX_set_keylog_callback(ctx, ssl_ctx_keylog_cb_func_invoke);
	}

SV *
SSL_CTX_get_keylog_callback(const SSL_CTX *ctx)
    CODE:
	SV *func = cb_data_advanced_get(ctx, "ssleay_ssl_ctx_keylog_callback!!func");
	/* without increment the reference will go away and ssl_ctx_keylog_cb_func_invoke croaks */
	SvREFCNT_inc(func);
	RETVAL = func;
    OUTPUT:
	RETVAL

#endif


int
SSL_set_purpose(s,purpose)
     SSL *	s
     int 	purpose

void
SSL_set_quiet_shutdown(ssl,mode)
     SSL *	ssl
     int 	mode

void
SSL_set_shutdown(ssl,mode)
     SSL *	ssl
     int 	mode

int
SSL_set_trust(s,trust)
     SSL *	s
     int 	trust

void
SSL_set_verify_depth(s,depth)
     SSL *	s
     int 	depth

void
SSL_set_verify_result(ssl,v)
     SSL *	ssl
     long 	v

int
SSL_shutdown(s)
     SSL *	s

const char *
SSL_get_version(ssl)
     const SSL * ssl

int
SSL_version(ssl)
     SSL *	ssl

#if OPENSSL_VERSION_NUMBER >= 0x10100006L && !defined(LIBRESSL_VERSION_NUMBER) /* 1.1.0-pre6 */

int
SSL_client_version(ssl)
     const SSL * ssl

int
SSL_is_dtls(ssl)
     const SSL * ssl

#endif

#define REM_MANUALLY_ADDED_1_09

X509_NAME_STACK *
SSL_load_client_CA_file(file)
     const char * file

int
SSL_add_file_cert_subjects_to_stack(stackCAs,file)
     X509_NAME_STACK * stackCAs
     const char * file

#ifndef WIN32
#ifndef VMS
#ifndef MAC_OS_pre_X

int
SSL_add_dir_cert_subjects_to_stack(stackCAs,dir)
     X509_NAME_STACK * stackCAs
     const char * dir

#endif
#endif
#endif

int
SSL_CTX_get_ex_new_index(argl,argp=NULL,new_func=NULL,dup_func=NULL,free_func=NULL)
     long argl
     void *  argp
     CRYPTO_EX_new *   new_func
     CRYPTO_EX_dup *   dup_func
     CRYPTO_EX_free *  free_func

int
SSL_CTX_set_session_id_context(ctx,sid_ctx,sid_ctx_len)
     SSL_CTX *   ctx
     const unsigned char *   sid_ctx
     unsigned int sid_ctx_len

int
SSL_set_session_id_context(ssl,sid_ctx,sid_ctx_len)
     SSL *   ssl
     const unsigned char *   sid_ctx
     unsigned int sid_ctx_len

#if OPENSSL_VERSION_NUMBER < 0x10100000L
void
SSL_CTX_set_tmp_rsa_callback(ctx, cb)
     SSL_CTX *   ctx
     cb_ssl_int_int_ret_RSA *   cb

void
SSL_set_tmp_rsa_callback(ssl, cb)
     SSL *   ssl
     cb_ssl_int_int_ret_RSA *  cb

#endif

void
SSL_CTX_set_tmp_dh_callback(ctx, dh)
     SSL_CTX *   ctx
     cb_ssl_int_int_ret_DH *  dh

void
SSL_set_tmp_dh_callback(ssl,dh)
     SSL *  ssl
     cb_ssl_int_int_ret_DH *  dh

int
SSL_get_ex_new_index(argl,argp=NULL,new_func=NULL,dup_func=NULL,free_func=NULL)
     long argl
     void *   argp
     CRYPTO_EX_new *  new_func
     CRYPTO_EX_dup *  dup_func
     CRYPTO_EX_free * free_func

int
SSL_SESSION_get_ex_new_index(argl,argp=NULL,new_func=NULL,dup_func=NULL,free_func=NULL)
     long argl
     void *   argp
     CRYPTO_EX_new *  new_func
     CRYPTO_EX_dup *  dup_func
     CRYPTO_EX_free * free_func

#define REM_SEMIAUTOMATIC_MACRO_GEN_1_09

long
SSL_clear_num_renegotiations(ssl)
  SSL *  ssl
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_CLEAR_NUM_RENEGOTIATIONS,0,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_add_extra_chain_cert(ctx,x509)
     SSL_CTX *	ctx
     X509 *     x509
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_EXTRA_CHAIN_CERT,0,(char*)x509);
  OUTPUT:
  RETVAL

void *
SSL_CTX_get_app_data(ctx)
     SSL_CTX *	ctx
  CODE:
  RETVAL = SSL_CTX_get_ex_data(ctx,0);
  OUTPUT:
  RETVAL

long
SSL_CTX_get_mode(ctx)
     SSL_CTX *	ctx
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_MODE,0,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_get_read_ahead(ctx)
     SSL_CTX *	ctx
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_GET_READ_AHEAD,0,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_get_session_cache_mode(ctx)
     SSL_CTX *	ctx
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_GET_SESS_CACHE_MODE,0,NULL);
  OUTPUT:
  RETVAL

#if OPENSSL_VERSION_NUMBER < 0x10100000L
long
SSL_CTX_need_tmp_RSA(ctx)
     SSL_CTX *	ctx
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_NEED_TMP_RSA,0,NULL);
  OUTPUT:
  RETVAL

#endif

int
SSL_CTX_set_app_data(ctx,arg)
     SSL_CTX *	ctx
     char *	arg
  CODE:
  RETVAL = SSL_CTX_set_ex_data(ctx,0,arg);
  OUTPUT:
  RETVAL

long
SSL_CTX_set_mode(ctx,op)
     SSL_CTX *	ctx
     long 	op
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_MODE,op,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_set_read_ahead(ctx,m)
     SSL_CTX *	ctx
     long 	m
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_SET_READ_AHEAD,m,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_set_session_cache_mode(ctx,m)
     SSL_CTX *	ctx
     long 	m
  CODE:
  RETVAL = SSL_CTX_ctrl(ctx,SSL_CTRL_SET_SESS_CACHE_MODE,m,NULL);
  OUTPUT:
  RETVAL

long
SSL_CTX_set_tmp_dh(ctx,dh)
     SSL_CTX *	ctx
     DH *	dh

#if OPENSSL_VERSION_NUMBER < 0x10100000L
long
SSL_CTX_set_tmp_rsa(ctx,rsa)
     SSL_CTX *	ctx
     RSA *	rsa

#endif

#if OPENSSL_VERSION_NUMBER > 0x10000000L && !defined OPENSSL_NO_EC

EC_KEY *
EC_KEY_new_by_curve_name(nid)
    int nid

void
EC_KEY_free(key)
    EC_KEY * key

long
SSL_CTX_set_tmp_ecdh(ctx,ecdh)
     SSL_CTX *	ctx
     EC_KEY  *	ecdh

int
EVP_PKEY_assign_EC_KEY(pkey,key)
    EVP_PKEY *  pkey
    EC_KEY *    key


EC_KEY *
EC_KEY_generate_key(curve)
	SV *curve;
    CODE:
	EC_GROUP *group = NULL;
	EC_KEY *eckey = NULL;
	int nid;

	RETVAL = 0;
	if (SvIOK(curve)) {
	    nid = SvIV(curve);
	} else {
	    nid = OBJ_sn2nid(SvPV_nolen(curve));
#if OPENSSL_VERSION_NUMBER > 0x10002000L
	    if (!nid) nid = EC_curve_nist2nid(SvPV_nolen(curve));
#endif
	    if (!nid) croak("unknown curve %s",SvPV_nolen(curve));
	}

	group = EC_GROUP_new_by_curve_name(nid);
	if (!group) croak("unknown curve nid=%d",nid);
	EC_GROUP_set_asn1_flag(group,OPENSSL_EC_NAMED_CURVE);

	eckey = EC_KEY_new();
	if ( eckey
	    && EC_KEY_set_group(eckey, group)
	    && EC_KEY_generate_key(eckey)) {
	    RETVAL = eckey;
	} else {
	    if (eckey) EC_KEY_free(eckey);
	}
	if (group) EC_GROUP_free(group);

    OUTPUT:
	RETVAL


#ifdef SSL_CTRL_SET_ECDH_AUTO

long
SSL_CTX_set_ecdh_auto(ctx,onoff)
     SSL_CTX * ctx
     int onoff

long
SSL_set_ecdh_auto(ssl,onoff)
     SSL * ssl
     int onoff

#endif

#ifdef SSL_CTRL_SET_CURVES_LIST

long
SSL_CTX_set1_curves_list(ctx,list)
     SSL_CTX * ctx
     char * list

long
SSL_set1_curves_list(ssl,list)
     SSL * ssl
     char * list

#endif

#if SSL_CTRL_SET_GROUPS_LIST

long
SSL_CTX_set1_groups_list(ctx,list)
     SSL_CTX * ctx
     char * list

long
SSL_set1_groups_list(ssl,list)
     SSL * ssl
     char * list

#endif



#endif

void *
SSL_get_app_data(s)
     SSL *	s
  CODE:
  RETVAL = SSL_get_ex_data(s,0);
  OUTPUT:
  RETVAL

int
SSL_get_cipher_bits(s,np=NULL)
     SSL *	s
     int *	np
  CODE:
  RETVAL = SSL_CIPHER_get_bits(SSL_get_current_cipher(s),np);
  OUTPUT:
  RETVAL

long
SSL_get_mode(ssl)
     SSL *	ssl
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_MODE,0,NULL);
  OUTPUT:
  RETVAL

void
SSL_set_state(ssl,state)
     SSL *	ssl
     int        state
  CODE:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
      /* not available */
#elif defined(OPENSSL_NO_SSL_INTERN)
   SSL_set_state(ssl,state);
#else
  ssl->state = state;
#endif

#if OPENSSL_VERSION_NUMBER < 0x10100000L
long
SSL_need_tmp_RSA(ssl)
     SSL *	ssl
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_NEED_TMP_RSA,0,NULL);
  OUTPUT:
  RETVAL


#endif

long
SSL_num_renegotiations(ssl)
     SSL *	ssl
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_GET_NUM_RENEGOTIATIONS,0,NULL);
  OUTPUT:
  RETVAL

void *
SSL_SESSION_get_app_data(ses)
     SSL_SESSION *	ses
  CODE:
  RETVAL = SSL_SESSION_get_ex_data(ses,0);
  OUTPUT:
  RETVAL

long
SSL_session_reused(ssl)
     SSL *	ssl

int
SSL_SESSION_set_app_data(s,a)
     SSL_SESSION *	s
     void *	a
  CODE:
  RETVAL = SSL_SESSION_set_ex_data(s,0,(char *)a);
  OUTPUT:
  RETVAL

int
SSL_set_app_data(s,arg)
     SSL *	s
     void *	arg
  CODE:
  RETVAL = SSL_set_ex_data(s,0,(char *)arg);
  OUTPUT:
  RETVAL

long
SSL_set_mode(ssl,op)
     SSL *	ssl
     long 	op
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_MODE,op,NULL);
  OUTPUT:
  RETVAL

int
SSL_set_pref_cipher(s,n)
     SSL *	s
     const char * n
  CODE:
  RETVAL = SSL_set_cipher_list(s,n);
  OUTPUT:
  RETVAL

long
SSL_set_tmp_dh(ssl,dh)
     SSL *	ssl
     DH *	dh

#if OPENSSL_VERSION_NUMBER < 0x10100000L
long
SSL_set_tmp_rsa(ssl,rsa)
     SSL *	ssl
     char *	rsa
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_SET_TMP_RSA,0,(char *)rsa);
  OUTPUT:
  RETVAL

#endif

#if OPENSSL_VERSION_NUMBER >= 0x0090800fL

RSA *
RSA_generate_key(bits,ee,perl_cb=&PL_sv_undef,perl_data=&PL_sv_undef)
        int bits
        unsigned long ee
        SV* perl_cb
        SV* perl_data
    PREINIT:
        simple_cb_data_t* cb_data = NULL;
    CODE:
       /* openssl 0.9.8 deprecated RSA_generate_key. */
       /* This equivalent was contributed by Brian Fraser for Android, */
       /* but was not portable to old OpenSSLs where RSA_generate_key_ex is not available. */
       /* It should now be more versatile. */
       /* as of openssl 1.1.0-pre1 it is not possible anymore to generate the BN_GENCB structure directly. */
       /* instead BN_EGNCB_new() has to be used. */
       int rc;
       RSA * ret;
       BIGNUM *e;
       e = BN_new();
       if(!e)
           croak("Net::SSLeay: RSA_generate_key perl function could not create BN structure.\n");
       BN_set_word(e, ee);
       cb_data = simple_cb_data_new(perl_cb, perl_data);

       ret = RSA_new();
       if(!ret) {
	   simple_cb_data_free(cb_data);
	   BN_free(e);
           croak("Net::SSLeay: RSA_generate_key perl function could not create RSA structure.\n");
       }
#if (OPENSSL_VERSION_NUMBER >= 0x10100001L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)
       BN_GENCB *new_cb;
       new_cb = BN_GENCB_new();
       if(!new_cb) {
	   simple_cb_data_free(cb_data);
	   BN_free(e);
	   RSA_free(ret);
	   croak("Net::SSLeay: RSA_generate_key perl function could not create BN_GENCB structure.\n");
       }
       BN_GENCB_set_old(new_cb, ssleay_RSA_generate_key_cb_invoke, cb_data);
       rc = RSA_generate_key_ex(ret, bits, e, new_cb);
       BN_GENCB_free(new_cb);
#else
       BN_GENCB new_cb;
       BN_GENCB_set_old(&new_cb, ssleay_RSA_generate_key_cb_invoke, cb_data);
       rc = RSA_generate_key_ex(ret, bits, e, &new_cb);
#endif
       simple_cb_data_free(cb_data);
       BN_free(e);
       if (rc == -1 || ret == NULL) {
           if (ret) RSA_free(ret);
           croak("Net::SSLeay: Couldn't generate RSA key");
       }
       e = NULL;
       RETVAL = ret;
    OUTPUT:
        RETVAL

#else

RSA *
RSA_generate_key(bits,e,perl_cb=&PL_sv_undef,perl_data=&PL_sv_undef)
        int bits
        unsigned long e
        SV* perl_cb
        SV* perl_data
    PREINIT:
        simple_cb_data_t* cb = NULL;
    CODE:
        cb = simple_cb_data_new(perl_cb, perl_data);
        RETVAL = RSA_generate_key(bits, e, ssleay_RSA_generate_key_cb_invoke, cb);
        simple_cb_data_free(cb);
    OUTPUT:
        RETVAL

#endif

#if OPENSSL_VERSION_NUMBER < 0x10100000L || defined(LIBRESSL_VERSION_NUMBER)

void
RSA_get_key_parameters(rsa)
	    RSA * rsa
PPCODE:
{
    /* Caution: returned list consists of SV pointers to BIGNUMs, which would need to be blessed as Crypt::OpenSSL::Bignum for further use */
    XPUSHs(bn2sv(rsa->n));
    XPUSHs(bn2sv(rsa->e));
    XPUSHs(bn2sv(rsa->d));
    XPUSHs(bn2sv(rsa->p));
    XPUSHs(bn2sv(rsa->q));
    XPUSHs(bn2sv(rsa->dmp1));
    XPUSHs(bn2sv(rsa->dmq1));
    XPUSHs(bn2sv(rsa->iqmp));
}

#endif

void
RSA_free(r)
    RSA * r

X509 *
X509_new()

void
X509_free(a)
    X509 * a

X509_CRL *
d2i_X509_CRL_bio(BIO *bp,void *unused=NULL)

X509_REQ *
d2i_X509_REQ_bio(BIO *bp,void *unused=NULL)

X509 *
d2i_X509_bio(BIO *bp,void *unused=NULL)

DH *
PEM_read_bio_DHparams(bio,x=NULL,cb=NULL,u=NULL)
	BIO  * bio
	void * x
	pem_password_cb * cb
	void * u

X509_CRL *
PEM_read_bio_X509_CRL(bio,x=NULL,cb=NULL,u=NULL)
	BIO  * bio
	void * x
	pem_password_cb * cb
	void * u

X509 *
PEM_read_bio_X509(BIO *bio,void *x=NULL,void *cb=NULL,void *u=NULL)

STACK_OF(X509_INFO) *
PEM_X509_INFO_read_bio(bio, stack=NULL, cb=NULL, u=NULL)
    BIO * bio
    STACK_OF(X509_INFO) * stack
    pem_password_cb * cb
    void * u

int
sk_X509_INFO_num(stack)
    STACK_OF(X509_INFO) * stack

X509_INFO *
sk_X509_INFO_value(stack, index)
    const STACK_OF(X509_INFO) * stack
    int index

void
sk_X509_INFO_free(stack)
    STACK_OF(X509_INFO) * stack

STACK_OF(X509) *
sk_X509_new_null()

void
sk_X509_free(stack)
    STACK_OF(X509) * stack

int
sk_X509_push(stack, data)
    STACK_OF(X509) * stack
    X509 * data

X509 *
sk_X509_pop(stack)
    STACK_OF(X509) * stack

X509 *
sk_X509_shift(stack)
    STACK_OF(X509) * stack

int
sk_X509_unshift(stack,x509)
    STACK_OF(X509) * stack
    X509 * x509

int
sk_X509_insert(stack,x509,index)
    STACK_OF(X509) * stack
    X509 * x509
    int index

X509 *
sk_X509_delete(stack,index)
    STACK_OF(X509) * stack
    int index

X509 *
sk_X509_value(stack,index)
    STACK_OF(X509) * stack
    int index

int
sk_X509_num(stack)
    STACK_OF(X509) * stack

X509 *
P_X509_INFO_get_x509(info)
        X509_INFO * info
    CODE:
        RETVAL = info->x509;
    OUTPUT:
        RETVAL

X509_REQ *
PEM_read_bio_X509_REQ(BIO *bio,void *x=NULL,pem_password_cb *cb=NULL,void *u=NULL)

EVP_PKEY *
PEM_read_bio_PrivateKey(bio,perl_cb=&PL_sv_undef,perl_data=&PL_sv_undef)
        BIO *bio
        SV* perl_cb
        SV* perl_data
    PREINIT:
        simple_cb_data_t* cb = NULL;
    CODE:
        RETVAL = 0;
        if (SvOK(perl_cb)) {
            /* setup our callback */
            cb = simple_cb_data_new(perl_cb, perl_data);
            RETVAL = PEM_read_bio_PrivateKey(bio, NULL, pem_password_cb_invoke, (void*)cb);
            simple_cb_data_free(cb);
        }
        else if (!SvOK(perl_cb) && SvOK(perl_data) && SvPOK(perl_data)) {
            /* use perl_data as the password */
            RETVAL = PEM_read_bio_PrivateKey(bio, NULL, NULL, SvPVX(perl_data));
        }
        else if (!SvOK(perl_cb) && !SvOK(perl_data)) {
            /* will trigger default password callback */
            RETVAL = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
        }
    OUTPUT:
        RETVAL

void
DH_free(dh)
	DH * dh

long
SSL_total_renegotiations(ssl)
     SSL *	ssl
  CODE:
  RETVAL = SSL_ctrl(ssl,SSL_CTRL_GET_TOTAL_RENEGOTIATIONS,0,NULL);
  OUTPUT:
  RETVAL

#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)
void
SSL_SESSION_get_master_key(s)
     SSL_SESSION *   s
     PREINIT:
     size_t master_key_length;
     unsigned char* master_key;
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     master_key_length = SSL_SESSION_get_master_key(s, 0, 0); /* get the length */
     New(0, master_key, master_key_length, unsigned char);
     SSL_SESSION_get_master_key(s, master_key, master_key_length);
     sv_setpvn(ST(0), (const char*)master_key, master_key_length);
     Safefree(master_key);

#else
void
SSL_SESSION_get_master_key(s)
     SSL_SESSION *   s
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     sv_setpvn(ST(0), (const char*)s->master_key, s->master_key_length);

#endif

#if OPENSSL_VERSION_NUMBER < 0x10100000L

void
SSL_SESSION_set_master_key(s,key)
     SSL_SESSION *   s
     PREINIT:
     STRLEN len;
     INPUT:
     char * key = SvPV(ST(1), len);
     CODE:
     memcpy(s->master_key, key, len);
     s->master_key_length = len;

#endif

#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)

void
SSL_get_client_random(s)
     SSL *   s
     PREINIT:
     size_t random_length;
     unsigned char* random_data;
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     random_length = SSL_get_client_random(s, 0, 0); /* get the length */
     New(0, random_data, random_length, unsigned char);
     SSL_get_client_random(s, random_data, random_length);
     sv_setpvn(ST(0), (const char*)random_data, random_length);
     Safefree(random_data);

#else

void
SSL_get_client_random(s)
     SSL *   s
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     sv_setpvn(ST(0), (const char*)s->s3->client_random, SSL3_RANDOM_SIZE);

#endif

#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)

void
SSL_get_server_random(s)
     SSL *   s
     PREINIT:
     size_t random_length;
     unsigned char* random_data;
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     random_length = SSL_get_server_random(s, 0, 0); /* get the length */
     New(0, random_data, random_length, unsigned char);
     SSL_get_server_random(s, random_data, random_length);
     sv_setpvn(ST(0), (const char*)random_data, random_length);
     Safefree(random_data);

#else

void
SSL_get_server_random(s)
     SSL *   s
     CODE:
     ST(0) = sv_newmortal();   /* Undefined to start with */
     sv_setpvn(ST(0), (const char*)s->s3->server_random, SSL3_RANDOM_SIZE);

#endif

int
SSL_get_keyblock_size(s)
     SSL *   s
     CODE:
#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL)
        const SSL_CIPHER *ssl_cipher;
	int cipher = NID_undef, digest = NID_undef, mac_secret_size = 0;
	const EVP_CIPHER *c = NULL;
	const EVP_MD *h = NULL;

	ssl_cipher = SSL_get_current_cipher(s);
	if (ssl_cipher)
	    cipher = SSL_CIPHER_get_cipher_nid(ssl_cipher);
	if (cipher != NID_undef)
	    c = EVP_get_cipherbynid(cipher);

	if (ssl_cipher)
	    digest = SSL_CIPHER_get_digest_nid(ssl_cipher);
	if (digest != NID_undef)    /* No digest if e.g., AEAD cipher */
	    h = EVP_get_digestbynid(digest);
	if (h)
	    mac_secret_size = EVP_MD_size(h);

	RETVAL = -1;
	if (c)
	    RETVAL = 2 * (EVP_CIPHER_key_length(c) + mac_secret_size +
		          EVP_CIPHER_iv_length(c));
#else
     if (s == NULL ||
	 s->enc_read_ctx == NULL ||
	 s->enc_read_ctx->cipher == NULL ||
	 s->read_hash == NULL)
     {
	RETVAL = -1;
     }
     else
     {
	const EVP_CIPHER *c;
	const EVP_MD *h;
	int md_size = -1;
	c = s->enc_read_ctx->cipher;
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
	h = NULL;
	if (s->s3)
	    md_size = s->s3->tmp.new_mac_secret_size;
#elif OPENSSL_VERSION_NUMBER >= 0x00909000L
	h = EVP_MD_CTX_md(s->read_hash);
	md_size = EVP_MD_size(h);
#else
	h = s->read_hash;
	md_size = EVP_MD_size(h);
#endif
	/* No digest if e.g., AEAD cipher */
	RETVAL = (md_size >= 0) ? (2 * (EVP_CIPHER_key_length(c) +
				       md_size +
				       EVP_CIPHER_iv_length(c)))
			       : -1;
     }
#endif

     OUTPUT:
     RETVAL



#if defined(SSL_F_SSL_SET_HELLO_EXTENSION)
int
SSL_set_hello_extension(s, type, data)
     SSL *   s
     int     type
     PREINIT:
     STRLEN len;
     INPUT:
     char *  data = SvPV( ST(2), len);
     CODE:
     RETVAL = SSL_set_hello_extension(s, type, data, len);
     OUTPUT:
     RETVAL

#endif

#if defined(SSL_F_SSL_SET_HELLO_EXTENSION) || defined(SSL_F_SSL_SET_SESSION_TICKET_EXT)

void 
SSL_set_session_secret_cb(s,callback=&PL_sv_undef,data=&PL_sv_undef)
        SSL * s
        SV * callback
        SV * data
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_session_secret_cb(s, NULL, NULL);
            cb_data_advanced_put(s, "ssleay_session_secret_cb!!func", NULL);
            cb_data_advanced_put(s, "ssleay_session_secret_cb!!data", NULL);
        }
        else {
            cb_data_advanced_put(s, "ssleay_session_secret_cb!!func", newSVsv(callback));
            cb_data_advanced_put(s, "ssleay_session_secret_cb!!data", newSVsv(data));
            SSL_set_session_secret_cb(s, (tls_session_secret_cb_fn)&ssleay_session_secret_cb_invoke, s);
        }

#endif

#ifdef NET_SSLEAY_CAN_PSK_CLIENT_CALLBACK

void
SSL_set_psk_client_callback(s,callback=&PL_sv_undef)
        SSL * s
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_set_psk_client_callback(s, NULL);
            cb_data_advanced_put(s, "ssleay_set_psk_client_callback!!func", NULL);
        }
        else {
            cb_data_advanced_put(s, "ssleay_set_psk_client_callback!!func", newSVsv(callback));
            SSL_set_psk_client_callback(s, ssleay_set_psk_client_callback_invoke);
        }

void
SSL_CTX_set_psk_client_callback(ctx,callback=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_psk_client_callback(ctx, NULL);
            cb_data_advanced_put(ctx, "ssleay_ctx_set_psk_client_callback!!func", NULL);
        }
        else {
            cb_data_advanced_put(ctx, "ssleay_ctx_set_psk_client_callback!!func", newSVsv(callback));
            SSL_CTX_set_psk_client_callback(ctx, ssleay_ctx_set_psk_client_callback_invoke);
        }

#endif

#ifdef NET_SSLEAY_CAN_TICKET_KEY_CB

void
SSL_CTX_set_tlsext_ticket_getkey_cb(ctx,callback=&PL_sv_undef,data=&PL_sv_undef)
        SSL_CTX * ctx 
        SV * callback
        SV * data
    CODE:
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_tlsext_ticket_key_cb(ctx, NULL);
	    cb_data_advanced_put(ctx, "tlsext_ticket_key_cb!!func", NULL);
	    cb_data_advanced_put(ctx, "tlsext_ticket_key_cb!!data", NULL);
        }
        else {
	    cb_data_advanced_put(ctx, "tlsext_ticket_key_cb!!func", newSVsv(callback));
	    cb_data_advanced_put(ctx, "tlsext_ticket_key_cb!!data", newSVsv(data));
            SSL_CTX_set_tlsext_ticket_key_cb(ctx, &tlsext_ticket_key_cb_invoke);
        }


#endif


#if OPENSSL_VERSION_NUMBER < 0x0090700fL
#define REM11 "NOTE: before 0.9.7"

int EVP_add_digest(EVP_MD *digest)

#else

int EVP_add_digest(const EVP_MD *digest)

#endif

#ifndef OPENSSL_NO_SHA

const EVP_MD *EVP_sha1()

#endif
#if !defined(OPENSSL_NO_SHA256) && OPENSSL_VERSION_NUMBER >= 0x0090800fL

const EVP_MD *EVP_sha256()

#endif
#if !defined(OPENSSL_NO_SHA512) && OPENSSL_VERSION_NUMBER >= 0x0090800fL

const EVP_MD *EVP_sha512()

#endif
void OpenSSL_add_all_digests()

const EVP_MD * EVP_get_digestbyname(const char *name)

int EVP_MD_type(const EVP_MD *md)

int EVP_MD_size(const EVP_MD *md)

#if OPENSSL_VERSION_NUMBER >= 0x1000000fL

SV*
P_EVP_MD_list_all()
    INIT:
        AV * results;
    CODE:
        results = (AV *)sv_2mortal((SV *)newAV());
        EVP_MD_do_all_sorted(handler_list_md_fn, results);
        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL

#endif

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL
#define REM16 "NOTE: requires 0.9.7+"

const EVP_MD *EVP_MD_CTX_md(const EVP_MD_CTX *ctx)

EVP_MD_CTX *EVP_MD_CTX_create()

int EVP_DigestInit(EVP_MD_CTX *ctx, const EVP_MD *type)

int EVP_DigestInit_ex(EVP_MD_CTX *ctx, const EVP_MD *type, ENGINE *impl)

void EVP_MD_CTX_destroy(EVP_MD_CTX *ctx)

void
EVP_DigestUpdate(ctx,data)
     PREINIT:
     STRLEN len;
     INPUT:
     EVP_MD_CTX *ctx = INT2PTR(EVP_MD_CTX *, SvIV(ST(0)));
     unsigned char *data = (unsigned char *) SvPV(ST(1), len);
     CODE:
     XSRETURN_IV(EVP_DigestUpdate(ctx,data,len));

void
EVP_DigestFinal(ctx)
     EVP_MD_CTX *ctx
     INIT:
     unsigned char md[EVP_MAX_MD_SIZE];
     unsigned int md_size;
     CODE:
     if (EVP_DigestFinal(ctx,md,&md_size))
         XSRETURN_PVN((char *)md, md_size);
     else
         XSRETURN_UNDEF;

void
EVP_DigestFinal_ex(ctx)
     EVP_MD_CTX *ctx
     INIT:
     unsigned char md[EVP_MAX_MD_SIZE];
     unsigned int md_size;
     CODE:
     if (EVP_DigestFinal_ex(ctx,md,&md_size))
         XSRETURN_PVN((char *)md, md_size);
     else
         XSRETURN_UNDEF;

void
EVP_Digest(...)
     PREINIT:
     STRLEN len;
     unsigned char md[EVP_MAX_MD_SIZE];
     unsigned int md_size;
     INPUT:
     unsigned char *data = (unsigned char *) SvPV(ST(0), len);
     EVP_MD *type = INT2PTR(EVP_MD *, SvIV(ST(1)));
     ENGINE *impl = (items>2 && SvOK(ST(2))) ? INT2PTR(ENGINE *, SvIV(ST(2))) : NULL;
     CODE:
     if (EVP_Digest(data,len,md,&md_size,type,impl))
         XSRETURN_PVN((char *)md, md_size);
     else
         XSRETURN_UNDEF;

#endif

const EVP_CIPHER *
EVP_get_cipherbyname(const char *name)

void
OpenSSL_add_all_algorithms()

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL

void
OPENSSL_add_all_algorithms_noconf()

void
OPENSSL_add_all_algorithms_conf()

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10000003L

int
SSL_CTX_set1_param(ctx, vpm)
     SSL_CTX *          ctx
     X509_VERIFY_PARAM *vpm

int
SSL_set1_param(ctx, vpm)
     SSL *          ctx
     X509_VERIFY_PARAM *vpm

#endif

#if OPENSSL_VERSION_NUMBER >= 0x0090800fL

X509_VERIFY_PARAM *
X509_VERIFY_PARAM_new()

void
X509_VERIFY_PARAM_free(param)
     X509_VERIFY_PARAM *param

int
X509_VERIFY_PARAM_inherit(to, from)
     X509_VERIFY_PARAM *to
     X509_VERIFY_PARAM *from

int
X509_VERIFY_PARAM_set1(to, from)
     X509_VERIFY_PARAM *to
     X509_VERIFY_PARAM *from

int
X509_VERIFY_PARAM_set1_name(param, name)
     X509_VERIFY_PARAM *param
     const char *name

int
X509_VERIFY_PARAM_set_flags(param, flags)
    X509_VERIFY_PARAM *param
    unsigned long flags

#if OPENSSL_VERSION_NUMBER >= 0x0090801fL
#define REM13 "NOTE: requires 0.9.8a+"

int
X509_VERIFY_PARAM_clear_flags(param, flags)
    X509_VERIFY_PARAM *param
    unsigned long flags

unsigned long
X509_VERIFY_PARAM_get_flags(param)
     X509_VERIFY_PARAM *param

#endif

int
X509_VERIFY_PARAM_set_purpose(param, purpose)
    X509_VERIFY_PARAM *param
    int purpose

int
X509_VERIFY_PARAM_set_trust(param, trust)
    X509_VERIFY_PARAM *param
    int trust

void
X509_VERIFY_PARAM_set_depth(param, depth)
    X509_VERIFY_PARAM *param
    int depth

void
X509_VERIFY_PARAM_set_time(param, t)
    X509_VERIFY_PARAM *param
    time_t t

int
X509_VERIFY_PARAM_add0_policy(param, policy)
    X509_VERIFY_PARAM *param
    ASN1_OBJECT *policy

int
X509_VERIFY_PARAM_set1_policies(param, policies)
    X509_VERIFY_PARAM *param
    STACK_OF(ASN1_OBJECT) *policies

int
X509_VERIFY_PARAM_get_depth(param)
    X509_VERIFY_PARAM *param

int
X509_VERIFY_PARAM_add0_table(param)
    X509_VERIFY_PARAM *param

const X509_VERIFY_PARAM *
X509_VERIFY_PARAM_lookup(name)
    const char *name

void
X509_VERIFY_PARAM_table_cleanup()

#if (OPENSSL_VERSION_NUMBER >= 0x10002001L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL) /* OpenSSL 1.0.2-beta1, LibreSSL 2.7.0 */

X509_VERIFY_PARAM *
SSL_CTX_get0_param(ctx)
   SSL_CTX * ctx

X509_VERIFY_PARAM *
SSL_get0_param(ssl)
   SSL * ssl

int
X509_VERIFY_PARAM_set1_host(param, name)
    X509_VERIFY_PARAM *param
    PREINIT:
    STRLEN namelen;
    INPUT:
    const char * name = SvPV(ST(1), namelen);
    CODE:
    RETVAL = X509_VERIFY_PARAM_set1_host(param, name, namelen);
    OUTPUT:
    RETVAL

int
X509_VERIFY_PARAM_set1_email(param, email)
    X509_VERIFY_PARAM *param
    PREINIT:
    STRLEN emaillen;
    INPUT:
    const char * email = SvPV(ST(1), emaillen);
    CODE:
    RETVAL = X509_VERIFY_PARAM_set1_email(param, email, emaillen);
    OUTPUT:
    RETVAL

int
X509_VERIFY_PARAM_set1_ip(param, ip)
    X509_VERIFY_PARAM *param
    PREINIT:
    STRLEN iplen;
    INPUT:
    const unsigned char * ip = (const unsigned char *)SvPV(ST(1), iplen);
    CODE:
    RETVAL = X509_VERIFY_PARAM_set1_ip(param, ip, iplen);
    OUTPUT:
    RETVAL

int
X509_VERIFY_PARAM_set1_ip_asc(param, ipasc)
    X509_VERIFY_PARAM *param
    const char *ipasc

#endif /* OpenSSL 1.0.2-beta1, LibreSSL 2.7.0 */

#if (OPENSSL_VERSION_NUMBER >= 0x10002002L && !defined(LIBRESSL_VERSION_NUMBER)) || (LIBRESSL_VERSION_NUMBER >= 0x2070000fL) /* OpenSSL 1.0.2-beta2, LibreSSL 2.7.0 */

int
X509_VERIFY_PARAM_add1_host(param, name)
    X509_VERIFY_PARAM *param
    PREINIT:
    STRLEN namelen;
    INPUT:
    const char * name = SvPV(ST(1), namelen);
    CODE:
    RETVAL = X509_VERIFY_PARAM_add1_host(param, name, namelen);
    OUTPUT:
    RETVAL

void
X509_VERIFY_PARAM_set_hostflags(param, flags)
    X509_VERIFY_PARAM *param
    unsigned int flags

char *
X509_VERIFY_PARAM_get0_peername(param)
    X509_VERIFY_PARAM *param

#endif /* OpenSSL 1.0.2-beta2, LibreSSL 2.7.0 */

void
X509_policy_tree_free(tree)
    X509_POLICY_TREE *tree

int
X509_policy_tree_level_count(tree)
    X509_POLICY_TREE *tree

X509_POLICY_LEVEL *
X509_policy_tree_get0_level(tree, i)
    X509_POLICY_TREE *tree
    int i

STACK_OF(X509_POLICY_NODE) *
X509_policy_tree_get0_policies(tree)
    X509_POLICY_TREE *tree

STACK_OF(X509_POLICY_NODE) *
X509_policy_tree_get0_user_policies(tree)
    X509_POLICY_TREE *tree

int
X509_policy_level_node_count(level)
    X509_POLICY_LEVEL *level

X509_POLICY_NODE *
X509_policy_level_get0_node(level, i)
    X509_POLICY_LEVEL *level
    int i

const ASN1_OBJECT *
X509_policy_node_get0_policy(node)
    const X509_POLICY_NODE *node

STACK_OF(POLICYQUALINFO) *
X509_policy_node_get0_qualifiers(node)
    X509_POLICY_NODE *node

const X509_POLICY_NODE *
X509_policy_node_get0_parent(node)
    const X509_POLICY_NODE *node

#endif

ASN1_OBJECT *
OBJ_dup(o)
    ASN1_OBJECT *o

ASN1_OBJECT *
OBJ_nid2obj(n)
    int n

const char *
OBJ_nid2ln(n)
    int n

const char *
OBJ_nid2sn(n)
    int n

int
OBJ_obj2nid(o)
    ASN1_OBJECT *o

ASN1_OBJECT *
OBJ_txt2obj(s, no_name=0)
    const char *s
    int no_name

void
OBJ_obj2txt(a, no_name=0)
    ASN1_OBJECT *a
    int no_name
    PREINIT:
    char buf[100]; /* openssl doc: a buffer length of 80 should be more than enough to handle any OID encountered in practice */
    int  len;
    CODE:
    len = OBJ_obj2txt(buf, sizeof(buf), a, no_name);
    ST(0) = sv_newmortal();
    sv_setpvn(ST(0), buf, len);

#if OPENSSL_VERSION_NUMBER < 0x0090700fL
#define REM14 "NOTE: before 0.9.7"

int
OBJ_txt2nid(s)
    char *s

#else

int
OBJ_txt2nid(s)
    const char *s

#endif

int
OBJ_ln2nid(s)
    const char *s

int
OBJ_sn2nid(s)
    const char *s

int
OBJ_cmp(a, b)
    ASN1_OBJECT *a
    ASN1_OBJECT *b

#if OPENSSL_VERSION_NUMBER >= 0x0090700fL

void
X509_pubkey_digest(data,type)
        const X509 *data
        const EVP_MD *type
    PREINIT:
        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int md_size;
    PPCODE:
        if (X509_pubkey_digest(data,type,md,&md_size))
            XSRETURN_PVN((char *)md, md_size);
        else
            XSRETURN_UNDEF;

#endif

void
X509_digest(data,type)
        const X509 *data
        const EVP_MD *type
    PREINIT:
        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int md_size;
    PPCODE:
        if (X509_digest(data,type,md,&md_size))
            XSRETURN_PVN((char *)md, md_size);
        XSRETURN_UNDEF;

void
X509_CRL_digest(data,type)
        const X509_CRL *data
        const EVP_MD *type
    PREINIT:
        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int md_size;
    PPCODE:
        if (X509_CRL_digest(data,type,md,&md_size))
            XSRETURN_PVN((char *)md, md_size);
        XSRETURN_UNDEF;

void
X509_REQ_digest(data,type)
        const X509_REQ *data
        const EVP_MD *type
    PREINIT:
        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int md_size;
    PPCODE:
        if (X509_REQ_digest(data,type,md,&md_size))
            XSRETURN_PVN((char *)md, md_size);
        XSRETURN_UNDEF;

void
X509_NAME_digest(data,type)
        const X509_NAME *data
        const EVP_MD *type
    PREINIT:
        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int md_size;
    PPCODE:
        if (X509_NAME_digest(data,type,md,&md_size))
            XSRETURN_PVN((char *)md, md_size);
        XSRETURN_UNDEF;

unsigned long
X509_subject_name_hash(X509 *x)

unsigned long
X509_issuer_name_hash(X509 *a)

unsigned long
X509_issuer_and_serial_hash(X509 *a)

ASN1_OBJECT *
P_X509_get_signature_alg(x)
        X509 * x
    CODE:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)
        RETVAL = (X509_get0_tbs_sigalg(x)->algorithm);
#else
        RETVAL = (x->cert_info->signature->algorithm);
#endif
    OUTPUT:
        RETVAL

ASN1_OBJECT *
P_X509_get_pubkey_alg(x)
        X509 * x
    PREINIT:
    CODE:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
    {
	X509_ALGOR * algor;
        X509_PUBKEY_get0_param(0, 0, 0, &algor, X509_get_X509_PUBKEY(x));
        RETVAL = (algor->algorithm);
    }
#else
        RETVAL = (x->cert_info->key->algor->algorithm);
#endif
    OUTPUT:
        RETVAL

void
X509_get_X509_PUBKEY(x)
   const X509 *x
   PPCODE:
   X509_PUBKEY *pkey;
   STRLEN len;
   unsigned char *pc, *pi;
   if (!(pkey = X509_get_X509_PUBKEY(x))) croak("invalid certificate");
   if (!(len = i2d_X509_PUBKEY(pkey, NULL))) croak("invalid certificate public key");
   Newx(pc,len,unsigned char);
   if (!pc) croak("out of memory");
   pi = pc;
   i2d_X509_PUBKEY(pkey, &pi);
   if (pi-pc != len) croak("invalid encoded length");
   XPUSHs(sv_2mortal(newSVpv((char*)pc,len)));
   Safefree(pc);

#if OPENSSL_VERSION_NUMBER >= 0x10001000L && !defined(OPENSSL_NO_NEXTPROTONEG) && !defined(LIBRESSL_VERSION_NUMBER)

int
SSL_CTX_set_next_protos_advertised_cb(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
        SV * data
    CODE:
        RETVAL = 1;
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_next_protos_advertised_cb(ctx, NULL, NULL);
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!func", NULL);
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!data", NULL);
            PR1("SSL_CTX_set_next_protos_advertised_cb - undef\n");
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVAV)) {
            /* callback param array ref like ['proto1','proto2'] */
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!func", NULL);
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!data", newSVsv(callback));
            SSL_CTX_set_next_protos_advertised_cb(ctx, next_protos_advertised_cb_invoke, ctx);
            PR2("SSL_CTX_set_next_protos_advertised_cb - simple ctx=%p\n",ctx);
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV)) {
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "next_protos_advertised_cb!!data", newSVsv(data));
            SSL_CTX_set_next_protos_advertised_cb(ctx, next_protos_advertised_cb_invoke, ctx);
            PR2("SSL_CTX_set_next_protos_advertised_cb - advanced ctx=%p\n",ctx);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SSL_CTX_set_next_proto_select_cb(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
        SV * data
    CODE: 
        RETVAL = 1;
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_next_proto_select_cb(ctx, NULL, NULL);
            cb_data_advanced_put(ctx, "next_proto_select_cb!!func", NULL);
            cb_data_advanced_put(ctx, "next_proto_select_cb!!data", NULL);
            PR1("SSL_CTX_set_next_proto_select_cb - undef\n");
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVAV)) {
            /* callback param array ref like ['proto1','proto2'] */
            cb_data_advanced_put(ctx, "next_proto_select_cb!!func", NULL);
            cb_data_advanced_put(ctx, "next_proto_select_cb!!data", newSVsv(callback));
            SSL_CTX_set_next_proto_select_cb(ctx, next_proto_select_cb_invoke, ctx);
            PR2("SSL_CTX_set_next_proto_select_cb - simple ctx=%p\n",ctx);
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV)) {
            cb_data_advanced_put(ctx, "next_proto_select_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "next_proto_select_cb!!data", newSVsv(data));
            SSL_CTX_set_next_proto_select_cb(ctx, next_proto_select_cb_invoke, ctx);
            PR2("SSL_CTX_set_next_proto_select_cb - advanced ctx=%p\n",ctx);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

void
P_next_proto_negotiated(s)
        const SSL *s
    PREINIT:
        const unsigned char *data;
        unsigned int len;
    PPCODE:
        SSL_get0_next_proto_negotiated(s, &data, &len);
        XPUSHs(sv_2mortal(newSVpv((char *)data, len)));

void
P_next_proto_last_status(s)
        const SSL *s
    PPCODE:
        XPUSHs(sv_2mortal(newSVsv(cb_data_advanced_get((void*)s, "next_proto_select_cb!!last_status"))));

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10000000L

#if !defined(OPENSSL_NO_TLSEXT)

int
SSL_set_tlsext_status_type(SSL *ssl,int cmd)

long
SSL_set_tlsext_status_ocsp_resp(ssl,staple)
        SSL *  ssl
    PREINIT:
        char * p;
        STRLEN staplelen;
    INPUT:
        char *  staple = SvPV( ST(1), staplelen);
    CODE:
        /* OpenSSL will free the memory */
        New(0, p, staplelen, char);
        memcpy(p, staple, staplelen);
        RETVAL = SSL_ctrl(ssl,SSL_CTRL_SET_TLSEXT_STATUS_REQ_OCSP_RESP,staplelen,(void *)p);
    OUTPUT:
        RETVAL

int
SSL_CTX_set_tlsext_status_cb(ctx,callback,data=&PL_sv_undef)
	SSL_CTX * ctx
	SV * callback
	SV * data
    CODE:
	RETVAL = 1;
	if (callback==NULL || !SvOK(callback)) {
	    cb_data_advanced_put(ctx, "tlsext_status_cb!!func", NULL);
	    cb_data_advanced_put(ctx, "tlsext_status_cb!!data", NULL);
	    SSL_CTX_set_tlsext_status_cb(ctx, NULL);
	} else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV)) {
	    cb_data_advanced_put(ctx, "tlsext_status_cb!!func", newSVsv(callback));
	    cb_data_advanced_put(ctx, "tlsext_status_cb!!data", newSVsv(data));
	    SSL_CTX_set_tlsext_status_cb(ctx, tlsext_status_cb_invoke);
	} else {
	    croak("argument must be code reference");
	}
    OUTPUT:
	RETVAL

int
SSL_set_session_ticket_ext_cb(ssl,callback,data=&PL_sv_undef)
        SSL *  ssl
        SV *  callback
        SV *  data
    CODE:
        RETVAL = 1;
        if (callback==NULL || !SvOK(callback)) {
            cb_data_advanced_put(ssl, "session_ticket_ext_cb!!func", NULL);
            cb_data_advanced_put(ssl, "session_ticket_ext_cb!!data", NULL);
            SSL_set_session_ticket_ext_cb(ssl, NULL, NULL);
        } else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV)) {
            cb_data_advanced_put(ssl, "session_ticket_ext_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ssl, "session_ticket_ext_cb!!data", newSVsv(data));
            SSL_set_session_ticket_ext_cb(ssl, (tls_session_ticket_ext_cb_fn)&session_ticket_ext_cb_invoke, ssl);
        } else {
            croak("argument must be code reference");
        }
    OUTPUT:
        RETVAL

int
SSL_set_session_ticket_ext(ssl,ticket)
        SSL *ssl
    PREINIT:
        unsigned char * p;
        STRLEN ticketlen;
    INPUT:
        unsigned char * ticket = (unsigned char *)SvPV( ST(1), ticketlen);
    CODE:
        RETVAL = 0;
        if (ticketlen > 0) {
            Newx(p, ticketlen, unsigned char);
            if (!p)
                croak("Net::SSLeay: set_session_ticket_ext could not allocate memory.\n");
            memcpy(p, ticket, ticketlen);
            RETVAL = SSL_set_session_ticket_ext(ssl, p, ticketlen);
            Safefree(p);
        }
    OUTPUT:
        RETVAL

#endif

OCSP_RESPONSE *
d2i_OCSP_RESPONSE(pv)
	SV *pv
    CODE:
	RETVAL = NULL;
	if (SvPOK(pv)) {
	    const unsigned char *p;
	    STRLEN len;
	    p = (unsigned char*)SvPV(pv,len);
	    RETVAL = d2i_OCSP_RESPONSE(NULL,&p,len);
	}
    OUTPUT:
	RETVAL

void
i2d_OCSP_RESPONSE(r)
	OCSP_RESPONSE * r
    PPCODE:
	STRLEN len;
	unsigned char *pc,*pi;
	if (!(len = i2d_OCSP_RESPONSE(r,NULL))) croak("invalid OCSP response");
	Newx(pc,len,unsigned char);
	if (!pc) croak("out of memory");
	pi = pc;
	i2d_OCSP_RESPONSE(r,&pi);
	XPUSHs(sv_2mortal(newSVpv((char*)pc,len)));
	Safefree(pc);

void
OCSP_RESPONSE_free(r)
    OCSP_RESPONSE * r


OCSP_REQUEST *
d2i_OCSP_REQUEST(pv)
	SV *pv
    CODE:
	RETVAL = NULL;
	if (SvPOK(pv)) {
	    const unsigned char *p;
	    STRLEN len;
	    p = (unsigned char*)SvPV(pv,len);
	    RETVAL = d2i_OCSP_REQUEST(NULL,&p,len);
	}
    OUTPUT:
	RETVAL

void
i2d_OCSP_REQUEST(r)
	OCSP_REQUEST * r
    PPCODE:
	STRLEN len;
	unsigned char *pc,*pi;
	if (!(len = i2d_OCSP_REQUEST(r,NULL))) croak("invalid OCSP request");
	Newx(pc,len,unsigned char);
	if (!pc) croak("out of memory");
	pi = pc;
	i2d_OCSP_REQUEST(r,&pi);
	XPUSHs(sv_2mortal(newSVpv((char*)pc,len)));
	Safefree(pc);


void
OCSP_REQUEST_free(r)
    OCSP_REQUEST * r


const char *
OCSP_response_status_str(long status)

long
OCSP_response_status(OCSP_RESPONSE *r)

void
SSL_OCSP_cert2ids(ssl,...)
	SSL *ssl
    PPCODE:
	SSL_CTX *ctx;
	X509_STORE *store;
	STACK_OF(X509) *chain;
	X509 *cert,*issuer;
	OCSP_CERTID *id;
	int i;
	STRLEN len;
	unsigned char *pi;

	if (!ssl) croak("not a SSL object");
	ctx = SSL_get_SSL_CTX(ssl);
	if (!ctx) croak("invalid SSL object - no context");
	store = SSL_CTX_get_cert_store(ctx);
	chain = SSL_get_peer_cert_chain(ssl);

	for(i=0;i<items-1;i++) {
	    cert = INT2PTR(X509*,SvIV(ST(i+1)));
	    if (X509_check_issued(cert,cert) == X509_V_OK)
		croak("no OCSP request for self-signed certificate");
	    if (!(issuer = find_issuer(cert,store,chain)))
		croak("cannot find issuer certificate");
	    id = OCSP_cert_to_id(EVP_sha1(),cert,issuer);
	    X509_free(issuer);
	    if (!id)
		croak("out of memory for generating OCSP certid");

	    pi = NULL;
	    if (!(len = i2d_OCSP_CERTID(id,&pi)))
		croak("OCSP certid has no length");
	    XPUSHs(sv_2mortal(newSVpvn((char *)pi, len)));

	    OPENSSL_free(pi);
	    OCSP_CERTID_free(id);
	}


OCSP_REQUEST *
OCSP_ids2req(...)
    CODE:
	OCSP_REQUEST *req;
	OCSP_CERTID *id;
	int i;

	req = OCSP_REQUEST_new();
	if (!req) croak("out of memory");
	OCSP_request_add1_nonce(req,NULL,-1);

	for(i=0;i<items;i++) {
	    STRLEN len;
	    const unsigned char *p = (unsigned char*)SvPV(ST(i),len);
	    id = d2i_OCSP_CERTID(NULL,&p,len);
	    if (!id) {
		OCSP_REQUEST_free(req);
		croak("failed to get OCSP certid from string");
	    }
	    OCSP_request_add0_id(req,id);
	}
	RETVAL = req;
    OUTPUT:
	RETVAL



int
SSL_OCSP_response_verify(ssl,rsp,svreq=NULL,flags=0)
	SSL *ssl
	OCSP_RESPONSE *rsp
	SV *svreq
	unsigned long flags
    PREINIT:
	SSL_CTX *ctx;
	X509_STORE *store;
	OCSP_BASICRESP *bsr;
	OCSP_REQUEST *req = NULL;
	int i;
    CODE:
	if (!ssl) croak("not a SSL object");
	ctx = SSL_get_SSL_CTX(ssl);
	if (!ctx) croak("invalid SSL object - no context");

	bsr = OCSP_response_get1_basic(rsp);
	if (!bsr) croak("invalid OCSP response");

	/* if we get a nonce it should match our nonce, if we get no nonce
	 * it was probably pre-signed */
	if (svreq && SvOK(svreq) &&
	    (req = INT2PTR(OCSP_REQUEST*,SvIV(svreq)))) {
	    i = OCSP_check_nonce(req,bsr);
	    if ( i <= 0 ) {
		if (i == -1) {
		    TRACE(2,"SSL_OCSP_response_verify: no nonce in response");
		} else {
		    OCSP_BASICRESP_free(bsr);
		    croak("nonce in OCSP response does not match request");
		}
	    }
	}

	RETVAL = 0;
	if ((store = SSL_CTX_get_cert_store(ctx))) {
	    /* add the SSL uchain to the uchain of the OCSP basic response, this
	     * looks like the easiest way to handle the case where the OCSP
	     * response does not contain the chain up to the trusted root */
	    STACK_OF(X509) *chain = SSL_get_peer_cert_chain(ssl);
	    for(i=0;i<sk_X509_num(chain);i++) {
		OCSP_basic_add1_cert(bsr, sk_X509_value(chain,i));
	    }
	    TRACE(1,"run basic verify");
	    RETVAL = OCSP_basic_verify(bsr, NULL, store, flags);
	    if (chain && !RETVAL) {
		/* some CAs don't add a certificate to their OCSP responses and
		 * openssl does not include the trusted CA which signed the
		 * lowest chain certificate when looking for the signer.
		 * So find this CA ourself and retry verification. */
		X509 *issuer;
		X509 *last = sk_X509_value(chain,sk_X509_num(chain)-1);
		ERR_clear_error(); /* clear error from last OCSP_basic_verify */
		if (last && (issuer = find_issuer(last,store,chain))) {
		    OCSP_basic_add1_cert(bsr, issuer);
		    X509_free(issuer);
		    TRACE(1,"run OCSP_basic_verify with issuer for last chain element");
		    RETVAL = OCSP_basic_verify(bsr, NULL, store, flags);
		}
	    }
	}
	OCSP_BASICRESP_free(bsr);
    OUTPUT:
	RETVAL


void
OCSP_response_results(rsp,...)
	OCSP_RESPONSE *rsp
    PPCODE:
	OCSP_BASICRESP *bsr;
	int i,want_array;
	time_t nextupd = 0;
	time_t gmtoff = -1;
	int getall,sksn;

	bsr = OCSP_response_get1_basic(rsp);
	if (!bsr) croak("invalid OCSP response");

	want_array = (GIMME == G_ARRAY);
	getall = (items <= 1);
	sksn = OCSP_resp_count(bsr);

	for(i=0; i < (getall ? sksn : items-1); i++) {
	    const char *error = NULL;
	    OCSP_SINGLERESP *sir = NULL;
	    OCSP_CERTID *certid = NULL;
	    SV *idsv = NULL;
	    int first, status, revocationReason;
	    ASN1_GENERALIZEDTIME *revocationTime, *thisupdate, *nextupdate;

	    if(getall) {
		sir = OCSP_resp_get0(bsr,i);
	    } else {
		STRLEN len;
		const unsigned char *p;

		idsv = ST(i+1);
		if (!SvOK(idsv)) croak("undefined certid in arguments");
		p = (unsigned char*)SvPV(idsv,len);
		if (!(certid = d2i_OCSP_CERTID(NULL,&p,len))) {
		    error = "failed to get OCSP certid from string";
		    goto end;
		}
                first = OCSP_resp_find(bsr, certid, -1); /* Find the first matching */
                if (first >= 0)
                    sir = OCSP_resp_get0(bsr,first);
	    }

	    if (sir)
	    {
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
		status = OCSP_single_get0_status(sir, &revocationReason, &revocationTime, &thisupdate, &nextupdate);
#else
		status = sir->certStatus->type;
		if (status == V_OCSP_CERTSTATUS_REVOKED)
		    revocationTime = sir->certStatus->value.revoked->revocationTime;
		thisupdate = sir->thisUpdate;
		nextupdate = sir->nextUpdate;
#endif
		if (status == V_OCSP_CERTSTATUS_REVOKED) {
		    error = "certificate status is revoked";
		} else if (status != V_OCSP_CERTSTATUS_GOOD) {
		    error = "certificate status is unknown";
		}
		else if (!OCSP_check_validity(thisupdate, nextupdate, 0, -1)) {
		    error = "response not yet valid or expired";
		}
	    } else {
	        error = "cannot find entry for certificate in OCSP response";
	    }

	    end:
	    if (want_array) {
		AV *idav = newAV();
		if (!idsv) {
		    /* getall: create new SV with OCSP_CERTID */
		    unsigned char *pi,*pc;
#if OPENSSL_VERSION_NUMBER >= 0x10100003L && !defined(LIBRESSL_VERSION_NUMBER)
		    int len = i2d_OCSP_CERTID((OCSP_CERTID *)OCSP_SINGLERESP_get0_id(sir),NULL);
#else
		    int len = i2d_OCSP_CERTID(sir->certId,NULL);
#endif
		    if(!len) continue;
		    Newx(pc,len,unsigned char);
		    if (!pc) croak("out of memory");
		    pi = pc;
#if OPENSSL_VERSION_NUMBER >= 0x10100003L && !defined(LIBRESSL_VERSION_NUMBER)
		    i2d_OCSP_CERTID((OCSP_CERTID *)OCSP_SINGLERESP_get0_id(sir),&pi);
#else
		    i2d_OCSP_CERTID(sir->certId,&pi);
#endif
		    idsv = newSVpv((char*)pc,len);
		    Safefree(pc);
		} else {
		    /* reuse idsv from ST(..), but increment refcount */
		    idsv = SvREFCNT_inc(idsv);
		}
		av_push(idav, idsv);
		av_push(idav, error ? newSVpv(error,0) : newSV(0));
		if (sir) {
		    HV *details = newHV();
		    av_push(idav,newRV_noinc((SV*)details));
		    hv_store(details,"statusType",10,
			newSViv(status),0);
		    if (nextupdate) hv_store(details,"nextUpdate",10,
			newSViv(ASN1_TIME_timet(nextupdate, &gmtoff)),0);
		    if (thisupdate) hv_store(details,"thisUpdate",10,
			newSViv(ASN1_TIME_timet(thisupdate, &gmtoff)),0);
		    if (status == V_OCSP_CERTSTATUS_REVOKED) {
#if OPENSSL_VERSION_NUMBER < 0x10100000L
			OCSP_REVOKEDINFO *rev = sir->certStatus->value.revoked;
			revocationReason = ASN1_ENUMERATED_get(rev->revocationReason);
#endif
			hv_store(details,"revocationTime",14,newSViv(ASN1_TIME_timet(revocationTime, &gmtoff)),0);
			hv_store(details,"revocationReason",16,newSViv(revocationReason),0);
			hv_store(details,"revocationReason_str",20,newSVpv(
		            OCSP_crl_reason_str(revocationReason),0),0);
		    }
		}
		XPUSHs(sv_2mortal(newRV_noinc((SV*)idav)));
	    } else if (!error) {
		/* compute lowest nextUpdate */
		time_t nu = ASN1_TIME_timet(nextupdate, &gmtoff);
		if (!nextupd || nextupd>nu) nextupd = nu;
	    }

	    if (certid) OCSP_CERTID_free(certid);
	    if (error && !want_array) {
		OCSP_BASICRESP_free(bsr);
		croak("%s", error);
	    }
	}
	OCSP_BASICRESP_free(bsr);
	if (!want_array)
	    XPUSHs(sv_2mortal(newSViv(nextupd)));



#endif

#if OPENSSL_VERSION_NUMBER >= 0x10002000L && !defined(OPENSSL_NO_TLSEXT)

int
SSL_CTX_set_alpn_select_cb(ctx,callback,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * callback
        SV * data
    CODE:
        RETVAL = 1;
        if (callback==NULL || !SvOK(callback)) {
            SSL_CTX_set_alpn_select_cb(ctx, NULL, NULL);
            cb_data_advanced_put(ctx, "alpn_select_cb!!func", NULL);
            cb_data_advanced_put(ctx, "alpn_select_cb!!data", NULL);
            PR1("SSL_CTX_set_alpn_select_cb - undef\n");
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVAV)) {
            /* callback param array ref like ['proto1','proto2'] */
            cb_data_advanced_put(ctx, "alpn_select_cb!!func", NULL);
            cb_data_advanced_put(ctx, "alpn_select_cb!!data", newSVsv(callback));
            SSL_CTX_set_alpn_select_cb(ctx, alpn_select_cb_invoke, ctx);
            PR2("SSL_CTX_set_alpn_select_cb - simple ctx=%p\n",ctx);
        }
        else if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV)) {
            cb_data_advanced_put(ctx, "alpn_select_cb!!func", newSVsv(callback));
            cb_data_advanced_put(ctx, "alpn_select_cb!!data", newSVsv(data));
            SSL_CTX_set_alpn_select_cb(ctx, alpn_select_cb_invoke, ctx);
            PR2("SSL_CTX_set_alpn_select_cb - advanced ctx=%p\n",ctx);
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
SSL_CTX_set_alpn_protos(ctx,data=&PL_sv_undef)
        SSL_CTX * ctx
        SV * data
    PREINIT:
        unsigned char *alpn_data;
        unsigned char alpn_len;

    CODE:
        RETVAL = -1;

        if (!SvROK(data) || (SvTYPE(SvRV(data)) != SVt_PVAV))
            croak("Net::SSLeay: CTX_set_alpn_protos needs a single array reference.\n");
        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(data), NULL);
        Newx(alpn_data, alpn_len, unsigned char);
        if (!alpn_data)
            croak("Net::SSLeay: CTX_set_alpn_protos could not allocate memory.\n");
        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(data), alpn_data);
        RETVAL = SSL_CTX_set_alpn_protos(ctx, alpn_data, alpn_len);
        Safefree(alpn_data);

    OUTPUT:
        RETVAL

int
SSL_set_alpn_protos(ssl,data=&PL_sv_undef)
        SSL * ssl
        SV * data
    PREINIT:
        unsigned char *alpn_data;
        unsigned char alpn_len;

    CODE:
        RETVAL = -1;

        if (!SvROK(data) || (SvTYPE(SvRV(data)) != SVt_PVAV))
            croak("Net::SSLeay: set_alpn_protos needs a single array reference.\n");
        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(data), NULL);
        Newx(alpn_data, alpn_len, unsigned char);
        if (!alpn_data)
            croak("Net::SSLeay: set_alpn_protos could not allocate memory.\n");
        alpn_len = next_proto_helper_AV2protodata((AV*)SvRV(data), alpn_data);
        RETVAL = SSL_set_alpn_protos(ssl, alpn_data, alpn_len);
        Safefree(alpn_data);

    OUTPUT:
        RETVAL

void
P_alpn_selected(s)
        const SSL *s
    PREINIT:
        const unsigned char *data;
        unsigned int len;
    PPCODE:
        SSL_get0_alpn_selected(s, &data, &len);
        XPUSHs(sv_2mortal(newSVpv((char *)data, len)));

#endif

#if OPENSSL_VERSION_NUMBER >= 0x10001000L

void
SSL_export_keying_material(ssl, outlen, label, context=&PL_sv_undef)
        SSL * ssl
        int outlen
        SV * context
    PREINIT:
        unsigned char *  out;
        STRLEN llen;
        STRLEN contextlen = 0;
        char *context_arg = NULL;
        int use_context = 0;
        int ret;
    INPUT:
        char *  label = SvPV( ST(2), llen);
    PPCODE:
        Newx(out, outlen, unsigned char);

        if (context != &PL_sv_undef) {
            use_context = 1;
            context_arg = SvPV( ST(3), contextlen);
        }
        ret = SSL_export_keying_material(ssl, out, outlen, label, llen, (unsigned char*)context_arg, contextlen, use_context);
        PUSHs(sv_2mortal(ret>0 ? newSVpvn((const char *)out, outlen) : newSV(0)));
        EXTEND(SP, 1);
	Safefree(out);

#endif

#if OPENSSL_VERSION_NUMBER >= 0x30000000L

OSSL_LIB_CTX *
OSSL_LIB_CTX_get0_global_default()


OSSL_PROVIDER *
OSSL_PROVIDER_load(SV *libctx, const char *name)
    CODE:
        OSSL_LIB_CTX *ctx = NULL;
        if (libctx != &PL_sv_undef)
	    ctx = INT2PTR(OSSL_LIB_CTX *, SvIV(libctx));
        RETVAL = OSSL_PROVIDER_load(ctx, name);
        if (RETVAL == NULL)
	    XSRETURN_UNDEF;
    OUTPUT:
	  RETVAL

OSSL_PROVIDER *
OSSL_PROVIDER_try_load(SV *libctx, const char *name, int retain_fallbacks)
    CODE:
        OSSL_LIB_CTX *ctx = NULL;
        if (libctx != &PL_sv_undef)
	    ctx = INT2PTR(OSSL_LIB_CTX *, SvIV(libctx));
        RETVAL = OSSL_PROVIDER_try_load(ctx, name, retain_fallbacks);
        if (RETVAL == NULL)
	    XSRETURN_UNDEF;
    OUTPUT:
	  RETVAL

int
OSSL_PROVIDER_unload(OSSL_PROVIDER *prov)

int
OSSL_PROVIDER_available(SV *libctx, const char *name)
    CODE:
        OSSL_LIB_CTX *ctx = NULL;
        if (libctx != &PL_sv_undef)
	    ctx = INT2PTR(OSSL_LIB_CTX *, SvIV(libctx));
        RETVAL = OSSL_PROVIDER_available(ctx, name);
    OUTPUT:
	  RETVAL

int
OSSL_PROVIDER_do_all(SV *libctx, SV *perl_cb, SV *perl_cbdata = &PL_sv_undef)
    PREINIT:
        simple_cb_data_t* cbdata = NULL;
    CODE:
        OSSL_LIB_CTX *ctx = NULL;
        if (libctx != &PL_sv_undef)
	    ctx = INT2PTR(OSSL_LIB_CTX *, SvIV(libctx));

        /* setup our callback */
        cbdata = simple_cb_data_new(perl_cb, perl_cbdata);
        RETVAL = OSSL_PROVIDER_do_all(ctx, ossl_provider_do_all_cb_invoke, cbdata);
        simple_cb_data_free(cbdata);
    OUTPUT:
        RETVAL

const char *
OSSL_PROVIDER_get0_name(const OSSL_PROVIDER *prov)

int
OSSL_PROVIDER_self_test(const OSSL_PROVIDER *prov)

#endif

#define REM_EOF "/* EOF - SSLeay.xs */"

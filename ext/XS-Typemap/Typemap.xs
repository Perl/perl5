/*
   XS code to test the typemap entries

   Copyright (C) 2001 Tim Jenness.
   All Rights Reserved

*/

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */

/* Prototypes for external functions */
FILE * xsfopen( const char * );
int xsfclose( FILE * );
int xsfprintf( FILE *, const char *);

/* Type definitions required for the XS typemaps */
typedef SV * SVREF; /* T_SVREF */
typedef int SysRet; /* T_SYSRET */
typedef int Int;    /* T_INT */
typedef int intRef; /* T_PTRREF */
typedef int intObj; /* T_PTROBJ */
typedef int intRefIv; /* T_REF_IV_PTR */
typedef int intArray; /* T_ARRAY */
typedef int intTINT; /* T_INT */
typedef int intTLONG; /* T_LONG */
typedef short shortOPQ;   /* T_OPAQUE */
typedef int intOpq;   /* T_OPAQUEPTR */
typedef unsigned intUnsigned; /* T_U_INT */
typedef PerlIO inputfh; /* T_IN */
typedef PerlIO outputfh; /* T_OUT */

/* A structure to test T_OPAQUEPTR and T_PACKED */
struct t_opaqueptr {
  int a;
  int b;
  double c;
};

typedef struct t_opaqueptr astruct;
typedef struct t_opaqueptr anotherstruct;

/* Some static memory for the tests */
static I32 xst_anint;
static intRef xst_anintref;
static intObj xst_anintobj;
static intRefIv xst_anintrefiv;
static intOpq xst_anintopq;

/* A different type to refer to for testing the different
 * AV*, HV*, etc typemaps */
typedef AV AV_FIXED;
typedef HV HV_FIXED;
typedef CV CV_FIXED;
typedef SVREF SVREF_FIXED;

/* Helper functions */

/* T_ARRAY - allocate some memory */
intArray * intArrayPtr( int nelem ) {
    intArray * array;
    Newx(array, nelem, intArray);
    return array;
}

/* test T_PACKED */
#define XS_pack_anotherstructPtr(out, in)                  \
    STMT_START {                                           \
      HV *hash = newHV();                                  \
      hv_stores(hash, "a", newSViv((in)->a));              \
      hv_stores(hash, "b", newSViv((in)->b));              \
      hv_stores(hash, "c", newSVnv((in)->c));              \
      sv_setsv((out), sv_2mortal(newRV_noinc((SV*)hash))); \
    } STMT_END

STATIC anotherstruct *
XS_unpack_anotherstructPtr(SV *in)
{
    dTHX; /* rats, this is expensive */
    /* this is similar to T_HVREF since we chose to use a hash */
    HV *inhash;
    SV **elem;
    anotherstruct *out;
    SV *const tmp = in;
    SvGETMAGIC(tmp);
    if (SvROK(tmp) && SvTYPE(SvRV(tmp)) == SVt_PVHV)
       inhash = (HV*)SvRV(tmp);
    else
        Perl_croak(aTHX_ "Argument is not a HASH reference");

    /* FIXME dunno if supposed to use perl mallocs here */
    Newxz(out, 1, anotherstruct);

    elem = hv_fetchs(inhash, "a", 0);
    if (elem == NULL)
      Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
    out->a = SvIV(*elem);

    elem = hv_fetchs(inhash, "b", 0);
    if (elem == NULL)
      Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
    out->b = SvIV(*elem);

    elem = hv_fetchs(inhash, "c", 0);
    if (elem == NULL)
      Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
    out->c = SvNV(*elem);

    return out;
}

/* test T_PACKEDARRAY */
#define XS_pack_anotherstructPtrPtr(out, in, cnt)          \
    STMT_START {                                           \
      UV i;                                                \
      AV *ary = newAV();                                   \
      for (i = 0; i < cnt; ++i) {                          \
        HV *hash = newHV();                                \
        hv_stores(hash, "a", newSViv((in)[i]->a));         \
        hv_stores(hash, "b", newSViv((in)[i]->b));         \
        hv_stores(hash, "c", newSVnv((in)[i]->c));         \
        av_push(ary, newRV_noinc((SV*)hash));              \
      }                                                    \
      sv_setsv((out), sv_2mortal(newRV_noinc((SV*)ary)));  \
    } STMT_END

STATIC anotherstruct **
XS_unpack_anotherstructPtrPtr(SV *in)
{
    dTHX; /* rats, this is expensive */
    /* this is similar to T_HVREF since we chose to use a hash */
    HV *inhash;
    AV *inary;
    SV **elem;
    anotherstruct **out;
    UV nitems, i;
    SV *tmp;

    /* safely deref the input array ref */
    tmp = in;
    SvGETMAGIC(tmp);
    if (SvROK(tmp) && SvTYPE(SvRV(tmp)) == SVt_PVAV)
       inary = (AV*)SvRV(tmp);
    else
        Perl_croak(aTHX_ "Argument is not an ARRAY reference");

    nitems = av_len(inary) + 1;

    /* FIXME dunno if supposed to use perl mallocs here */
    /* N+1 elements so we know the last one is NULL */
    Newxz(out, nitems+1, anotherstruct*);

    /* WARNING: in real code, we'd have to Safefree() on exception, but
     *          since we're testing perl, if we croak() here, stuff is
     *          rotten anyway! */
    for (i = 0; i < nitems; ++i) {
      Newxz(out[i], 1, anotherstruct);
      elem = av_fetch(inary, i, 0);
      if (elem == NULL)
        Perl_croak(aTHX_ "Shouldn't happen: av_fetch returns NULL");
      tmp = *elem;
      SvGETMAGIC(tmp);
      if (SvROK(tmp) && SvTYPE(SvRV(tmp)) == SVt_PVHV)
         inhash = (HV*)SvRV(tmp);
      else
          Perl_croak(aTHX_ "Array element %u is not a HASH reference", i);

      elem = hv_fetchs(inhash, "a", 0);
      if (elem == NULL)
        Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
      out[i]->a = SvIV(*elem);

      elem = hv_fetchs(inhash, "b", 0);
      if (elem == NULL)
        Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
      out[i]->b = SvIV(*elem);

      elem = hv_fetchs(inhash, "c", 0);
      if (elem == NULL)
        Perl_croak(aTHX_ "Shouldn't happen: hv_fetchs returns NULL");
      out[i]->c = SvNV(*elem);

    }

    return out;
}

/* no special meaning as far as typemaps are concerned,
 * just for convenience */
void
XS_release_anotherstructPtrPtr(anotherstruct **in)
{
  unsigned int i = 0;
  while (in[i] != NULL)
    Safefree(in[i++]);
  Safefree(in);
}


MODULE = XS::Typemap   PACKAGE = XS::Typemap

PROTOTYPES: DISABLE

TYPEMAP: <<END_OF_TYPEMAP

# Typemap file for typemap testing
# includes bonus typemap entries
# Mainly so that all the standard typemaps can be exercised even when
# there is not a corresponding type explicitly identified in the standard
# typemap

svtype           T_ENUM
intRef *         T_PTRREF
intRef           T_IV
intObj *         T_PTROBJ
intObj           T_IV
intRefIv *       T_REF_IV_PTR
intRefIv         T_IV
intArray *       T_ARRAY
intOpq           T_IV
intOpq   *       T_OPAQUEPTR
intUnsigned      T_U_INT
intTINT          T_INT
intTLONG         T_LONG
shortOPQ         T_OPAQUE
shortOPQ *       T_OPAQUEPTR
astruct *        T_OPAQUEPTR
anotherstruct *  T_PACKED
anotherstruct ** T_PACKEDARRAY
AV_FIXED *	 T_AVREF_REFCOUNT_FIXED
HV_FIXED *	 T_HVREF_REFCOUNT_FIXED
CV_FIXED *	 T_CVREF_REFCOUNT_FIXED
SVREF_FIXED	 T_SVREF_REFCOUNT_FIXED
inputfh          T_IN
outputfh         T_OUT

END_OF_TYPEMAP

=head1 TYPEMAPS

The more you think about interfacing between two languages, the more
you'll realize that the majority of programmer effort has to go into
converting between the data structures that are native to either of
the languages involved. This trumps other matter such as differing
calling conventions because the problem space is so much greater.
There are simply more ways to shove data into memory than there are
ways to implement a function call.

Perl XS' attempt at a solution to this is the concept of typemaps.
At an abstract level, a Perl XS typemap is nothing but a recipe for
converting from a certain Perl data structure to a certain C
data structure and/or vice versa. Since there can be C types that
are sufficiently similar to warrant converting with the same logic,
XS typemaps are represented by a unique identifier, called XS type
henceforth in this document. You can then tell the XS compiler that
multiple C types are to be mapped with the same XS typemap.

In your XS code, when you define an argument with a C type or when
you are using a C<CODE:> and an C<OUTPUT:> section together with a
C return type of your XSUB, it'll be the typemapping mechanism that
makes this easy.

=head2 Anatomy of a typemap File

Traditionally, typemaps needed to be written to a separate file,
conventionally called C<typemap>. With ExtUtils::ParseXS (the XS
compiler) version 3.00 or better (comes with perl 5.16), typemaps
can also be embedded directly into your XS code using a HERE-doc
like syntax:

  TYPEMAP: <<HERE
  ...
  HERE

where C<HERE> can be replaced by other identifiers like with normal
Perl HERE-docs. All details below about the typemap textual format
remain valid.

A typemap file generally has three sections: The C<TYPEMAP>
section is used to associate C types with XS type identifiers.
The C<INPUT> section is used to define the typemaps for I<input>
into the XSUB from Perl, and the C<OUTPUT> section has the opposite
conversion logic for getting data out of an XSUB back into Perl.

Each section is started by the section name in capital letters on a
line of its own. A typemap file implicitly starts in the C<TYPEMAP>
section. Each type of section can appear an arbitrary number of times
and does not have to appear at all. For example, a typemap file may
lack C<INPUT> and C<OUTPUT> sections if all it needs to do is
associate additional C types with core XS types like T_PTROBJ.
Lines that start with a hash C<#> are considered comments and ignored
in the C<TYPEMAP> section, but are considered significant in C<INPUT>
and C<OUTPUT>. Blank lines are generally ignored.

The C<TYPEMAP> section should contain one pair of C type and
XS type per line as follows. An example from the core typemap file:

  TYPEMAP
  # all variants of char* is handled by the T_PV typemap
  char *          T_PV
  const char *    T_PV
  unsigned char * T_PV
  ...

The C<INPUT> and C<OUTPUT> sections have identical formats, that is,
each unindented line starts a new in- or output map respectively.
A new in- or output map must start with the name of the XS type to
map on a line by itself, followed by the code that implements it
indented on the following lines. Example:

  INPUT
  T_PV
    $var = ($type)SvPV_nolen($arg)
  T_PTR
    $var = INT2PTR($type,SvIV($arg))

We'll get to the meaning of those Perlish-looking variables in a
little bit.

Finally, here's an example of the full typemap file for mapping C
strings of the C<char *> type to Perl scalars/strings:

  TYPEMAP
  char *  T_PV
  
  INPUT
  T_PV
    $var = ($type)SvPV_nolen($arg)
  
  OUTPUT
  T_PV
    sv_setpv((SV*)$arg, $var);

=head2 The Role of the typemap File in Your Distribution

For CPAN distributions, you can assume that the XS types defined by
the perl core are already available. Additionally, the core typemap
has default XS types for a large number of C types. For example, if
you simply return a C<char *> from your XSUB, the core typemap will
have this C type associated with the T_PV XS type. That means your
C string will be copied into the PV (pointer value) slot of a new scalar
that will be returned from your XSUB to to Perl.

If you're developing a CPAN distribution using XS, you may add your own
file called F<typemap> to the distribution. That file may contain
typemaps that either map types that are specific to your code or that
override the core typemap file's mappings for common C types.

=head2 Sharing typemaps Between CPAN Distributions

Starting with ExtUtils::ParseXS version 3.13_01 (comes with perl 5.16
and better), it is rather easy to share typemap code between multiple
CPAN distributions. The general idea is to share it as a module that
offers a certain API and have the dependent modules declare that as a
built-time requirement and import the typemap into the XS. An example
of such a typemap-sharing module on CPAN is
C<ExtUtils::Typemaps::Basic>. Two steps to getting that module's
typemaps available in your code:

=over 4

=item *

Declare C<ExtUtils::Typemaps::Basic> as a build-time dependency
in C<Makefile.PL> (use C<BUILD_REQUIRES>), or in your C<Build.PL>
(use C<build_requires>).

=item *

Include the following line in the XS section of your XS file:
(don't break the line)

  INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd
                   -e "print embeddable_typemap(q{Basic})"

=back

=head2 Full Listing of Core Typemaps

Each C type is represented by an entry in the typemap file that
is responsible for converting perl variables (SV, AV, HV, CV, etc.)
to and from that type. The following sections list all XS types
that come with perl by default.

=over 4

=item T_SV

This simply passes the C representation of the Perl variable (an SV*)
in and out of the XS layer. This can be used if the C code wants
to deal directly with the Perl variable.

=cut

SV *
T_SV( sv )
  SV * sv
 CODE:
  /* create a new sv for return that is a copy of the input
     do not simply copy the pointer since the SV will be marked
     mortal by the INPUT typemap when it is pushed back onto the stack */
  RETVAL = sv_mortalcopy( sv );
  /* increment the refcount since the default INPUT typemap mortalizes
     by default and we don't want to decrement the ref count twice
     by mistake */
  SvREFCNT_inc(RETVAL);
 OUTPUT:
  RETVAL

=item T_SVREF

Used to pass in and return a reference to an SV.

Note that this typemap does not decrement the reference count
when returning the reference to an SV*.
See also: T_SVREF_REFCOUNT_FIXED

=cut

SVREF
T_SVREF( svref )
  SVREF svref
 CODE:
  RETVAL = svref;
 OUTPUT:
  RETVAL

=item T_SVREF_FIXED

Used to pass in and return a reference to an SV.
This is a fixed
variant of T_SVREF that decrements the refcount appropriately
when returning a reference to an SV*. Introduced in perl 5.15.4.

=cut

SVREF_FIXED
T_SVREF_REFCOUNT_FIXED( svref )
  SVREF_FIXED svref
 CODE:
  SvREFCNT_inc(svref);
  RETVAL = svref;
 OUTPUT:
  RETVAL

=item T_AVREF

From the perl level this is a reference to a perl array.
From the C level this is a pointer to an AV.

Note that this typemap does not decrement the reference count
when returning an AV*. See also: T_AVREF_REFCOUNT_FIXED

=cut

AV *
T_AVREF( av )
  AV * av
 CODE:
  RETVAL = av;
 OUTPUT:
  RETVAL

=item T_AVREF_REFCOUNT_FIXED

From the perl level this is a reference to a perl array.
From the C level this is a pointer to an AV. This is a fixed
variant of T_AVREF that decrements the refcount appropriately
when returning an AV*. Introduced in perl 5.15.4.

=cut

AV_FIXED*
T_AVREF_REFCOUNT_FIXED( av )
  AV_FIXED * av
 CODE:
  SvREFCNT_inc(av);
  RETVAL = av;
 OUTPUT:
  RETVAL

=item T_HVREF

From the perl level this is a reference to a perl hash.
From the C level this is a pointer to an HV.

Note that this typemap does not decrement the reference count
when returning an HV*. See also: T_HVREF_REFCOUNT_FIXED

=cut

HV *
T_HVREF( hv )
  HV * hv
 CODE:
  RETVAL = hv;
 OUTPUT:
  RETVAL

=item T_HVREF_REFCOUNT_FIXED

From the perl level this is a reference to a perl hash.
From the C level this is a pointer to an HV. This is a fixed
variant of T_HVREF that decrements the refcount appropriately
when returning an HV*. Introduced in perl 5.15.4.

=cut

HV_FIXED*
T_HVREF_REFCOUNT_FIXED( hv )
  HV_FIXED * hv
 CODE:
  SvREFCNT_inc(hv);
  RETVAL = hv;
 OUTPUT:
  RETVAL


=item T_CVREF

From the perl level this is a reference to a perl subroutine
(e.g. $sub = sub { 1 };). From the C level this is a pointer
to a CV.

Note that this typemap does not decrement the reference count
when returning an HV*. See also: T_HVREF_REFCOUNT_FIXED

=cut

CV *
T_CVREF( cv )
  CV * cv
 CODE:
  RETVAL = cv;
 OUTPUT:
  RETVAL

=item T_CVREF_REFCOUNT_FIXED

From the perl level this is a reference to a perl subroutine
(e.g. $sub = sub { 1 };). From the C level this is a pointer
to a CV.

This is a fixed
variant of T_HVREF that decrements the refcount appropriately
when returning an HV*. Introduced in perl 5.15.4.

=cut

CV_FIXED *
T_CVREF_REFCOUNT_FIXED( cv )
  CV_FIXED * cv
 CODE:
  SvREFCNT_inc(cv);
  RETVAL = cv;
 OUTPUT:
  RETVAL

=item T_SYSRET

The T_SYSRET typemap is used to process return values from system calls.
It is only meaningful when passing values from C to perl (there is
no concept of passing a system return value from Perl to C).

System calls return -1 on error (setting ERRNO with the reason)
and (usually) 0 on success. If the return value is -1 this typemap
returns C<undef>. If the return value is not -1, this typemap
translates a 0 (perl false) to "0 but true" (which
is perl true) or returns the value itself, to indicate that the
command succeeded.

The L<POSIX|POSIX> module makes extensive use of this type.

=cut

# Test a successful return

SysRet
T_SYSRET_pass()
 CODE:
  RETVAL = 0;
 OUTPUT:
  RETVAL

# Test failure

SysRet
T_SYSRET_fail()
 CODE:
  RETVAL = -1;
 OUTPUT:
  RETVAL

=item T_UV

An unsigned integer.

=cut

unsigned int
T_UV( uv )
  unsigned int uv
 CODE:
  RETVAL = uv;
 OUTPUT:
  RETVAL

=item T_IV

A signed integer. This is cast to the required integer type when
passed to C and converted to an IV when passed back to Perl.

=cut

long
T_IV( iv )
  long iv
 CODE:
  RETVAL = iv;
 OUTPUT:
  RETVAL

=item T_INT

A signed integer. This typemap converts the Perl value to a native
integer type (the C<int> type on the current platform). When returning
the value to perl it is processed in the same way as for T_IV.

Its behaviour is identical to using an C<int> type in XS with T_IV.

=cut

intTINT
T_INT( i )
  intTINT i
 CODE:
  RETVAL = i;
 OUTPUT:
  RETVAL

=item T_ENUM

An enum value. Used to transfer an enum component
from C. There is no reason to pass an enum value to C since
it is stored as an IV inside perl.

=cut

# The test should return the value for SVt_PVHV.
# 11 at the present time but we can't not rely on this
# for testing purposes.

svtype
T_ENUM()
 CODE:
  RETVAL = SVt_PVHV;
 OUTPUT:
  RETVAL

=item T_BOOL

A boolean type. This can be used to pass true and false values to and
from C.

=cut

bool
T_BOOL( in )
  bool in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_U_INT

This is for unsigned integers. It is equivalent to using T_UV
but explicitly casts the variable to type C<unsigned int>.
The default type for C<unsigned int> is T_UV.

=cut

intUnsigned
T_U_INT( uint )
  intUnsigned uint
 CODE:
  RETVAL = uint;
 OUTPUT:
  RETVAL

=item T_SHORT

Short integers. This is equivalent to T_IV but explicitly casts
the return to type C<short>. The default typemap for C<short>
is T_IV.

=cut

short
T_SHORT( s )
  short s
 CODE:
  RETVAL = s;
 OUTPUT:
  RETVAL

=item T_U_SHORT

Unsigned short integers. This is equivalent to T_UV but explicitly
casts the return to type C<unsigned short>. The default typemap for
C<unsigned short> is T_UV.

T_U_SHORT is used for type C<U16> in the standard typemap.

=cut

U16
T_U_SHORT( in )
  U16 in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL


=item T_LONG

Long integers. This is equivalent to T_IV but explicitly casts
the return to type C<long>. The default typemap for C<long>
is T_IV.

=cut

intTLONG
T_LONG( in )
  intTLONG in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_U_LONG

Unsigned long integers. This is equivalent to T_UV but explicitly
casts the return to type C<unsigned long>. The default typemap for
C<unsigned long> is T_UV.

T_U_LONG is used for type C<U32> in the standard typemap.

=cut

U32
T_U_LONG( in )
  U32 in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_CHAR

Single 8-bit characters.

=cut

char
T_CHAR( in );
  char in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL


=item T_U_CHAR

An unsigned byte.

=cut

unsigned char
T_U_CHAR( in );
  unsigned char in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL


=item T_FLOAT

A floating point number. This typemap guarantees to return a variable
cast to a C<float>.

=cut

float
T_FLOAT( in )
  float in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_NV

A Perl floating point number. Similar to T_IV and T_UV in that the
return type is cast to the requested numeric type rather than
to a specific type.

=cut

NV
T_NV( in )
  NV in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_DOUBLE

A double precision floating point number. This typemap guarantees to
return a variable cast to a C<double>.

=cut

double
T_DOUBLE( in )
  double in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_PV

A string (char *).

=cut

char *
T_PV( in )
  char * in
 CODE:
  RETVAL = in;
 OUTPUT:
  RETVAL

=item T_PTR

A memory address (pointer). Typically associated with a C<void *>
type.

=cut

# Pass in a value. Store the value in some static memory and
# then return the pointer

void *
T_PTR_OUT( in )
  int in;
 CODE:
  xst_anint = in;
  RETVAL = &xst_anint;
 OUTPUT:
  RETVAL

# pass in the pointer and return the value

int
T_PTR_IN( ptr )
  void * ptr
 CODE:
  RETVAL = *(int *)ptr;
 OUTPUT:
  RETVAL

=item T_PTRREF

Similar to T_PTR except that the pointer is stored in a scalar and the
reference to that scalar is returned to the caller. This can be used
to hide the actual pointer value from the programmer since it is usually
not required directly from within perl.

The typemap checks that a scalar reference is passed from perl to XS.

=cut

# Similar test to T_PTR
# Pass in a value. Store the value in some static memory and
# then return the pointer

intRef *
T_PTRREF_OUT( in )
  intRef in;
 CODE:
  xst_anintref = in;
  RETVAL = &xst_anintref;
 OUTPUT:
  RETVAL

# pass in the pointer and return the value

intRef
T_PTRREF_IN( ptr )
  intRef * ptr
 CODE:
  RETVAL = *ptr;
 OUTPUT:
  RETVAL



=item T_PTROBJ

Similar to T_PTRREF except that the reference is blessed into a class.
This allows the pointer to be used as an object. Most commonly used to
deal with C structs. The typemap checks that the perl object passed
into the XS routine is of the correct class (or part of a subclass).

The pointer is blessed into a class that is derived from the name
of type of the pointer but with all '*' in the name replaced with
'Ptr'.

=cut

# Similar test to T_PTRREF
# Pass in a value. Store the value in some static memory and
# then return the pointer

intObj *
T_PTROBJ_OUT( in )
  intObj in;
 CODE:
  xst_anintobj = in;
  RETVAL = &xst_anintobj;
 OUTPUT:
  RETVAL

# pass in the pointer and return the value

MODULE = XS::Typemap  PACKAGE = intObjPtr

intObj
T_PTROBJ_IN( ptr )
  intObj * ptr
 CODE:
  RETVAL = *ptr;
 OUTPUT:
  RETVAL

MODULE = XS::Typemap PACKAGE = XS::Typemap

=item T_REF_IV_REF

NOT YET

=item T_REF_IV_PTR

Similar to T_PTROBJ in that the pointer is blessed into a scalar object.
The difference is that when the object is passed back into XS it must be
of the correct type (inheritance is not supported).

The pointer is blessed into a class that is derived from the name
of type of the pointer but with all '*' in the name replaced with
'Ptr'.

=cut

# Similar test to T_PTROBJ
# Pass in a value. Store the value in some static memory and
# then return the pointer

intRefIv *
T_REF_IV_PTR_OUT( in )
  intRefIv in;
 CODE:
  xst_anintrefiv = in;
  RETVAL = &xst_anintrefiv;
 OUTPUT:
  RETVAL

# pass in the pointer and return the value

MODULE = XS::Typemap  PACKAGE = intRefIvPtr

intRefIv
T_REF_IV_PTR_IN( ptr )
  intRefIv * ptr
 CODE:
  RETVAL = *ptr;
 OUTPUT:
  RETVAL


MODULE = XS::Typemap PACKAGE = XS::Typemap

=item T_PTRDESC

NOT YET

=item T_REFREF

Similar to T_PTRREF, except the pointer stored in the referenced scalar
is dereferenced and copied to the output variable. This means that
T_REFREF is to T_PTRREF as T_OPAQUE is to T_OPAQUEPTR. All clear?

Only the INPUT part of this is implemented (Perl to XSUB) and there
are no known users in core or on CPAN.

=cut

=item T_REFOBJ

NOT YET

=item T_OPAQUEPTR

This can be used to store bytes in the string component of the
SV. Here the representation of the data is irrelevant to perl and the
bytes themselves are just stored in the SV. It is assumed that the C
variable is a pointer (the bytes are copied from that memory
location).  If the pointer is pointing to something that is
represented by 8 bytes then those 8 bytes are stored in the SV (and
length() will report a value of 8). This entry is similar to T_OPAQUE.

In principal the unpack() command can be used to convert the bytes
back to a number (if the underlying type is known to be a number).

This entry can be used to store a C structure (the number
of bytes to be copied is calculated using the C C<sizeof> function)
and can be used as an alternative to T_PTRREF without having to worry
about a memory leak (since Perl will clean up the SV).

=cut

intOpq *
T_OPAQUEPTR_IN( val )
  intOpq val
 CODE:
  xst_anintopq = val;
  RETVAL = &xst_anintopq;
 OUTPUT:
  RETVAL

intOpq
T_OPAQUEPTR_OUT( ptr )
  intOpq * ptr
 CODE:
  RETVAL = *ptr;
 OUTPUT:
  RETVAL

short
T_OPAQUEPTR_OUT_short( ptr )
  shortOPQ * ptr
 CODE:
  RETVAL = *ptr;
 OUTPUT:
  RETVAL

# Test it with a structure
astruct *
T_OPAQUEPTR_IN_struct( a,b,c )
  int a
  int b
  double c
 PREINIT:
  struct t_opaqueptr test;
 CODE:
  test.a = a;
  test.b = b;
  test.c = c;
  RETVAL = &test;
 OUTPUT:
  RETVAL

void
T_OPAQUEPTR_OUT_struct( test )
  astruct * test
 PPCODE:
  XPUSHs(sv_2mortal(newSViv(test->a)));
  XPUSHs(sv_2mortal(newSViv(test->b)));
  XPUSHs(sv_2mortal(newSVnv(test->c)));


=item T_OPAQUE

This can be used to store data from non-pointer types in the string
part of an SV. It is similar to T_OPAQUEPTR except that the
typemap retrieves the pointer directly rather than assuming it
is being supplied. For example, if an integer is imported into
Perl using T_OPAQUE rather than T_IV the underlying bytes representing
the integer will be stored in the SV but the actual integer value will not
be available. i.e. The data is opaque to perl.

The data may be retrieved using the C<unpack> function if the
underlying type of the byte stream is known.

T_OPAQUE supports input and output of simple types.
T_OPAQUEPTR can be used to pass these bytes back into C if a pointer
is acceptable.

=cut

shortOPQ
T_OPAQUE_IN( val )
  int val
 CODE:
  RETVAL = (shortOPQ)val;
 OUTPUT:
  RETVAL

IV
T_OPAQUE_OUT( val )
  shortOPQ val
 CODE:
  RETVAL = (IV)val;
 OUTPUT:
  RETVAL

=item Implicit array

xsubpp supports a special syntax for returning
packed C arrays to perl. If the XS return type is given as

  array(type, nelem)

xsubpp will copy the contents of C<nelem * sizeof(type)> bytes from
RETVAL to an SV and push it onto the stack. This is only really useful
if the number of items to be returned is known at compile time and you
don't mind having a string of bytes in your SV.  Use T_ARRAY to push a
variable number of arguments onto the return stack (they won't be
packed as a single string though).

This is similar to using T_OPAQUEPTR but can be used to process more than
one element.

=cut

array(int,3)
T_OPAQUE_array( a,b,c)
  int a
  int b
  int c
 PREINIT:
  int array[3];
 CODE:
  array[0] = a;
  array[1] = b;
  array[2] = c;
  RETVAL = array;
 OUTPUT:
  RETVAL


=item T_PACKED

Calls user-supplied functions for conversion. For C<OUTPUT>
(XSUB to Perl), a function named C<XS_pack_$ntype> is called
with the output Perl scalar and the C variable to convert from.
C<$ntype> is the normalized C type that is to be mapped to
Perl. Normalized means that all C<*> are replaced by the
string C<Ptr>. The return value of the function is ignored.

Conversely for C<INPUT> (Perl to XSUB) mapping, the
function named C<XS_unpack_$ntype> is called with the input Perl
scalar as argument and the return value is cast to the mapped
C type and assigned to the output C variable.

An example conversion function for a typemapped struct
C<foo_t *> might be:

  static void
  XS_pack_foo_tPtr(SV *out, foo_t *in)
  {
    dTHX; /* alas, signature does not include pTHX_ */
    HV* hash = newHV();
    hv_stores(hash, "int_member", newSViv(in->int_member));
    hv_stores(hash, "float_member", newSVnv(in->float_member));
    /* ... */

    /* mortalize as thy stack is not refcounted */
    sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hash)));
  }

The conversion from Perl to C is left as an exercise to the reader,
but the prototype would be:

  static foo_t *
  XS_unpack_foo_tPtr(SV *in);

Instead of an actual C function that has to fetch the thread context
using C<dTHX>, you can define macros of the same name and avoid the
overhead. Also, keep in mind to possibly free the memory allocated by
C<XS_unpack_foo_tPtr>.

=cut

void
T_PACKED_in(in)
  anotherstruct *in;
 PPCODE:
  mXPUSHi(in->a);
  mXPUSHi(in->b);
  mXPUSHn(in->c);
  Safefree(in);
  XSRETURN(3);

anotherstruct *
T_PACKED_out(a, b ,c)
  int a;
  int b;
  double c;
 CODE:
  Newxz(RETVAL, 1, anotherstruct);
  RETVAL->a = a;
  RETVAL->b = b;
  RETVAL->c = c;
 OUTPUT: RETVAL
 CLEANUP:
  Safefree(RETVAL);

=item T_PACKEDARRAY

T_PACKEDARRAY is similar to T_PACKED. In fact, the C<INPUT> (Perl
to XSUB) typemap is indentical, but the C<OUTPUT> typemap passes
an additional argument to the C<XS_pack_$ntype> function. This
third parameter indicates the number of elements in the output
so that the function can handle C arrays sanely. The variable
needs to be declared by the user and must have the name
C<count_$ntype> where C<$ntype> is the normalized C type name
as explained above. The signature of the function would be for
the example above and C<foo_t **>:

  static void
  XS_pack_foo_tPtrPtr(SV *out, foo_t *in, UV count_foo_tPtrPtr);

The type of the third parameter is arbitrary as far as the typemap
is concerned. It just has to be in line with the declared variable.

Of course, unless you know the number of elements in the
C<sometype **> C array, within your XSUB, the return value from
C<foo_t ** XS_unpack_foo_tPtrPtr(...)> will be hard to decypher.
Since the details are all up to the XS author (the typemap user),
there are several solutions, none of which particularly elegant.
The most commonly seen solution has been to allocate memory for
N+1 pointers and assign C<NULL> to the (N+1)th to facilitate
iteration.

Alternatively, using a customized typemap for your purposes in
the first place is probably preferrable.

=cut

void
T_PACKEDARRAY_in(in)
  anotherstruct **in;
 PREINIT:
  unsigned int i = 0;
 PPCODE:
  while (in[i] != NULL) {
    mXPUSHi(in[i]->a);
    mXPUSHi(in[i]->b);
    mXPUSHn(in[i]->c);
    ++i;
  }
  XS_release_anotherstructPtrPtr(in);
  XSRETURN(3*i);

anotherstruct **
T_PACKEDARRAY_out(...)
 PREINIT:
  unsigned int i, nstructs, count_anotherstructPtrPtr;
 CODE:
  if ((items % 3) != 0)
    croak("Need nitems divisible by 3");
  nstructs = (unsigned int)(items / 3);
  count_anotherstructPtrPtr = nstructs;
  Newxz(RETVAL, nstructs+1, anotherstruct *);
  for (i = 0; i < nstructs; ++i) {
    Newxz(RETVAL[i], 1, anotherstruct);
    RETVAL[i]->a = SvIV(ST(3*i));
    RETVAL[i]->b = SvIV(ST(3*i+1));
    RETVAL[i]->c = SvNV(ST(3*i+2));
  }
 OUTPUT: RETVAL
 CLEANUP:
  XS_release_anotherstructPtrPtr(RETVAL);

=item T_DATAUNIT

NOT YET

=item T_CALLBACK

NOT YET

=item T_ARRAY

This is used to convert the perl argument list to a C array
and for pushing the contents of a C array onto the perl
argument stack.

The usual calling signature is

  @out = array_func( @in );

Any number of arguments can occur in the list before the array but
the input and output arrays must be the last elements in the list.

When used to pass a perl list to C the XS writer must provide a
function (named after the array type but with 'Ptr' substituted for
'*') to allocate the memory required to hold the list. A pointer
should be returned. It is up to the XS writer to free the memory on
exit from the function. The variable C<ix_$var> is set to the number
of elements in the new array.

When returning a C array to Perl the XS writer must provide an integer
variable called C<size_$var> containing the number of elements in the
array. This is used to determine how many elements should be pushed
onto the return argument stack. This is not required on input since
Perl knows how many arguments are on the stack when the routine is
called. Ordinarily this variable would be called C<size_RETVAL>.

Additionally, the type of each element is determined from the type of
the array. If the array uses type C<intArray *> xsubpp will
automatically work out that it contains variables of type C<int> and
use that typemap entry to perform the copy of each element. All
pointer '*' and 'Array' tags are removed from the name to determine
the subtype.

=cut

# Test passes in an integer array and returns it along with
# the number of elements
# Pass in a dummy value to test offsetting

# Problem is that xsubpp does XSRETURN(1) because we arent
# using PPCODE. This means that only the first element
# is returned. KLUGE this by using CLEANUP to return before the
# end.
# Note: I read this as: The "T_ARRAY" typemap is really rather broken,
#       at least for OUTPUT. That is apart from the general design
#       weaknesses. --Steffen

intArray *
T_ARRAY( dummy, array, ... )
  int dummy = 0;
  intArray * array
 PREINIT:
  U32 size_RETVAL;
 CODE:
  dummy += 0; /* Fix -Wall */
  size_RETVAL = ix_array;
  RETVAL = array;
 OUTPUT:
  RETVAL
 CLEANUP:
  Safefree(array);
  XSRETURN(size_RETVAL);


=item T_STDIO

This is used for passing perl filehandles to and from C using
C<FILE *> structures.

=cut

FILE *
T_STDIO_open( file )
  const char * file
 CODE:
  RETVAL = xsfopen( file );
 OUTPUT:
  RETVAL

SysRet
T_STDIO_close( f )
  PerlIO * f
 PREINIT:
  FILE * stream;
 CODE:
  /* Get the FILE* */
  stream = PerlIO_findFILE( f );  
  /* Release the FILE* from the PerlIO system so that we do
     not close the file twice */
  PerlIO_releaseFILE(f,stream);
  /* Must release the file before closing it */
  RETVAL = xsfclose( stream );
 OUTPUT:
  RETVAL

int
T_STDIO_print( stream, string )
  FILE * stream
  const char * string
 CODE:
  RETVAL = xsfprintf( stream, string );
 OUTPUT:
  RETVAL


=item T_INOUT

This is used for passing perl filehandles to and from C using
C<PerlIO *> structures. The file handle can used for reading and
writing. This corresponds to the C<+E<lt>> mode, see also T_IN
and T_OUT.

See L<perliol> for more information on the Perl IO abstraction
layer. Perl must have been built with C<-Duseperlio>.

There is no check to assert that the filehandle passed from Perl
to C was created with the right C<open()> mode.

=cut

PerlIO *
T_INOUT(in)
  PerlIO *in;
 CODE:
  RETVAL = in; /* silly test but better than nothing */
 OUTPUT: RETVAL

=item T_IN

Same as T_INOUT, but the filehandle that is returned from C to Perl
can only be used for reading (mode C<E<lt>>). 

=cut

inputfh
T_IN(in)
  inputfh in;
 CODE:
  RETVAL = in; /* silly test but better than nothing */
 OUTPUT: RETVAL

=item T_OUT

Same as T_INOUT, but the filehandle that is returned from C to Perl
is set to use the open mode C<+E<gt>>.

=back

=cut

outputfh
T_OUT(in)
  outputfh in;
 CODE:
  RETVAL = in; /* silly test but better than nothing */
 OUTPUT: RETVAL


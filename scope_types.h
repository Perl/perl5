/* zero args */

#define SAVEt_ALLOC             0
#define SAVEt_CLEARPADRANGE     1
#define SAVEt_CLEARSV           2
#define SAVEt_REGCONTEXT        3

/* one arg */

#define SAVEt_TMPSFLOOR         4
#define SAVEt_BOOL              5
#define SAVEt_COMPILE_WARNINGS  6
#define SAVEt_COMPPAD           7
#define SAVEt_FREECOPHH         8
#define SAVEt_FREEOP            9
#define SAVEt_FREEPV            10
#define SAVEt_FREESV            11
#define SAVEt_I16               12
#define SAVEt_I32_SMALL         13
#define SAVEt_I8                14
#define SAVEt_INT_SMALL         15
#define SAVEt_MORTALIZESV       16
#define SAVEt_NSTAB             17
#define SAVEt_OP                18
#define SAVEt_PARSER            19
#define SAVEt_STACK_POS         20
#define SAVEt_READONLY_OFF      21
#define SAVEt_FREEPADNAME       22
#define SAVEt_STRLEN_SMALL      23

/* two args */

#define SAVEt_AV                24
#define SAVEt_DESTRUCTOR        25
#define SAVEt_DESTRUCTOR_X      26
#define SAVEt_GENERIC_PVREF     27
#define SAVEt_GENERIC_SVREF     28
#define SAVEt_GP                29
#define SAVEt_GVSV              30
#define SAVEt_HINTS             31
#define SAVEt_HPTR              32
#define SAVEt_HV                33
#define SAVEt_I32               34
#define SAVEt_INT               35
#define SAVEt_ITEM              36
#define SAVEt_IV                37
#define SAVEt_LONG              38
#define SAVEt_PPTR              39
#define SAVEt_SAVESWITCHSTACK   40
#define SAVEt_SHARED_PVREF      41
#define SAVEt_SPTR              42
#define SAVEt_STRLEN            43
#define SAVEt_SV                44
#define SAVEt_SVREF             45
#define SAVEt_VPTR              46
#define SAVEt_ADELETE           47
#define SAVEt_APTR              48
#define SAVEt_RCPV_FREE         49

/* three args */

#define SAVEt_HELEM             50
#define SAVEt_PADSV_AND_MORTALIZE 51
#define SAVEt_SET_SVFLAGS       52
#define SAVEt_GVSLOT            53
#define SAVEt_AELEM             54
#define SAVEt_DELETE            55
#define SAVEt_HINTS_HH          56

static const U8 leave_scope_arg_counts[] = {
    0, /* SAVEt_ALLOC              */
    0, /* SAVEt_CLEARPADRANGE      */
    0, /* SAVEt_CLEARSV            */
    0, /* SAVEt_REGCONTEXT         */
    1, /* SAVEt_TMPSFLOOR          */
    1, /* SAVEt_BOOL               */
    1, /* SAVEt_COMPILE_WARNINGS   */
    1, /* SAVEt_COMPPAD            */
    1, /* SAVEt_FREECOPHH          */
    1, /* SAVEt_FREEOP             */
    1, /* SAVEt_FREEPV             */
    1, /* SAVEt_FREESV             */
    1, /* SAVEt_I16                */
    1, /* SAVEt_I32_SMALL          */
    1, /* SAVEt_I8                 */
    1, /* SAVEt_INT_SMALL          */
    1, /* SAVEt_MORTALIZESV        */
    1, /* SAVEt_NSTAB              */
    1, /* SAVEt_OP                 */
    1, /* SAVEt_PARSER             */
    1, /* SAVEt_STACK_POS          */
    1, /* SAVEt_READONLY_OFF       */
    1, /* SAVEt_FREEPADNAME        */
    1, /* SAVEt_STRLEN_SMALL       */
    2, /* SAVEt_AV                 */
    2, /* SAVEt_DESTRUCTOR         */
    2, /* SAVEt_DESTRUCTOR_X       */
    2, /* SAVEt_GENERIC_PVREF      */
    2, /* SAVEt_GENERIC_SVREF      */
    2, /* SAVEt_GP                 */
    2, /* SAVEt_GVSV               */
    2, /* SAVEt_HINTS              */
    2, /* SAVEt_HPTR               */
    2, /* SAVEt_HV                 */
    2, /* SAVEt_I32                */
    2, /* SAVEt_INT                */
    2, /* SAVEt_ITEM               */
    2, /* SAVEt_IV                 */
    2, /* SAVEt_LONG               */
    2, /* SAVEt_PPTR               */
    2, /* SAVEt_SAVESWITCHSTACK    */
    2, /* SAVEt_SHARED_PVREF       */
    2, /* SAVEt_SPTR               */
    2, /* SAVEt_STRLEN             */
    2, /* SAVEt_SV                 */
    2, /* SAVEt_SVREF              */
    2, /* SAVEt_VPTR               */
    2, /* SAVEt_ADELETE            */
    2, /* SAVEt_APTR               */
    2, /* SAVEt_RCPV_FREE          */
    3, /* SAVEt_HELEM              */
    3, /* SAVEt_PADSV_AND_MORTALIZE*/
    3, /* SAVEt_SET_SVFLAGS        */
    3, /* SAVEt_GVSLOT             */
    3, /* SAVEt_AELEM              */
    3, /* SAVEt_DELETE             */
    3  /* SAVEt_HINTS_HH           */
};

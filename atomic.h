#ifdef __GNUC__

/*
 * These atomic operations copied from the linux kernel and altered
 * only slightly. I need to get official permission to distribute
 * under the Artistic License.
 */
/* We really need to integrate the atomic typedef with the typedef
 * used by sv_refcnt of an SV. It's possible that for CPUs like alpha
 * where we'd need to up sv_refcnt from 32 to 64 bits, we may be better
 * off sticking with EMULATE_ATOMIC_REFCOUNTS instead.
 */
typedef U32 atomic_t;	/* kludge */

#ifdef i386

#  ifdef NO_SMP
#    define LOCK ""
#  else
#    define LOCK "lock ; "
#  endif

#  define __atomic_fool_gcc(x) (*(struct { int a[100]; } *)x)
static __inline__ void atomic_inc(atomic_t *v)
{
    __asm__ __volatile__(
	    LOCK "incl %0"
	    :"=m" (__atomic_fool_gcc(v))
	    :"m" (__atomic_fool_gcc(v)));
}

static __inline__ int atomic_dec_and_test(atomic_t *v)
{
    unsigned char c;

    __asm__ __volatile__(
	    LOCK "decl %0; sete %1"
	    :"=m" (__atomic_fool_gcc(v)), "=qm" (c)
	    :"m" (__atomic_fool_gcc(v)));
    return c != 0;
}
#  else
/* XXX What symbol does gcc define for sparc64? */
#  ifdef sparc64
#    define __atomic_fool_gcc(x) ((struct { int a[100]; } *)x)
typedef U32 atomic_t;
extern __inline__ void atomic_add(int i, atomic_t *v)
{
        __asm__ __volatile__("
1:      lduw            [%1], %%g5
        add             %%g5, %0, %%g7
        cas             [%1], %%g5, %%g7
        sub             %%g5, %%g7, %%g5
        brnz,pn         %%g5, 1b
         nop"
        : /* No outputs */
        : "HIr" (i), "r" (__atomic_fool_gcc(v))
        : "g5", "g7", "memory");
}

extern __inline__ int atomic_sub_return(int i, atomic_t *v)
{
        unsigned long oldval;
        __asm__ __volatile__("
1:      lduw            [%2], %%g5
        sub             %%g5, %1, %%g7
        cas             [%2], %%g5, %%g7
        sub             %%g5, %%g7, %%g5
        brnz,pn         %%g5, 1b
         sub            %%g7, %1, %0"
        : "=&r" (oldval)
        : "HIr" (i), "r" (__atomic_fool_gcc(v))
        : "g5", "g7", "memory");
        return (int)oldval;
}

#define atomic_inc(v) atomic_add(1,(v))
#define atomic_dec_and_test(v) (atomic_sub_return(1, (v)) == 0)
/* Add further gcc architectures here */
#  else
#    define EMULATE_ATOMIC_REFCOUNTS
#  endif /* sparc64 */
#endif /* i386 */
#else
/* Add non-gcc native atomic operations here */
#  define EMULATE_ATOMIC_REFCOUNTS
#endif

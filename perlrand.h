/*    perlrand.h
 *
 *    Copyright (C) 1991-2026 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 *    Types and macros used for the random number generator.
 *
 */

#ifndef PERL_PERLRAND_H_
#define PERL_PERLRAND_H_

typedef struct { uint64_t state;  uint64_t inc; } pcg64_random_t;

#define PL_RANDOM_STATE_TYPE pcg64_random_t

#define Perl_pcg64_seed(seed) (Perl_pcg64_seed_r(&PL_random_state, (seed)))
#define Perl_pcg64_random_double() \
    (Perl_pcg64_random_double_r(&PL_random_state))

#ifdef PERL_CORE
/* uses a different source of randomness to avoid interfering with the results
 * of rand() */
#define Perl_internal_randd() \
    (Perl_pcg64_random_double_r(&PL_internal_random_state))
#define Perl_internal_rand_seed(seed) \
    (Perl_pcg64_seed_r(&PL_internal_random_state, (seed)))
#endif

#endif /* PERL_UTIL_H_ */

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */

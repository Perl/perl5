#ifdef PERL_EXT_RE_BUILD
#include "re_top.h"
#endif

#include "EXTERN.h"
#define PERL_IN_REGEX_ENGINE
#define PERL_IN_REGCOMP_ANY
#define PERL_IN_REGCOMP_TRIE_C
#include "perl.h"

#ifdef PERL_IN_XSUB_RE
#  include "re_comp.h"
#else
#  include "regcomp.h"
#endif

#include "invlist_inline.h"
#include "unicode_constants.h"
#include "regcomp_internal.h"

/* During construction each state's transitions are kept in a sorted list.
 * Element zero is a header, not a transition.  The header's forid field is
 * the next insertion position, so transitions occupy elements 1 through
 * forid - 1; its newstate field is the allocated capacity. */
#define TRIE_LIST_HEAD(state)      (trie->states[state].trans.list[0])
#define TRIE_LIST_ITEM(state, idx) (trie->states[state].trans.list[idx])
#define TRIE_LIST_CUR(state)       (TRIE_LIST_HEAD(state).forid)
#define TRIE_LIST_LEN(state)       (TRIE_LIST_HEAD(state).newstate)
#define TRIE_LIST_USED(state)      (trie->states[state].trans.list       \
                                    ? TRIE_LIST_CUR(state) - 1           \
                                    : 0)

#ifdef DEBUGGING
#  define TRIE_MARK_OCTET(octet)                                            \
    STMT_START {                                                           \
        TRIE_BITMAP_SET(trie, octet);                                       \
    } STMT_END
#else
#  define TRIE_MARK_OCTET(octet) NOOP
#endif

#ifndef RE_PREFER_LONG_TRIE
#  define RE_PREFER_LONG_TRIE 0
#endif


static U8
S_select_trie_op(pTHX_ const Size_t trie_room, const U32 needed_next)
{
    assert(needed_next <= U32_MAX);

    if (RE_PREFER_LONG_TRIE || needed_next > U16_MAX) {
        if (trie_room >= sizeof(tregnode_LTRIE)) {
            return LTRIE;
        }
        if (needed_next <= U16_MAX && trie_room >= sizeof(tregnode_TRIE)) {
            return TRIE;
        }
    }
    else {
        if (trie_room >= sizeof(tregnode_TRIE)) {
            return TRIE;
        }
        if (trie_room >= sizeof(tregnode_LTRIE)) {
            return LTRIE;
        }
    }

    return 0;
}


#ifdef DEBUGGING

#define TRIE_DEBUG_OCTET_USED(trie, octet) \
    BITMAP_TEST((trie)->bitmap, octet)

static void
S_dump_trie_char(pTHX_ const reg_trie_data *trie, U32 octet,
                 const int colwidth)
{
    octet = (U8)octet;

    PERL_UNUSED_VAR(trie);
    if (isPRINT_A(octet) && octet != ' ' && octet != '\\')
        re_printf("%*c", colwidth, (int)octet);
    else {
        re_printf("%*.*X", colwidth, 2, (unsigned)octet);
    }
}

/*
   dump_trie(trie)
   dump_trie_interim_list(trie,next_alloc)

   These routines dump out a trie in a somewhat readable format.
   The _interim_ variants are used for debugging the interim
   tables that are used to generate the final compressed
   representation which is what dump_trie expects.

   Part of the reason for their existence is to provide a form
   of documentation as to how the different representations function.

*/

/*
  Dumps the final compressed table form of the trie to Perl_debug_log.
  Used for debugging make_trie().
*/

static void
S_dump_trie(pTHX_ const struct reg_trie_data_ *trie, U32 depth)
{
    PERL_ARGS_ASSERT_DUMP_TRIE;

    U32 state;
    const int colwidth = 4;
    U32 word;
    DECLARE_AND_GET_RE_DEBUG_FLAGS;

    re_indentf("Char : %-6s%-6s%-4s ",
        depth+1, "Match","Base","Ofs" );

    for( state = 0 ; state < TRIE_ALPHABET_SIZE ; state++ ) {
        if (!TRIE_DEBUG_OCTET_USED(trie, state))
            continue;
        S_dump_trie_char(aTHX_ trie, state, colwidth);
    }
    re_printf("\n");
    re_indentf("State|-----------------------", depth+1);

    for( state = 0 ; state < TRIE_ALPHABET_SIZE ; state++ )
        if (TRIE_DEBUG_OCTET_USED(trie, state))
            re_printf("%.*s", colwidth, "--------");
    re_printf("\n");

    /* Prefix extraction leaves the old prefix states in the table, but the
     * executable trie begins at startstate.  Dump only the executable part. */
    for( state = trie->startstate ; state < trie->statecount ; state++ ) {
        const U32 base = trie->states[ state ].trans.base;

        re_indentf("#%4" UVXf "|", depth+1, (UV)state);

        if ( trie->states[ state ].wordnum ) {
            re_printf(" W%4X", trie->states[ state ].wordnum );
        } else {
            re_printf("%6s", "" );
        }

        re_printf(" @%4" UVXf " ", (UV)base );

        if ( base ) {
            U32 ofs = 0;

            while( ( base + ofs  < TRIE_ALPHABET_SIZE ) ||
                   ( base + ofs - TRIE_ALPHABET_SIZE < trie->lasttrans
                     && trie->trans[ base + ofs - TRIE_ALPHABET_SIZE ].check
                                                                    != state))
                    ofs++;

            re_printf("+%2" UVXf "[ ", (UV)ofs);

            for ( ofs = 0 ; ofs < TRIE_ALPHABET_SIZE ; ofs++ ) {
                if (!TRIE_DEBUG_OCTET_USED(trie, ofs))
                    continue;
                if ( ( base + ofs >= TRIE_ALPHABET_SIZE )
                        && ( base + ofs - TRIE_ALPHABET_SIZE
                                                        < trie->lasttrans )
                        && trie->trans[ base + ofs
                                    - TRIE_ALPHABET_SIZE ].check == state )
                {
                   re_printf("%*" UVXf, colwidth,
                    (UV)trie->trans[ base + ofs - TRIE_ALPHABET_SIZE ].next
                   );
                } else {
                    re_printf("%*s", colwidth,"   ." );
                }
            }

            re_printf("]");

        }
        re_printf("\n" );
    }
    re_indentf("word_info N:(prev,len)=",
                                depth);
    for (word = 1; word <= trie->wordcount; word++) {
        re_printf(" %d:(%d,%d)",
            (int)word, (int)(trie->wordinfo[word].prev),
            (int)(trie->wordinfo[word].len));
    }
    re_printf("\n" );
}
/*
  Dumps a fully constructed but uncompressed trie in list form.
  List tries are used for construction with the fixed 256-octet alphabet.
  Used for debugging make_trie().
*/
static void
S_dump_trie_interim_list(pTHX_ const struct reg_trie_data_ *trie,
                         U32 next_alloc, U32 depth)
{
    PERL_ARGS_ASSERT_DUMP_TRIE_INTERIM_LIST;

    U32 state;
    const int colwidth = 4;
    DECLARE_AND_GET_RE_DEBUG_FLAGS;

    /* print out the table precompression.  */
    re_indentf("State :Word | Transition Data\n",
            depth+1 );
    re_indentf("%s",
            depth+1, "------:-----+-----------------\n" );

    for( state = 1; state < next_alloc; state++ ) {
        U32 idx;

        re_indentf(" %4" UVXf " :",
            depth+1, (UV)state  );
        if ( ! trie->states[ state ].wordnum ) {
            re_printf("%5s| ","");
        } else {
            re_printf("W%4x| ",
                trie->states[ state ].wordnum
            );
        }
        for( idx = 1 ; idx <= TRIE_LIST_USED( state ) ; idx++ ) {
            const U32 forid = TRIE_LIST_ITEM(state, idx).forid;
            if (forid <= U8_MAX && isPRINT_A((U8)forid)
                    && forid != ' ' && forid != '\\' && forid != '\'') {
                re_printf(" '%c'", (int)forid);
            } else {
                re_printf("%*.*X", colwidth, 2, (unsigned)forid);
            }
            re_printf("=%4" UVXf " | ",
                      (UV)TRIE_LIST_ITEM(state, idx).newstate);
            if (!(idx % 10))
                re_printf("\n%*s| ",
                    (int)((depth * 2) + 14), "");
        }
        re_printf("\n");
    }
}

static void
S_dump_trie_physical_char(pTHX_ U32 octet)
{
    octet = (U8)octet;

    if (isPRINT_A(octet) && octet != ' ' && octet != '\\' && octet != '\'')
        re_printf(" '%c'", (int)octet);
    else
        re_printf("  %02X", (unsigned)octet);
}

static void
S_dump_trie_physical(pTHX_ const struct reg_trie_data_ *trie,
                     U32 physical, U32 depth)
{
    U32 slot;
    PERL_ARGS_ASSERT_DUMP_TRIE_PHYSICAL;

    re_indentf("Physical transitions:\n", depth+1);
    re_indentf("Physical| State | Word  | Base  | Ofs | Char | Next\n", depth+1);
    re_indentf("--------+-------+-------+-------+-----+------+-----\n", depth+1);
    for (slot = 0; slot < physical; slot++) {
        const reg_trie_trans * const trans = trie->trans + slot;
        if (!trans->next)
            continue;
        {
            const U32 state = trans->check;
            const U32 octet = slot + TRIE_ALPHABET_SIZE
                                     - trie->states[state].trans.base;
            re_indentf("%8" UVXf "| #%4" UVXf " |",
                       depth+1,
                       (UV)slot,
                       (UV)state);
            if (trie->states[state].wordnum)
                re_printf(" W%4" UVuf " |", (UV)trie->states[state].wordnum);
            else
                re_printf("       |");
            re_printf(" @%4" UVXf " | +%02" UVXf " |",
                      (UV)trie->states[state].trans.base,
                      (UV)octet);
            re_printf(" ");
            S_dump_trie_physical_char(aTHX_ octet);
            re_printf(" | %4" UVXf, (UV)trans->next);
            if (!trie->states[trans->next].trans.base
                    && trie->states[trans->next].wordnum)
                re_printf(" (W%" UVuf ")",
                          (UV)trie->states[trans->next].wordnum);
            re_printf("\n");
        }
    }
}

#endif


/* make_trie(startbranch,first,last,tail,word_count,octet_count,flags,depth)
  startbranch: the first branch in the whole branch sequence
  first      : start branch of sequence of branch-exact nodes.
               May be the same as startbranch
  last       : Thing following the last branch.
               May be the same as tail.
  tail       : item following the branch sequence
  count      : words in the sequence
  flags      : currently the OP() type we will be building one of /EXACT(|F|FA|FU|FU_SS|L|FLU8)/
  depth      : indent depth

Inplace optimizes a sequence of 2 or more Branch-Exact nodes into a TRIE node.

A trie is an N'ary tree where the branches are determined by digital
decomposition of the key. IE, at the root node you look up the 1st character and
follow that branch.  Repeat until you find the end of the branches. Nodes can
be marked as "accepting" meaning they represent a complete word. Eg:

  /he|she|his|hers/

would convert into the following structure. Numbers represent states; letters
following numbers represent valid transitions on the letter from that state.
If the number is in square brackets it represents an accepting state,
otherwise it will be in parenthesis.

      +-h->+-e->[3]-+-r->(8)-+-s->[9]
      |    |
      |   (2)
      |    |
     (1)   +-i->(6)-+-s->[7]
      |
      +-s->(3)-+-h->(4)-+-e->[5]

      Accept Word Mapping: 3 => 1 (he), 5 => 2 (she), 7 => 3 (his), 9 => 4 (hers)

This shows that when matching against the string 'hers' we will begin at state 1
read 'h' and move to state 2, read 'e' and move to state 3 which is accepting,
then read 'r' and go to state 8 followed by 's' which takes us to state 9 which
is also accepting. Thus we know that we can match both 'he' and 'hers' with a
single traverse. We store a mapping from accepting to state to which word was
matched, and then when we have multiple possibilities we try to complete the
rest of the regex in the order in which they occurred in the alternation.

The only prior NFA like behaviour that would be changed by the TRIE support is
the silent ignoring of duplicate alternations which are of the form:

 / (DUPE|DUPE) X? (?{ ... }) Y /x

Thus EVAL blocks following a trie may be called a different number of times with
and without the optimisation. With the optimisations dupes will be silently
ignored. This inconsistent behaviour of EVAL type nodes is well established as
the following demonstrates:

 'words'=~/(word|word|word)(?{ print $1 })[xyz]/

which prints out 'word' three times, but

 'words'=~/(word|word|word)(?{ print $1 })S/

which doesnt print it out at all. This is due to other optimisations kicking in.

Example of what happens on a structural level:

The regexp /(ac|ad|ab)+/ will produce the following debug output:

   1: CURLYM[1] {1,32767}(18)
   5:   BRANCH(8)
   6:     EXACT <ac>(16)
   8:   BRANCH(11)
   9:     EXACT <ad>(16)
  11:   BRANCH(14)
  12:     EXACT <ab>(16)
  16:   SUCCEED(0)
  17:   NOTHING(18)
  18: END(0)

This would be optimizable with startbranch = 5, first = 5, last = 16, tail = 16
and should turn into:

   1: CURLYM[1] {1,32767}(18)
   5:   TRIE(16)
        [Words:3 Chars Stored:6 Unique Chars:4 States:5 NCP:1]
          <ac>
          <ad>
          <ab>
  16:   SUCCEED(0)
  17:   NOTHING(18)
  18: END(0)

Cases where tail != last would be like /(?foo|bar)baz/:

   1: BRANCH(4)
   2:   EXACT <foo>(8)
   4: BRANCH(7)
   5:   EXACT <bar>(8)
   7: TAIL(8)
   8: EXACT <baz>(10)
  10: END(0)

which would be optimizable with startbranch = 1, first = 1, last = 7, tail = 8
and would end up looking like:

    1: TRIE(8)
      [Words:2 Chars Stored:6 Unique Chars:5 States:7 NCP:1]
        <foo>
        <bar>
   7: TAIL(8)
   8: EXACT <baz>(10)
  10: END(0)

    d = uv_to_utf8(d, uv);

is the recommended Unicode-aware way of saying

    *(d++) = uv;
*/

/* These node types contain UTF-8 source octets even when the pattern itself
 * is not marked UTF-8.  Ordinary non-UTF-8 nodes contain native octets; they
 * must not be identified as UTF-8 merely because their octets happen to form
 * a valid UTF-8 sequence. */
#define TRIE_SOURCE_UTF8(noper)                                             \
    (UTF || OP(noper) == EXACT_REQ8 || OP(noper) == EXACTFU_REQ8            \
        || OP(noper) == EXACTL || OP(noper) == EXACTFLU8)

PERL_STATIC_INLINE void
S_trie_list_push(reg_trie_data *trie, const U32 state, const U32 fid,
                 const U32 newstate, const U32 position)
{
    /* Element zero is the list header, not a transition.  Its forid field
     * stores the next insertion position (one past the last transition),
     * while newstate stores the allocated capacity.  Transition records
     * occupy elements 1 through forid - 1 and remain sorted by forid. */
    reg_trie_trans_le *list = trie->states[state].trans.list;
    const U32 used = list[0].forid;

    if (used >= list[0].newstate) {
        const U32 new_len = list[0].newstate * 2;
        Renew(list, new_len, reg_trie_trans_le);
        trie->states[state].trans.list = list;
        list[0].newstate = new_len;
    }

    /* An insertion at the end is the common fast path. */
    if (position < used)
        Move(&list[position], &list[position + 1], used - position,
             reg_trie_trans_le);
    list[position].forid = fid;
    list[position].newstate = newstate;
    list[0].forid++;
}

PERL_STATIC_INLINE void
S_trie_list_new(reg_trie_data *trie, const U32 state)
{
    /* These lists exist only while the trie is being constructed.  They use
     * the ordinary allocator and are released after the lists are packed
     * into trie->trans; the persistent trie arrays use the shared allocator. */
    /* Allocate initial storage for this state's transition list.  The
     * length is measured in transitions, not octets: it is the number of
     * transition records we can add before the list must be resized.  Most
     * states in a trie have only one transition, and only a few states have
     * several; when there is a branching state it is very often the first
     * state.  Give that state more room up front, while keeping later sparse
     * states cheap to create. */
    const U32 initial_len = (state == 1) ? 16 : 4;
    Newx(trie->states[state].trans.list, initial_len, reg_trie_trans_le);
    trie->states[state].trans.list[0].forid = 1;
    trie->states[state].trans.list[0].newstate = initial_len;
}

PERL_STATIC_INLINE void
S_trie_list_transition(reg_trie_data *trie, U32 *state, const U32 octet,
                       U32 *next_alloc, U32 *state_capacity,
                       U32 **prev_states, STRLEN *transition_count)
{
    U32 check;
    U32 newstate = 0;
    reg_trie_trans_le *list;
    const U32 current_state = *state;

    TRIE_MARK_OCTET(octet);
    if (!trie->states[current_state].trans.list)
        S_trie_list_new(trie, current_state);
    list = trie->states[current_state].trans.list;

    for (check = 1; check <= list[0].forid - 1; check++) {
        if (list[check].forid == octet) {
            newstate = list[check].newstate;
            break;
        }
        if (list[check].forid > octet)
            break;
    }
    if (!newstate) {
        if (*next_alloc >= *state_capacity) {
            const U32 old_capacity = *state_capacity;
            *state_capacity *= 2;
            trie->states = (reg_trie_state *)
                PerlMemShared_realloc(trie->states,
                                      *state_capacity * sizeof(reg_trie_state));
            Renew(*prev_states, *state_capacity, U32);
            Zero(trie->states + old_capacity,
                 *state_capacity - old_capacity, reg_trie_state);
            Zero(*prev_states + old_capacity,
                 *state_capacity - old_capacity, U32);
        }
        newstate = (*next_alloc)++;
        (*prev_states)[newstate] = current_state;
        if (!TRIE_LIST_USED(current_state)) {
            trie->states[current_state].min_octet = (U8)octet;
            trie->states[current_state].max_octet = (U8)octet;
        }
        else {
            if (octet < trie->states[current_state].min_octet)
                trie->states[current_state].min_octet = (U8)octet;
            if (octet > trie->states[current_state].max_octet)
                trie->states[current_state].max_octet = (U8)octet;
        }
        S_trie_list_push(trie, current_state, octet, newstate, check);
        (*transition_count)++;
    }
    *state = newstate;
}

PERL_STATIC_INLINE U32
S_trie_trans_state(const reg_trie_data *trie, const U32 state,
                   const U32 base, const U32 ucharcount, const U32 octet,
                   const U32 special, const U32 ubound)
{
    const U32 index = base - ucharcount + octet;

    /* The packed table stores a transition at base - alphabet_size + octet.
     * The check field confirms that the physical slot belongs to this state.
     * During Aho-Corasick construction, special is the fallback transition
     * used when the lookup is performed from the root state. */
    return base + octet >= ucharcount
        && base + octet < ubound
        && state == trie->trans[index].check
        && trie->trans[index].next
        ? trie->trans[index].next
        : state == 1 ? special : 0;
}


I32
Perl_make_trie(pTHX_ RExC_state_t *pRExC_state, regnode *startbranch,
                  regnode *first, regnode *last, regnode *tail,
                  U32 word_count, STRLEN octet_count, U32 flags, U32 depth)
{
    PERL_ARGS_ASSERT_MAKE_TRIE;

    /* Scan the source words and construct the trie in one pass. */
    reg_trie_data *trie;
    regnode *cur;
    STRLEN len = 0;
    UV uvc = 0;
    U32 curword = 0;
    U32 next_alloc = 0;
    U32 state_capacity = 0;
    regnode *jumper = NULL;
    regnode *nextbranch = NULL;
    regnode *lastbranch = NULL;
    regnode *convert = NULL;
    /* Temporary predecessor links.  Once the list representation has been
     * compressed, these links are used to reconstruct the wordinfo[].prev
     * chains for words which end at the same or an earlier state. */
    U32 *prev_states;
    /* A non-NULL folder identifies a folded trie and also means that its
     * transitions must use the processed UTF-8 representation. */
    const U8 * folder = NULL;
    /* Every trie transition is an octet.  In raw mode, native source octets
     * are used directly.  In processed mode, source codepoints are encoded
     * as UTF-8 octets before entering the trie.  Invariant codepoints have
     * the same representation in both modes; awkward and high codepoints
     * require processed mode. */
    bool trie_needs_codepoint_processing;

    /* Store the trie and, in debugging builds, its word list. */
#ifdef DEBUGGING
    const U32 data_slot = reg_add_data( pRExC_state, STR_WITH_LEN("ta"));
    AV *trie_words = NULL;
#else
    const U32 data_slot = reg_add_data( pRExC_state, STR_WITH_LEN("t"));
    STRLEN trie_charcount = 0;
#endif
    DECLARE_AND_GET_RE_DEBUG_FLAGS;

#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif
    switch (flags) {
        case EXACT: case EXACT_REQ8: case EXACTL: break;
        case EXACTFAA:
        case EXACTFUP:
        case EXACTFU:
        case EXACTFLU8:
            folder = PL_fold_latin1;
            break;
        case EXACTF:  folder = PL_fold; break;
        default: croak("panic! In trie construction, unknown node type %u %s", (unsigned) flags, REGNODE_NAME(flags) );
    }

    /* Trie data is immutable after compilation and is shared by cloned
     * regexes through refcounting.  Allocate the trie and its persistent
     * storage from the shared allocator, and use PerlMemShared_realloc() and
     * PerlMemShared_free() for it; pregfree() releases it only when the last
     * regex reference disappears. */
    trie = (reg_trie_data *) PerlMemShared_calloc( 1, sizeof(reg_trie_data) );
    trie->refcount = 1;
    trie->startstate = 1;
    trie->wordcount = word_count;
    trie->prop_flags = folder == NULL
        ? 0
        : folder == PL_fold
            ? TRIE_FOLD_NATIVE
            : TRIE_FOLD_UNICODE;
    RExC_rxi->data->data[ data_slot ] = (void*)trie;
#ifdef DEBUGGING
    /* The compiler can return early if no replacement node fits.  Install
     * the optional word-list slot before that can happen, so regex cleanup
     * never sees an uninitialised data pointer. */
    RExC_rxi->data->data[ data_slot + TRIE_WORDS_OFFSET ] = NULL;
#endif
    trie->wordinfo = (reg_trie_wordinfo *) PerlMemShared_calloc(
                       trie->wordcount+1, sizeof(reg_trie_wordinfo));

    DEBUG_r({
        trie_words = newAV();
    });

    DEBUG_TRIE_COMPILE_r({
        re_indentf(
          "make_trie start == %d, first == %d, last == %d, tail == %d depth = %d\n",
          depth+1,
          REG_NODE_NUM(startbranch), REG_NODE_NUM(first),
          REG_NODE_NUM(last), REG_NODE_NUM(tail), (int)depth);
    });

   /* Find the node we are going to overwrite */
    if ( first == startbranch && OP( last ) != BRANCH ) {
        /* whole branch chain */
        convert = first;
    } else {
        /* branch sub-chain */
        convert = REGNODE_AFTER( first );
    }
    /* Jump offsets are recorded relative to this location.  Prefix
     * extraction may move the trie, in which case jump_correction rebases
     * them. */
    regnode * const jump_base = convert;

    /* State zero is reserved as the sentinel; state one is the root, and
     * next_alloc always names the next state to allocate. */
    /* The list compiler performs source analysis and transition-list
     * construction in one pass.  The larger of the word and octet counts is
     * a useful initial estimate: common prefixes reduce the number of states,
     * while UTF-8 expansion and folding can increase it.  State storage
     * therefore grows on demand when the estimate is low. */
    state_capacity = MAX(word_count, octet_count) + 2;
    if (state_capacity < 16)
        state_capacity = 16;
    trie_needs_codepoint_processing = folder != NULL;

    /*
        We construct every trie using an array of transition lists.  Once
        construction is complete, the list representation is converted into
        the compressed transition form used by regexec.c.

    */


    Newx(prev_states, state_capacity, U32);
    prev_states[1] = 0;

    {
        /*
            Array Of Lists Representation

            Each state will be represented by a list of octet:state records
            (reg_trie_trans_le) the first such element holds the CUR and LEN
            points of the allocated array. (See defines above).

            We build the initial structure using the lists, and then convert
            it into the compressed table form which allows faster lookups
            (but cant be modified once converted).
        */

        /* TRIE_CHARCOUNT counts source characters for diagnostics.  This
         * count is different from transition_count, which counts distinct
         * list transitions and provides the initial packed-table estimate. */
        STRLEN transition_count = 1;

        DEBUG_TRIE_COMPILE_MORE_r( re_indentf("Compiling trie using list compiler\n",
            depth+1));

        trie->states = (reg_trie_state *)
            PerlMemShared_calloc( state_capacity,
                                  sizeof(reg_trie_state) );
        S_trie_list_new(trie, 1);
        next_alloc = 2;

        for ( cur = first ; cur < last ; cur = regnext( cur ) ) {

            regnode *noper   = REGNODE_AFTER( cur );
            U32 state        = 1;         /* required init */
            U32 wordlen      = 0;         /* required init */
            int foldlen      = 0;
            STRLEN minchars  = 0;
            STRLEN maxchars  = 0;
            lastbranch = cur;

            if (OP(noper) == NOTHING) {
                regnode *noper_next= regnext(noper);
                if (noper_next < tail)
                    noper = noper_next;
                /* we will undo this assignment if noper does not
                 * point at a trieable type in the else clause of
                 * the following statement. */
            }

            if (    noper < tail
                && (    OP(noper) == flags
                    || (flags == EXACT && OP(noper) == EXACT_REQ8)
                    || (flags == EXACTFU && (   OP(noper) == EXACTFU_REQ8
                                              || OP(noper) == EXACTFUP))))
            {
                const U8 *uc= (U8*)STRING(noper);
                const U8 *e= uc + STR_LEN(noper);

                bool is_utf8 = TRIE_SOURCE_UTF8(noper);

                for ( ; uc < e ; uc += len ) {
                    if (is_utf8 && folder == NULL) {
                        const U8 *bp;
                        const U8 * const ep = uc + UTF8SKIP(uc);

                        /* An un-folded UTF-8 source word is already in the
                         * representation used by the trie.  Avoid decoding
                         * and re-encoding it; UTF8SKIP is sufficient here
                         * because compiled pattern strings are well formed. */
                        len = (STRLEN)(ep - uc);
                        wordlen++;
                        minchars++;
                        maxchars++;
                        TRIE_CHARCOUNT(trie)++;

                        if (len == 1) {
                            trie->prop_flags |= TRIE_CP_INVARIANT;
                        }
                        else if (UTF8_IS_ABOVE_LATIN1(*uc)) {
                            trie->prop_flags |= TRIE_CP_HIGH;
                            trie_needs_codepoint_processing = true;
                        }
                        else {
                            trie->prop_flags |= TRIE_CP_AWKWARD;
                            trie_needs_codepoint_processing = true;
                        }

                        for (bp = uc; bp < ep; bp++)
                            S_trie_list_transition(trie, &state, *bp,
                                                    &next_alloc, &state_capacity,
                                                    &prev_states, &transition_count);
                        continue;
                    }

                    wordlen++;
                    if (is_utf8) {
                        /* If it is UTF then it is either already folded, or
                         * does not need folding. */
                        uvc = valid_utf8_to_uv((const U8 *)uc, &len);
                    }
                    else if (folder == PL_fold_latin1) {
                        /* This folder implies Unicode rules, which in the
                         * range expressible by not UTF is the lower case,
                         * with the two exceptions, one of which should have
                         * been taken care of before calling this. */
                        assert(*uc != LATIN_SMALL_LETTER_SHARP_S);
                        uvc = toLOWER_L1(*uc);
                        if (UNLIKELY(uvc == MICRO_SIGN))
                            uvc = GREEK_SMALL_LETTER_MU;
                        len = 1;
                    }
                    else {
                        /* Raw data, will be folded later if needed. */
                        uvc = (U32)*uc;
                        len = 1;
                    }
                    TRIE_CHARCOUNT(trie)++;

                    if (UVCHR_IS_INVARIANT(uvc))
                        trie->prop_flags |= TRIE_CP_INVARIANT;
                    else if (NATIVE_TO_UNI(uvc) < 256) {
                        trie->prop_flags |= TRIE_CP_AWKWARD;
                        trie_needs_codepoint_processing = true;
                    }
                    else {
                        trie->prop_flags |= TRIE_CP_HIGH;
                        trie_needs_codepoint_processing = true;
                    }

                    /* The trie contains every character in the folded
                     * representation, so maxchars counts each character
                     * visited here.  A multi-character fold can make the
                     * actual match longer than the source word. */
                    maxchars++;
                    if (folder == NULL) {
                        minchars++;
                    }
                    else if (foldlen > 0) {
                        /* The remaining characters of a multi-character
                         * fold are represented in the trie, but they do not
                         * consume additional source characters. */
                        foldlen -= (UTF) ? UTF8SKIP(uc) : 1;
                    }
                    else {
                        minchars++;
                        /* Count the first character of a fold normally, then
                         * suppress the additional folded characters from the
                         * minimum.  foldlen is measured in source octets. */
                        if (UTF) {
                            if ((foldlen = is_MULTI_CHAR_FOLD_utf8_safe(uc, e)))
                                foldlen -= UTF8SKIP(uc);
                        }
                        else if ((foldlen = is_MULTI_CHAR_FOLD_latin1_safe(uc, e)))
                            foldlen--;
                    }

                    if ( trie_needs_codepoint_processing ) {
                        const U8 *bp;
                        const U8 *ep;
                        U8 encoded[UTF8_MAXBYTES + 1];

                        if (!is_utf8 && FITS_IN_8_BITS(uvc)) {
                            const native_octet_utf8_t * const octet =
                                &PL_native_octet_utf8[(U8)uvc];
                            bp = octet->bytes;
                            ep = bp + octet->len;
                        }
                        else {
                            UV unicode_uv = uvc;
                            /* The trie is always encoded as UTF-8.  Convert a
                             * native source codepoint only for this encoding
                             * step; keep uvc in its source representation for
                             * the rest of the pass. */
                            if (!is_utf8)
                                unicode_uv = NATIVE_TO_UNI(uvc);
                            ep = uvoffuni_to_utf8_flags(encoded, unicode_uv, 0);
                            bp = encoded;
                        }

                        for ( ; bp < ep; bp++)
                            S_trie_list_transition(trie, &state, *bp,
                                                    &next_alloc, &state_capacity,
                                                    &prev_states, &transition_count);
                    } else {
                        S_trie_list_transition(trie, &state, uvc,
                                                &next_alloc, &state_capacity,
                                                &prev_states, &transition_count);
                    }
                }
            } else {
                /* If we end up here it is because we skipped past a NOTHING, but did not end up
                 * on a trieable type. So we need to reset noper back to point at the first regop
                 * in the branch before we record the word
                */
                noper = REGNODE_AFTER(cur);
            }
            if (cur == first) {
                trie->minlen = minchars;
                trie->maxlen = maxchars;
            }
            else if (minchars < trie->minlen) {
                trie->minlen = minchars;
            }
            else if (maxchars > trie->maxlen) {
                trie->maxlen = maxchars;
            }
            {
                U32 dupe = trie->states[state].wordnum;
                regnode * const noper_next = regnext(noper);

                DEBUG_r({
                    /* Store the word for dumping. */
                    SV *tmp;
                    if (OP(noper) != NOTHING)
                        tmp = newSVpvn_utf8(STRING(noper), STR_LEN(noper), UTF);
                    else
                        tmp = newSVpvn_utf8("", 0, UTF);
                    av_push_simple(trie_words, tmp);
                });

                curword++;
                assert(curword <= word_count);
                trie->wordinfo[curword].prev = 0;
                trie->wordinfo[curword].len = wordlen;
                trie->wordinfo[curword].accept = state;

                /* If this branch continues past its exact node, preserve the
                 * continuation and the capture-state values associated with
                 * the branch.  Replacing the branch chain with one trie node
                 * would otherwise discard that control-flow information. */
                if (noper_next < tail) {
                    if (!trie->jump) {
                        trie->jump = (TRIE_JUMP_TYPE *)
                            PerlMemShared_calloc(word_count + 1,
                                                 sizeof(TRIE_JUMP_TYPE));
                        trie->j_before_paren = (U16 *)
                            PerlMemShared_calloc(word_count + 1, sizeof(U16));
                        trie->j_after_paren = (U16 *)
                            PerlMemShared_calloc(word_count + 1, sizeof(U16));
                    }
                    assert(noper_next > convert);
                    assert(curword <= word_count);
                    assert(!trie->jump[curword]);
                    assert((noper_next - convert) >= 0);
                    assert((noper_next - convert) <= TRIE_JUMP_TYPE_MAX);
                    trie->jump[curword] = noper_next - convert;
                    U16 set_before_paren;
                    U16 set_after_paren;
                    if (OP(cur) == BRANCH) {
                        set_before_paren = ARG1a(cur);
                        set_after_paren = ARG1b(cur);
                    }
                    else {
                        set_before_paren = ARG2a(cur);
                        set_after_paren = ARG2b(cur);
                    }
                    trie->j_before_paren[curword] = set_before_paren;
                    trie->j_after_paren[curword] = set_after_paren;
                    if (!jumper)
                        jumper = noper_next;
                    if (!nextbranch)
                        nextbranch = regnext(cur);
                }

                if (dupe) {
                    /* It's a duplicate.  Pre-insert it into the
                     * wordinfo[].prev chain so duplicate words appear in
                     * the chain when it is linked below. */
                    trie->wordinfo[curword].prev = trie->wordinfo[dupe].prev;
                    trie->wordinfo[dupe].prev = curword;
                }
                else {
                    trie->states[state].wordnum = curword;
                }
            }

        } /* end list construction */

        /* The list pass has also completed the source analysis. */
#ifdef DEBUGGING
        Zero(trie->bitmap, sizeof(trie->bitmap), U8);
#endif
        trie->before_paren = OP(first) == BRANCH
                     ? ARG1a(first)
                     : ARG2a(first); /* BRANCHJ */

        trie->after_paren = OP(lastbranch) == BRANCH
                     ? ARG1b(lastbranch)
                     : ARG2b(lastbranch); /* BRANCHJ */
        DEBUG_TRIE_COMPILE_r(
            re_indentf(
                    "TRIE(%s): W:%d C:%d Uq:%d Min:%d Max:%d\n",
                    depth+1,
                    ( trie_needs_codepoint_processing ? "PROCESSED" : "RAW" ), (int)word_count,
                    (int)TRIE_CHARCOUNT(trie), TRIE_ALPHABET_SIZE,
                    (int)trie->minlen, (int)trie->maxlen )
        );

        /* next alloc is the NEXT state to be allocated */
        trie->statecount = next_alloc;
        trie->states = (reg_trie_state *)
            PerlMemShared_realloc( trie->states,
                                   next_alloc
                                   * sizeof(reg_trie_state) );

        /* and now dump it out before we compress it */
        DEBUG_TRIE_COMPILE_MORE_r(dump_trie_interim_list(trie, next_alloc,
                                                         depth+1)
        );

        /* The list compiler has counted each distinct transition.  The flat
         * table has an unused slot zero, so this is the ideal number of
         * occupied entries.  The table itself may need more physical slots
         * because a state's character-ID range can contain holes. */
#ifdef DEBUGGING
        const STRLEN ideal_transition_count = transition_count - 1;
#endif
        STRLEN transition_capacity = transition_count;
        trie->trans = (reg_trie_trans *)
            PerlMemShared_calloc( transition_capacity,
                                  sizeof(reg_trie_trans) );
        {
            U32 state;
            /* table_highwater is one past the packed portion of trie->trans;
             * next_hole is the first unused slot within that portion.  A
             * non-zero next field marks an occupied slot, so holes can be
             * reused without a separate occupancy map. */
            U32 table_highwater = 0;
            U32 next_hole = 0;


            for( state = 1; state < next_alloc; state ++ ) {
                U32 base = 0;

                /*
                DEBUG_TRIE_COMPILE_MORE_r(
                    re_printf("table_highwater: %d next_hole: %d ",
                              table_highwater, next_hole)
                );
                */

                if (trie->states[state].trans.list) {
                    const U32 used = TRIE_LIST_USED( state );
                    const U32 minid = TRIE_LIST_ITEM( state, 1).forid;
                    const U32 maxid = TRIE_LIST_ITEM( state, used).forid;
                    const U32 frame_span = maxid - minid;
                    const U32 frame_width = frame_span + 1;
                    bool placed = false;
                    U32 idx;

                    /* A state's transitions form a frame from minid through
                     * maxid.  Sparse frames may fit into holes left by earlier
                     * frames.  Try the first available position.  The
                     * frame may extend beyond table_highwater, provided it
                     * fits in the allocation and its occupied slots do not
                     * clash. */
                    while (next_hole < table_highwater
                            && trie->trans[next_hole].next)
                        next_hole++;
                    /* Only sparse frames benefit from hole searching.  Small
                     * frames are cheap to try, while larger frames are tried
                     * only when their span is much wider than their payload. */
                    if (used > 1 && (used <= 4 || used * 8 < frame_span)
                            && next_hole < table_highwater
                            && next_hole + frame_width >= next_hole) {
                        const U32 candidate_end = next_hole + frame_width;
                        if (transition_capacity < candidate_end) {
                            const U32 old_capacity = transition_capacity;
                            const U32 needed = candidate_end;

                            while (transition_capacity < needed)
                                transition_capacity *= 2;
                            trie->trans = (reg_trie_trans *)
                                PerlMemShared_realloc(
                                    trie->trans,
                                    transition_capacity
                                      * sizeof(reg_trie_trans) );
                            Zero( trie->trans + old_capacity,
                                  transition_capacity - old_capacity,
                                  reg_trie_trans );
                        }
                        for (idx = 1; idx <= used; idx++) {
                            const U32 tid = next_hole
                                           + TRIE_LIST_ITEM( state, idx ).forid
                                           - minid;
                            if (trie->trans[ tid ].next)
                                break;
                        }
                        if (idx > used) {
                            base = TRIE_ALPHABET_SIZE + next_hole - minid;
                            for (idx = 1; idx <= used; idx++) {
                                const U32 tid = base
                                               - TRIE_ALPHABET_SIZE
                                               + TRIE_LIST_ITEM( state, idx ).forid;
                                trie->trans[ tid ].next = TRIE_LIST_ITEM( state,
                                                                    idx ).newstate;
                                trie->trans[ tid ].check = state;
                            }
                            if (candidate_end > table_highwater)
                                table_highwater = candidate_end;
                            while (next_hole < table_highwater
                                    && trie->trans[next_hole].next)
                                next_hole++;
                            placed = true;
                        }
                    }

                    /* Grow the physical table when the frame cannot fit at
                     * the current high-water mark. */
                    if (!placed
                            && transition_capacity < table_highwater + frame_width) {
                        const U32 old_capacity = transition_capacity;
                        const U32 needed = table_highwater + frame_width;

                        while (transition_capacity < needed)
                            transition_capacity *= 2;
                        trie->trans = (reg_trie_trans *)
                            PerlMemShared_realloc( trie->trans,
                                                     transition_capacity
                                                     * sizeof(reg_trie_trans) );
                        Zero( trie->trans + old_capacity,
                              transition_capacity - old_capacity,
                              reg_trie_trans );
                    }
                    if (!placed) {
                        base = TRIE_ALPHABET_SIZE + table_highwater - minid;
                    }
                    /* A one-transition frame can occupy one existing hole;
                     * it does not need its full frame width to be reserved. */
                    if ( !placed && maxid == minid ) {
                        U32 set = 0;
                        for ( ; next_hole < table_highwater ; next_hole++ ) {
                            if ( ! trie->trans[ next_hole ].next ) {
                                base = TRIE_ALPHABET_SIZE + next_hole - minid;
                                trie->trans[ next_hole ].next = TRIE_LIST_ITEM( state,
                                                                   1).newstate;
                                trie->trans[ next_hole ].check = state;
                                set = 1;
                                break;
                            }
                        }
                        if ( !set ) {
                            trie->trans[ table_highwater ].next = TRIE_LIST_ITEM( state,
                                                                   1).newstate;
                            trie->trans[ table_highwater ].check = state;
                            table_highwater++;
                            next_hole = table_highwater;
                        } else {
                            while (next_hole < table_highwater
                                    && trie->trans[next_hole].next)
                                next_hole++;
                        }
                    } else if (!placed) {
                        for ( idx = 1; idx <= TRIE_LIST_USED( state ) ; idx++ ) {
                            const U32 tid = base
                                           - TRIE_ALPHABET_SIZE
                                           + TRIE_LIST_ITEM( state, idx ).forid;
                            trie->trans[ tid ].next = TRIE_LIST_ITEM( state,
                                                                idx ).newstate;
                            trie->trans[ tid ].check = state;
                        }
                        table_highwater += frame_width;
                        while (next_hole < table_highwater
                                && trie->trans[next_hole].next)
                            next_hole++;
                    }
                    Safefree(trie->states[ state ].trans.list);
                }
                /*
                DEBUG_TRIE_COMPILE_MORE_r(
                    re_printf(" base: %d\n",base);
                );
                */
                trie->states[ state ].trans.base = base;
            }
            /* Slot zero is reserved by the packed-table representation; keep
             * it in the recorded range even when table_highwater is zero. */
            trie->lasttrans = table_highwater + 1;
            assert(next_hole <= table_highwater);
            assert(table_highwater <= transition_capacity);
            DEBUG_TRIE_COMPILE_MORE_r(
                re_indentf("Compressed table: physical=%" UVuf
                           " ideal=%" UVuf " overhead=%" UVuf "\n",
                    depth+1,
                    (UV)table_highwater,
                    (UV)ideal_transition_count,
                    (UV)(table_highwater - ideal_transition_count))
            );
            DEBUG_TRIE_COMPILE_MORE_r(
                dump_trie_physical(trie, table_highwater, depth+1)
            );
        }
    }
    DEBUG_TRIE_COMPILE_MORE_r(
            re_indentf("Statecount:%" UVxf " Lasttrans:%" UVxf "\n",
                depth+1,
                (UV)trie->statecount,
                (UV)trie->lasttrans)
    );
    /* resize the trans array to remove unused space */
    trie->trans = (reg_trie_trans *)
        PerlMemShared_realloc( trie->trans, trie->lasttrans
                               * sizeof(reg_trie_trans) );

    {   /* Modify the program and insert the new TRIE node */
        U8 nodetype =(U8) flags;
        U8 trie_op = TRIE;
        char *str = NULL;
        U8 original_len = 0;
        U8 original_string[256];
        U32 original_next = 0;
        const U32 original_minlen = trie->minlen;
        const U32 original_maxlen = trie->maxlen;

#ifdef DEBUGGING
        regnode *optimize = NULL;
#endif /* DEBUGGING */
        if (trie->jump) {
            original_len = STR_LEN(convert);
            Copy(STRING(convert), original_string, original_len, U8);
            original_next = TRIE_NEXT(convert);
        }
        /* make sure we have enough room to inject the TRIE op */
        assert((!trie->jump) || !trie->jump[1] ||
                (trie->jump[1] >= (sizeof(tregnode_TRIE)/sizeof(struct regnode))));
        /*
           This means we convert either the first branch or the first Exact,
           depending on whether the thing following (in 'last') is a branch
           or not and whther first is the startbranch (ie is it a sub part of
           the alternation or is it the whole thing.)
           Assuming its a sub part we convert the EXACT otherwise we convert
           the whole branch sequence, including the first.
         */
        /* Find the node we are going to overwrite */
        if ( first != startbranch || OP( last ) == BRANCH ) {
            /* branch sub-chain */
            TRIE_NEXT_set(first, last - first);
            /* whole branch chain */
        }
        /* But first we check to see if there is a common prefix we can
           split out as an EXACT and put in front of the TRIE node.  */
        trie->startstate = 1;
        DEBUG_TRIE_COMPILE_MORE_r({
            re_printf("Trie prefix probe: mode=%u ranges=%#x\n",
                      (unsigned)(trie->prop_flags & TRIE_FOLD_MASK),
                      (unsigned)(trie->prop_flags & (TRIE_CP_INVARIANT
                                                     | TRIE_CP_AWKWARD
                                                     | TRIE_CP_HIGH)));
            if (trie_needs_codepoint_processing) {
                U32 debug_state = 1;
                U32 debug_octets = 0;
                U32 debug_complete_octets = 0;
                U32 debug_chars = 0;
                U32 debug_need = 0;
                U8 debug_prefix[256];

                re_printf("Octet trie prefix probe:\n");
                while (debug_state < trie->statecount - 1
                       && debug_octets < sizeof(debug_prefix)) {
                    U32 ofs;
                    U32 count = trie->states[debug_state].wordnum ? 1 : 0;
                    U32 transition = 0;
                    const U32 min_octet =
                        trie->states[debug_state].min_octet;
                    const U32 max_octet =
                        trie->states[debug_state].max_octet;

                    for (ofs = min_octet; ofs <= max_octet; ofs++) {
                        const U32 index = trie->states[debug_state].trans.base
                                        + ofs - TRIE_ALPHABET_SIZE;
                        if (trie->states[debug_state].trans.base + ofs
                                >= TRIE_ALPHABET_SIZE
                            && index < trie->lasttrans
                            && trie->trans[index].check == debug_state) {
                            count++;
                            transition = ofs;
                        }
                    }
                    if (count != 1)
                        break;

                    debug_prefix[debug_octets++] = (U8)transition;
                    if (!debug_need) {
                        if (transition < 0x80)
                            debug_need = 0;
                        else if (transition < 0xe0)
                            debug_need = 1;
                        else if (transition < 0xf0)
                            debug_need = 2;
                        else
                            debug_need = 3;
                    }
                    else
                        debug_need--;
                    if (!debug_need) {
                        debug_complete_octets = debug_octets;
                        debug_chars++;
                    }
                    debug_state++;
                }
                re_printf("  states=%u octets=%u complete_octets=%u chars=%u "
                          "tail_octets=%u\n", (unsigned)debug_state,
                          (unsigned)debug_octets, (unsigned)debug_complete_octets,
                          (unsigned)debug_chars, (unsigned)debug_need);
                re_printf("  raw prefix:");
                for (debug_octets = 0; debug_octets < debug_complete_octets;
                     debug_octets++)
                    re_printf(" %02x", (unsigned)debug_prefix[debug_octets]);
                re_printf("\n");
            }
        });
        /* Extract a common prefix only when it is safe to remove complete
         * characters from the trie.  Raw invariant tries consume one octet
         * per character.  Processed tries must stop at UTF-8 codepoint
         * boundaries; native processed tries also reject an awkward encoded
         * transition (TRIE-PREFIX-XX) rather than treating its first octet as
         * a complete character. */
        if ( (!trie_needs_codepoint_processing || UTF) ) {
            /* we want to find the first state that has more than
             * one transition, if that state is not the first state
             * then we have a common prefix which we can remove.
             */
            U32 state;
            U32 complete_state = 1;
            /* prefixlen_octets and prefixlen_chars have different units in
             * the processed path.  complete_state is the first trie state
             * left after the complete prefix has been extracted. */
            U32 complete_octets = 0;
            U32 complete_chars = 0;
            U8 utf8_prefix[256];

            if (trie_needs_codepoint_processing) {
                U32 octets = 0;
                U32 chars = 0;
                U32 need = 0;

                state = 1;
                /* The final state has no outgoing transition and is not a
                 * prefix state, so stop before statecount - 1. */
                while (state < trie->statecount - 1
                       && octets < sizeof(utf8_prefix)) {
                    U32 ofs;
                    U32 count = trie->states[state].wordnum ? 1 : 0;
                    U32 next_state = 0;
                    const U32 base = trie->states[state].trans.base;
                    const U32 min_octet = trie->states[state].min_octet;
                    const U32 max_octet = trie->states[state].max_octet;

                    for (ofs = min_octet; ofs <= max_octet; ofs++) {
                        if (base + ofs >= TRIE_ALPHABET_SIZE
                            && base + ofs - TRIE_ALPHABET_SIZE < trie->lasttrans
                            && trie->trans[base + ofs - TRIE_ALPHABET_SIZE].check == state) {
                            if (++count > 1)
                                break;
                            next_state = trie->trans[base + ofs
                                                   - TRIE_ALPHABET_SIZE].next;
                            utf8_prefix[octets] = (U8)ofs;
                        }
                    }
                    if (count != 1)
                        break;

                    if (!need) {
                        /* The trie contains only valid UTF-8 sequences, so
                         * UTF8SKIP() gives the number of octets remaining in
                         * this codepoint. */
                        need = UTF8SKIP(&utf8_prefix[octets]) - 1;
                    }
                    else if (!UTF8_IS_CONTINUATION(utf8_prefix[octets]))
                        break;
                    else
                        need--;

                    octets++;
                    state = next_state;
                    if (!need) {
                        complete_state = state;
                        complete_octets = octets;
                        complete_chars = ++chars;
                    }
                }
                state = complete_state;
                if (complete_octets) {
                    OP(convert) = nodetype;
                    str = STRING(convert);
                    setSTR_LEN(convert, 0);
                    /* The replacement EXACT node stores its string length in
                     * an octet, so the extracted prefix must fit in 255. */
                    assert(STR_LEN(convert) + complete_octets < 256);
                    Copy(utf8_prefix, str, complete_octets, U8);
                    str += complete_octets;
                    setSTR_LEN(convert, (U8)complete_octets);
                }
            }
            else {
            /* The final state has no outgoing transition and is not a prefix
             * state, so stop before statecount - 1. */
            for ( state = 1 ; state < trie->statecount-1 ; state++ ) {
                U32 ofs = 0;
                I32 first_ofs = -1; /* keeps track of the ofs of the first
                                       transition, -1 means none */
                U32 count = 0;
                const U32 base = trie->states[ state ].trans.base;
                const U32 min_octet = trie->states[state].min_octet;
                const U32 max_octet = trie->states[state].max_octet;

                /* does this state terminate an alternation? */
                if ( trie->states[state].wordnum )
                        count = 1;

                for ( ofs = min_octet ; ofs <= max_octet ; ofs++ ) {
                    if ( ( base + ofs >= TRIE_ALPHABET_SIZE ) &&
                         ( base + ofs - TRIE_ALPHABET_SIZE < trie->lasttrans ) &&
                         trie->trans[ base + ofs - TRIE_ALPHABET_SIZE ].check == state )
                    {
                        if ( ++count > 1 ) {
                            /* more than one transition here, so we can exit the loop */
                            break;
                        }
                        first_ofs = ofs;
                    }
                }
                if ( count == 1 ) {
                    /* This state has only one transition, its transition is part
                     * of a common prefix - we need to concatenate the char it
                     * represents to what we have so far. */
                    STRLEN len;
                    char *ch;
                    U8 octet;
                    octet = (U8)first_ofs;
                    ch = (char *)&octet;
                    len = 1;
                    DEBUG_OPTIMISE_r({
                        SV *sv = sv_newmortal();
                        re_indentf("Prefix State: %" UVuf " Ofs: %" UVuf " Char: '%s'\n",
                            depth+1,
                            (UV)state, (UV)first_ofs,
                            pv_pretty(sv, ch, len, 6,
                                PL_colors[0], PL_colors[1],
                                PERL_PV_ESCAPE_FIRSTCHAR
                            )
                        );
                    });
                    if ( state == 1 ) {
                        OP( convert ) = nodetype;
                        str = STRING(convert);
                        setSTR_LEN(convert, 0);
                    }
                    /* The replacement EXACT node stores its string length in
                     * an octet, so the extracted prefix must fit in 255. */
                    assert( ( STR_LEN(convert) + len ) < 256 );
                    setSTR_LEN(convert, (U8)(STR_LEN(convert) + len));
                    while (len--)
                        *str++ = *ch++;
                } else {
#ifdef DEBUGGING
                    if (state > 1)
                        DEBUG_OPTIMISE_r(re_printf("]\n"));
#endif
                    break;
                }
            }
            trie->prefixlen_octets = (state-1);
            trie->prefixlen_chars = (state-1);
            }
            if (trie_needs_codepoint_processing) {
                trie->prefixlen_octets = complete_octets;
                trie->prefixlen_chars = complete_chars;
            }
            if (str) {
                /* A non-NULL str means that at least one common prefix
                 * character was copied out of the trie and into convert. */
                regnode *n = REGNODE_AFTER(convert);
                if (trie->jump && trie->jump[1]
                    && (SSize_t)trie->jump[1] - (n - jump_base)
                         < (SSize_t)(sizeof(tregnode_TRIE)
                                     / sizeof(struct regnode))) {
                    /* The extracted prefix left too little room for a
                     * jump-capable trie.  Restore the source node and leave
                     * the trie at its original location. */
                    Copy(original_string, STRING(convert), original_len, U8);
                    setSTR_LEN(convert, original_len);
                    TRIE_NEXT_set(convert, original_next);
                    trie->startstate = 1;
                    trie->minlen = original_minlen;
                    trie->maxlen = original_maxlen;
                    trie->prefixlen_octets = 0;
                    trie->prefixlen_chars = 0;
                    trie->jump_correction = 0;
                    str = NULL;
                }
                if (str) {
                    TRIE_NEXT_set(convert, n - convert);
                    trie->startstate = state;
                    /* The extracted prefix is now matched by convert, so remove
                     * its character count from the length bounds that describe
                     * the remaining trie.  In the processed path state - 1 counts
                     * octet states, so use prefixlen_chars rather than state - 1. */
                    trie->minlen -= trie->prefixlen_chars;
                    trie->maxlen -= trie->prefixlen_chars;
#ifdef DEBUGGING
                    /* At least the UNICOS C compiler choked on this
                     * being argument to DEBUG_r(), so let's just have
                     * it right here. */
                    if (
#ifdef PERL_EXT_RE_BUILD
                        1
#else
                        DEBUG_r_TEST
#endif
                    ) {
                        U32 word = trie->wordcount;
                        while (word--) {
                            SV ** const tmp = av_fetch_simple( trie_words, word, 0 );
                            if (tmp) {
                                if ( STR_LEN(convert) <= SvCUR(*tmp) )
                                    sv_chop(*tmp, SvPV_nolen(*tmp) + STR_LEN(convert));
                                else
                                    sv_chop(*tmp, SvPV_nolen(*tmp) + SvCUR(*tmp));
                            }
                        }
                    }
#endif
                    if (trie->maxlen || (trie->jump && str)) {
                        if (trie->jump)
                            trie->jump_correction = n - jump_base;
                        convert = n;
                    } else {
                        trie->jump_correction = 0;
                        TRIE_NEXT_set(convert, tail - convert);
                        DEBUG_r(optimize= n);
                    }
                }
            }
        }
        if (!jumper)
            jumper = last;
        if ( trie->maxlen || (trie->jump && str) ) {
            const U32 needed_next = tail - convert;
            /* The replacement trie must fit in the program space being
             * overwritten.  Jump tries reserve their first jump distance;
             * otherwise jumper marks the end of the replaceable region. */
            const SSize_t jump_room = trie->jump ? TRIE_JUMP_ROOM(trie) : 0;
            const Size_t trie_room = trie->jump && trie->jump[1]
                ? (Size_t)jump_room * sizeof(struct regnode)
                : (Size_t)((char *)jumper - (char *)convert);
            assert(!trie->jump || !trie->jump[1] || jump_room >= 0);
            trie_op = S_select_trie_op(aTHX_ trie_room, needed_next);

            if (!trie_op) {
                DEBUG_TRIE_COMPILE_r(
                    re_indentf("No trie node type fits at %d (need next=%" UVuf ", room=%" UVuf ")\n",
                        depth+1,
                        REG_NODE_NUM(convert),
                        (UV)needed_next,
                        (UV)trie_room)
                );
                return 0;
            }

            OP( convert ) = trie_op;
            TRIE_NEXT_set(convert, tail - convert);
            TRIE_DATA_SLOT_set(convert, data_slot);
            /* Store the offset to the first unabsorbed branch in
               jump[0], which is otherwise unused by the jump logic.
               We use this when dumping a trie and during optimisation. */
            if (trie->jump) {
                assert(nextbranch > convert);
                assert((nextbranch - convert) <= TRIE_JUMP_TYPE_MAX);
                assert(trie->jump[0] == 0);
                assert(nextbranch <= tail);

                trie->jump[0] = nextbranch - jump_base;
            }

            /* store the type in the flags */
            FLAGS(convert) = nodetype;
            DEBUG_r({
            optimize = convert
                      + NODE_STEP_REGNODE
                      + REGNODE_ARG_LEN( OP( convert ) );
            });
            /* XXX We really should free up the resource in trie now,
                   as we won't use them - (which resources?) dmq */
        }
        /* needed for dumping*/
        DEBUG_r(if (optimize) {
            /*
                Try to clean up some of the debris left after the
                optimisation.
             */
            while( optimize < jumper ) {
                OP( optimize ) = OPTIMIZED;
                optimize++;
            }
        });
    } /* end node insert */

    /*  Finish populating the prev field of the wordinfo array.  Starting at
     *  each word's accept state, walk back through predecessor states until
     *  we find the next earlier accepting state, and point the first word's
     *  .prev field at that word. If the
     *  second already has a .prev field set, stop now. This will be the
     *  case either if we've already processed that word's accept state,
     *  or that state had multiple words, and the overspill words were
     *  already linked up earlier.
     */
    {
        U32 word;
        U32 state;
        U32 prev;

        for (word = 1; word <= trie->wordcount; word++) {
            prev = 0;
            if (trie->wordinfo[word].prev)
                continue;
            state = trie->wordinfo[word].accept;
            while (state) {
                state = prev_states[state];
                if (!state)
                    break;
                prev = trie->states[state].wordnum;
                if (prev)
                    break;
            }
            trie->wordinfo[word].prev = prev;
        }
        Safefree(prev_states);
    }


    /* and now dump out the compressed format */
    DEBUG_TRIE_COMPILE_r(dump_trie(trie, depth+1));
#ifdef DEBUGGING
    RExC_rxi->data->data[ data_slot + TRIE_WORDS_OFFSET ] = (void*)trie_words;
#endif
    return trie->jump
           ? MADE_JUMP_TRIE
           : trie->startstate > 1
             ? MADE_EXACT_TRIE
             : MADE_TRIE;
}

regnode *
Perl_construct_ahocorasick_from_trie(pTHX_ RExC_state_t *pRExC_state, regnode *source, U32 depth)
{
    PERL_ARGS_ASSERT_CONSTRUCT_AHOCORASICK_FROM_TRIE;

/* The Trie is constructed and compressed now so we can build a fail array if
 * it's needed

   This is basically the Aho-Corasick algorithm. Its from exercise 3.31 and
   3.32 in the
   "Red Dragon" -- Compilers, principles, techniques, and tools. Aho, Sethi,
   Ullman 1985/88
   ISBN 0-201-10088-6

   We find the fail state for each state in the trie, this state is the longest
   proper suffix of the current state's 'word' that is also a proper prefix of
   another word in our trie. State 1 represents the word '' and is thus the
   default fail state. This allows the DFA not to have to restart after its
   tried and failed a word at a given point, it simply continues as though it
   had been matching the other word in the first place.
   Consider
      'abcdgu'=~/abcdefg|cdgu/
   When we get to 'd' we are still matching the first word, we would encounter
   'g' which would fail, which would bring us to the state representing 'd' in
   the second word where we would try 'g' and succeed, proceeding to match
   'cdgu'.
 */
 /* add a fail transition */
    const U32 trie_offset = TRIE_DATA_SLOT(source);
    reg_trie_data *trie = (reg_trie_data *)RExC_rxi->data->data[trie_offset];
    U32 *q;
    const U32 ucharcount = TRIE_ALPHABET_SIZE;
    const U32 numstates = trie->statecount;
    const U32 ubound = trie->lasttrans + ucharcount;
    U32 q_read = 0;
    U32 q_write = 0;
    U32 octet;
    U32 base = trie->states[ 1 ].trans.base;
    U32 *fail;
    reg_ac_data *aho;
    const U32 data_slot = reg_add_data( pRExC_state, STR_WITH_LEN("T"));
    regnode *stclass = NULL;
    DECLARE_AND_GET_RE_DEBUG_FLAGS;

    PERL_UNUSED_CONTEXT;
#ifndef DEBUGGING
    PERL_UNUSED_ARG(depth);
#endif
    {
        tregnode_AHOCORASICK *op = (tregnode_AHOCORASICK *)
            PerlMemShared_calloc(1, sizeof(tregnode_AHOCORASICK));
        OP(op) = AHOCORASICK;
        FLAGS(op) = FLAGS(source);
        stclass = (regnode *)op;
    }

    assert(OP(stclass)==AHOCORASICK);
    /* AHOCORASICK nodes are short TRIE's, some compilers arn't smart
     * enough to know that the normal TRIE_DATA_SLOT_set() macro wont
     * ever access undefined memory because of the opcode guards. So we
     * just use the short macro instead here.
     */
    SHORT_TRIE_DATA_SLOT_set(stclass, data_slot);
    aho = (reg_ac_data *) PerlMemShared_calloc( 1, sizeof(reg_ac_data) );
    RExC_rxi->data->data[ data_slot ] = (void*)aho;
    aho->trie = trie_offset;
    aho->states = (reg_trie_state *)PerlMemShared_malloc( numstates * sizeof(reg_trie_state) );
    Copy( trie->states, aho->states, numstates, reg_trie_state );
    /* The breadth-first work queue can contain each state at most once, so
     * numstates entries suffice.  q_read and q_write address it as a
     * circular queue while q_write advances monotonically. */
    Newx( q, numstates, U32);
    aho->fail = (U32 *) PerlMemShared_calloc( numstates, sizeof(U32) );
    aho->refcount = 1;
    fail = aho->fail;
    /* initialize fail[0..1] to be 1 so that we always have
       a valid final fail state */
    fail[ 0 ] = fail[ 1 ] = 1;

    /* Root transitions have no failure link to follow.  Seed the breadth-
     * first traversal with them and make their failure state the root.
     * Later lookups use special = 1 so a failed transition falls back to the
     * root transition. */
    if (base) {
        for ( octet = trie->states[1].min_octet;
              octet <= trie->states[1].max_octet; octet++ ) {
            const U32 newstate = S_trie_trans_state(trie, 1, base, ucharcount,
                                                    octet, 0, ubound);
            if ( newstate ) {
                q[ q_write ] = newstate;
                /* set to point at the root */
                fail[ q[ q_write++ ] ]=1;
            }
        }
    }
    while ( q_read < q_write) {
        const U32 cur = q[ q_read++ % numstates ];
        base = trie->states[ cur ].trans.base;

        if (base) {
            for ( octet = aho->states[cur].min_octet;
                  octet <= aho->states[cur].max_octet; octet++ ) {
                const U32 ch_state = S_trie_trans_state(trie, cur, base,
                                                        ucharcount, octet, 1,
                                                        ubound);
                if (ch_state) {
                    U32 fail_state = cur;
                    U32 fail_base;
                    do {
                        fail_state = fail[ fail_state ];
                        fail_base = aho->states[ fail_state ].trans.base;
                    } while ( !S_trie_trans_state(trie, fail_state, fail_base,
                                                  ucharcount, octet, 1, ubound) );

                    fail_state = S_trie_trans_state(trie, fail_state, fail_base,
                                                ucharcount, octet, 1, ubound);
                    fail[ ch_state ] = fail_state;
                    if ( !aho->states[ ch_state ].wordnum && aho->states[ fail_state ].wordnum )
                    {
                            aho->states[ ch_state ].wordnum =  aho->states[ fail_state ].wordnum;
                    }
                    q[ q_write++ % numstates] = ch_state;
                }
            }
        }
    }
    /* restore fail[0..1] to 0 so that we "fall out" of the AC loop
       when we fail in state 1, this allows us to use the
       charclass scan to find a valid start char. This is based on the principle
       that theres a good chance the string being searched contains lots of stuff
       that cant be a start char.
     */
    fail[ 0 ] = fail[ 1 ] = 0;
    DEBUG_TRIE_COMPILE_r({
        re_indentf("Stclass Failtable (%" UVuf " states): 0",
                      depth, (UV)numstates
        );
        for( q_read = 1; q_read < numstates; q_read++ ) {
            re_printf(", %" UVuf, (UV)fail[q_read]);
        }
        re_printf("\n");
    });
    Safefree(q);
    /*RExC_seen |= REG_TRIEDFA_SEEN;*/
    return stclass;
}

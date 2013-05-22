#if 0

#define ptr_table_new()                    (Perl_ptr_table(aTHX))
#define ptr_table_find(tbl, sv)            (Perl_ptr_table_find(aTHX_ tbl, sv))
#define ptr_table_fetch(tbl, sv)           (Perl_ptr_table_fetch(aTHX_ tbl, sv))
#define ptr_table_store(tbl, oldsv, newsv) (Perl_ptr_table_store(aTHX_ tbl, oldsv, newsv))
#define ptr_table_split(tbl)               (Perl_ptr_table_split(aTHX_ tbl))
#define ptr_table_free(tbl)                (Perl_ptr_table_free(aTHX_ tbl))

#else
#define ptr_table_new()                    (my_ptr_table_new(aTHX))
#define ptr_table_find(tbl, sv)            (my_ptr_table_find(aTHX_ tbl, sv))
#define ptr_table_fetch(tbl, sv)           (my_ptr_table_fetch(aTHX_ tbl, sv))
#define ptr_table_store(tbl, oldsv, newsv) (my_ptr_table_store(aTHX_ tbl, oldsv, newsv))
#define ptr_table_split(tbl)               (my_ptr_table_split(aTHX_ tbl))
#define ptr_table_free(tbl)                (my_ptr_table_free(aTHX_ tbl))


typedef struct my_ptr_tbl_ent MY_PTR_TBL_ENT_t;
typedef struct my_ptr_tbl MY_PTR_TBL_t;

struct my_ptr_tbl_ent {
	struct my_ptr_tbl_ent* next;
	const void* oldval;
	void* newval;
};

struct my_ptr_tbl {
	struct my_ptr_tbl_ent** tbl_ary;
	UV tbl_max;
	UV tbl_items;
	struct my_ptr_tbl_arena	*tbl_arena;
	struct my_ptr_tbl_ent *tbl_arena_next;
	struct my_ptr_tbl_ent *tbl_arena_end;
};

struct my_ptr_tbl_arena {
	struct my_ptr_tbl_arena *next;
	struct my_ptr_tbl_ent array[1023/3]; /* as ptr_tbl_ent has 3 pointers.  */
};

/* create a new pointer-mapping table */

static MY_PTR_TBL_t *
my_ptr_table_new(pTHX)
{
    MY_PTR_TBL_t *tbl;
    PERL_UNUSED_CONTEXT;

    Newx(tbl, 1, MY_PTR_TBL_t);
    tbl->tbl_max	= 511;
    tbl->tbl_items	= 0;
    tbl->tbl_arena	= NULL;
    tbl->tbl_arena_next	= NULL;
    tbl->tbl_arena_end	= NULL;
    Newxz(tbl->tbl_ary, tbl->tbl_max + 1, MY_PTR_TBL_ENT_t*);
    return tbl;
}

#define MY_PTR_TABLE_HASH(ptr) \
  ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))


/* map an existing pointer using a table */

static MY_PTR_TBL_ENT_t *
my_ptr_table_find(MY_PTR_TBL_t *const tbl, const void *const sv)
{
    MY_PTR_TBL_ENT_t *tblent;
    const UV hash = MY_PTR_TABLE_HASH(sv);

    tblent = tbl->tbl_ary[hash & tbl->tbl_max];
    for (; tblent; tblent = tblent->next) {
	if (tblent->oldval == sv)
	    return tblent;
    }
    return NULL;
}

static void *
my_ptr_table_fetch(pTHX_ MY_PTR_TBL_t *const tbl, const void *const sv)
{
    MY_PTR_TBL_ENT_t const *const tblent = my_ptr_table_find(tbl, sv);
    PERL_UNUSED_CONTEXT;
    return tblent ? tblent->newval : NULL;
}

/* double the hash bucket size of an existing ptr table */

static void
my_ptr_table_split(pTHX_ MY_PTR_TBL_t *const tbl)
{
    MY_PTR_TBL_ENT_t **ary = tbl->tbl_ary;
    const UV oldsize = tbl->tbl_max + 1;
    UV newsize = oldsize * 2;
    UV i;
    PERL_UNUSED_CONTEXT;
    Renew(ary, newsize, MY_PTR_TBL_ENT_t*);
    Zero(&ary[oldsize], newsize-oldsize, MY_PTR_TBL_ENT_t*);
    tbl->tbl_max = --newsize;
    tbl->tbl_ary = ary;
    for (i=0; i < oldsize; i++, ary++) {
	MY_PTR_TBL_ENT_t **entp = ary;
	MY_PTR_TBL_ENT_t *ent = *ary;
	MY_PTR_TBL_ENT_t **curentp;
	if (!ent)
	    continue;
	curentp = ary + oldsize;
	do {
	    if ((newsize & MY_PTR_TABLE_HASH(ent->oldval)) != i) {
		*entp = ent->next;
		ent->next = *curentp;
		*curentp = ent;
	    }
	    else
		entp = &ent->next;
	    ent = *entp;
	} while (ent);
    }
}

/* add a new entry to a pointer-mapping table */

static void
my_ptr_table_store(pTHX_ MY_PTR_TBL_t *const tbl, const void *const oldsv, void *const newsv)
{
    MY_PTR_TBL_ENT_t *tblent = my_ptr_table_find(tbl, oldsv);
    PERL_UNUSED_CONTEXT;
    if (tblent) {
	tblent->newval = newsv;
    } else {
	const UV entry = MY_PTR_TABLE_HASH(oldsv) & tbl->tbl_max;

	if (tbl->tbl_arena_next == tbl->tbl_arena_end) {
	    struct my_ptr_tbl_arena *new_arena;

	    Newx(new_arena, 1, struct my_ptr_tbl_arena);
	    new_arena->next = tbl->tbl_arena;
	    tbl->tbl_arena = new_arena;
	    tbl->tbl_arena_next = new_arena->array;
	    tbl->tbl_arena_end = new_arena->array
		+ sizeof(new_arena->array) / sizeof(new_arena->array[0]);
	}

	tblent = tbl->tbl_arena_next++;

	tblent->oldval = oldsv;
	tblent->newval = newsv;
	tblent->next = tbl->tbl_ary[entry];
	tbl->tbl_ary[entry] = tblent;
	tbl->tbl_items++;
	if (tblent->next && tbl->tbl_items > tbl->tbl_max)
	    my_ptr_table_split(tbl);
    }
}

/* clear and free a ptr table */

static void
my_ptr_table_free(pTHX_ MY_PTR_TBL_t *const tbl)
{
    struct my_ptr_tbl_arena *arena;

    if (!tbl) {
        return;
    }

    arena = tbl->tbl_arena;

    while (arena) {
	struct my_ptr_tbl_arena *next = arena->next;

	Safefree(arena);
	arena = next;
    }

    Safefree(tbl->tbl_ary);
    Safefree(tbl);
}

#define PTR_TBL_ENT_t MY_PTR_TBL_ENT_t
#define PTR_TBL_t MY_PTR_TBL_t

#endif

#ifndef HASHMAP_H__
#define HASHMAP_H__

#define _HASHMAP_MINCAP        8
#define _HASHMAP_BUCKET_MINCAP 1

typedef enum {
    HMDR_FAIL = 0, /* returns old entry in parameter entry, lets NAME##Put() */
                   /* "fail", i.e. return HMPR_FAILED */
    HMDR_FIND,     /* returns old entry in parameter entry */
    HMDR_REPLACE,  /* puts new entry, replaces current entry if exists */
    HMDR_SWAP,     /* puts new entry, swappes old entry with *entry otherwise */
} HashMapDuplicateResolution;

typedef enum {
    HMPR_FAILED = 0, /* map could not grow */
    HMPR_FOUND,      /* item already existed */
    HMPR_REPLACED,   /* item was replace */
    HMPR_SWAPPED,    /* item already existed and was swapped with *entry */
    HMPR_PUT,        /* new item was added to map */
} HashMapPutStatus;

#define _HASHMAP_BUCKET_NEXTCAP(min)        \
    if (!min) min = _HASHMAP_BUCKET_MINCAP; \
    else {                                  \
        min--;                              \
        min |= min >> 1;                    \
        min |= min >> 2;                    \
        min |= min >> 4;                    \
        min |= min >> 8;                    \
        min |= min >> 16;                   \
        /* uncomment for 64bit ints */      \
        /* min |= min >> 32; */             \
        min++;                              \
    }

#define _HASHMAP_NEXTCAP(min)               \
    if (!min) min = _HASHMAP_MINCAP;        \
    else _HASHMAP_BUCKET_NEXTCAP(min);

#define _HASHMAP_BUCKET(map, hash) &map->buckets[(hash) & (U64TYPE)(map->capacity-1)]

#define DEFINE_HASHMAP(NAME, HASH_T, VAL_T)                                    \
    typedef struct {                                                           \
        U32    size;                                                           \
        U32    capacity;                                                       \
        VAL_T* entries;                                                        \
    } NAME##_bucket;                                                           \
                                                                               \
    typedef struct {                                                           \
        U32            size;                                                   \
        U32            capacity;                                               \
        NAME##_bucket* buckets;                                                \
    } HASH_T;                                                                  \
                                                                               \
    typedef struct {                                                           \
        VAL_T*           entry;                                                \
        HashMapPutStatus status;                                               \
    } NAME##_put_result;                                                       \
                                                                               \
    typedef VAL_T  _##NAME##_vtype;                                            \
    typedef HASH_T _##NAME##_htype;                                            \
                                                                               \
    void NAME##_new     (HASH_T* map);                                         \
    void NAME##_destroy (HASH_T* map);                                         \
    bool NAME##_reserve (HASH_T* map, U32 capacity);                           \
    VAL_T*            NAME##_find   (const HASH_T* map, const _##NAME##_vtype* entry);          \
    NAME##_put_result NAME##_put    (HASH_T* map, VAL_T* entry, HashMapDuplicateResolution dr); \
    bool              NAME##_remove (HASH_T* map, VAL_T* entry);

/**
 * To iterate over all entries in order they are saved in the map.
 * You must not insert or delete elements in this loop.
 * You can use continue and break as in usual for-loops.
 * 
 * You HAVE TO put braces:
 *     HASHMAP_FOR_EACH(NAME, iter, map) {
 *         do_something();
 *     } HASHMAP_FOR_EACH_END
 *  It's meant as a feature ...
 * 
 * \param NAME Defined name of map
 * \param ITER _##NAME##_vtype* denoting the current element.
 * \param MAP Map to iterate over.
 */
#define HASHMAP_FOR_EACH(NAME, ITER, MAP)                                      \
    do {                                                                       \
        U32 __i, __h, __broke;                                                 \
        if(!(MAP).buckets || !(MAP).size) break;                               \
        for(__i = 0, __broke = 0; !__broke && __i < (MAP).capacity; ++__i) {   \
            if(!(MAP).buckets[__i].entries) continue;                          \
            for(__h = 0; !__broke && __h < (MAP).buckets[__i].size; ++__h) {   \
                ITER = &(MAP).buckets[__i].entries[__h];                       \
                __broke = 1;                                                   \
                do

/**
 * Closes a HASHMAP_FOR_EACH(...)
 */
#define HASHMAP_FOR_EACH_END                                                   \
                while( __broke = 0, __broke );                                 \
            }                                                                  \
        }                                                                      \
    } while(0);

/**
 * Like HASHMAP_FOR_EACH(ITER, MAP), but you are safe to delete elements during
 * the loop. You deleted elements may or may not show up during the for-loop!
 */
#define HASHMAP_FOR_EACH_SAFE_TO_DELETE(NAME, ITER, MAP)                       \
    do {                                                                       \
        U32 __i, __h, __broke;                                                 \
        if(!(MAP).buckets || !(MAP).size) break;                               \
        for(__i = 0, __broke = 0; !__broke && __i < (MAP).capacity; ++__i) {   \
            if(!(MAP).buckets[__i].entries) continue;                          \
            const U32 __size = (MAP).buckets[__i].size;                        \
            _##NAME##_vtype __entries[__size];                                 \
            memcpy(__entries, &(MAP).buckets[__i].entries, sizeof(__entries)); \
            for(__h = 0; !__broke && __h < __size; ++__h) {                    \
                ITER = &(MAP).buckets[__i].entries[__h];                       \
                __broke = true;                                                \
                do

/**
 * Closes a HASHMAP_FOR_EACH_SAFE_TO_DELETE(...)
 */
#define HASHMAP_FOR_EACH_SAFE_TO_DELETE_END HASHMAP_FOR_EACH_END

/**
 * Declares the hash map functions.
 * \param NAME Typedef'd name of the HashMap type.
 * \param CMP int (*cmp)(_##NAME##_vtype *left, _##NAME##_vtype *right).
 *            Could easily be a macro. Must return 0 if and only if *left
 *            equals *right.
 * \param GET_HASH inttype (*getHash)(_##NAME##_vtype *entry). Could easily be
 *                 a macro.
 * \param FREE free() to use
 * \param REALLOC realloc() to use. Assumes accordance with C standard, i.e.
 *                realloc(NULL, size) behaves as malloc(size).
 */
#define DECLARE_HASHMAP(NAME, CMP, GET_HASH, FREE, REALLOC)                    \
                                                                               \
void NAME##_new (_##NAME##_htype* map) {                                       \
    map->size = 0;                                                             \
    map->capacity = 0;                                                         \
    map->buckets = NULL;                                                       \
}                                                                              \
                                                                               \
void NAME##_destroy (_##NAME##_htype* map) {                                   \
    size_t i;                                                                  \
    if (map->buckets) {                                                        \
        const size_t capacity = map->capacity;                                 \
        for (i = 0; i < capacity; ++i) {                                       \
            if (map->buckets[i].entries) FREE(map->buckets[i].entries);        \
        }                                                                      \
        FREE(map->buckets);                                                    \
    }                                                                          \
    map->size = 0;                                                             \
    map->capacity = 0;                                                         \
    map->buckets = NULL;                                                       \
}                                                                              \
                                                                               \
/* Helper function that puts an entry into the map, with checking the size   */\
/* or minding duplicates.                                                    */\
/* \param map Map to put entry into.                                         */\
/* \param entry Entry to insert in map.                                      */\
/* \return pointer to inserted element, or NULL if could not grow            */\
static _##NAME##_vtype*                                                        \
_##NAME##_put_real (_##NAME##_htype* map, const _##NAME##_vtype* entry) {      \
    _##NAME##_vtype* result;                                                   \
    NAME##_bucket* bucket;                                                     \
    bucket = _HASHMAP_BUCKET(map, GET_HASH(entry));                            \
    if (bucket->capacity <= bucket->size) {                                    \
        size_t new_capacity = bucket->size + 1;                                \
        _HASHMAP_BUCKET_NEXTCAP(new_capacity);                                 \
        if (!new_capacity) return NULL;                                        \
        bucket->capacity = new_capacity;                                       \
        result = (_##NAME##_vtype*)(REALLOC(bucket->entries,                   \
                                  sizeof(_##NAME##_vtype[new_capacity])));     \
        if (!result) return NULL;                                              \
        bucket->entries = result;                                              \
    }                                                                          \
    result = &bucket->entries[bucket->size++];                                 \
    *result = *entry;                                                          \
    return result;                                                             \
}                                                                              \
                                                                               \
bool NAME##_reserve (_##NAME##_htype* map, U32 capacity) {                     \
    size_t old_capacity, i, h;                                                 \
    NAME##_bucket *old_buckets, *new_buckets;                                  \
    capacity = (capacity+2)/3 * 4; /* load factor = 0.75 */                    \
    if (map->capacity >= capacity) return true;                                \
    _HASHMAP_NEXTCAP(capacity);                                                \
    if (!capacity) return false;                                               \
    old_capacity = map->capacity;                                              \
    old_buckets = map->buckets;                                                \
    map->capacity = capacity;                                                  \
    new_buckets = (NAME##_bucket*) REALLOC(                                    \
        NULL, sizeof(NAME##_bucket[capacity])                                  \
    );                                                                         \
    if (!new_buckets) return false;                                            \
    memset(new_buckets, 0, sizeof(NAME##_bucket[capacity]));                   \
    map->buckets = new_buckets;                                                \
    /* TODO: a failed _##NAME##_put_real(...) would corrupt the map! */        \
    if (map->size) {                                                           \
        for (i = 0; i < old_capacity; ++i) {                                   \
            for (h = 0; h < old_buckets->size; ++h) {                          \
                _##NAME##_put_real(map, &old_buckets->entries[h]);             \
            }                                                                  \
            FREE(old_buckets->entries);                                        \
            old_buckets++;                                                     \
        }                                                                      \
    }                                                                          \
    FREE(old_buckets - old_capacity);                                          \
    return true;                                                               \
}                                                                              \
                                                                               \
_##NAME##_vtype*                                                               \
NAME##_find (const _##NAME##_htype* map, const _##NAME##_vtype* entry) {       \
    NAME##_bucket* bucket;                                                     \
    size_t h;                                                                  \
    if (!map->buckets) return NULL;                                            \
    bucket = _HASHMAP_BUCKET(map, GET_HASH(entry));                            \
    for (h = 0; h < bucket->size; ++h)                                         \
        if (!(CMP((&bucket->entries[h]), entry))) return &bucket->entries[h];  \
    return NULL;                                                               \
}                                                                              \
                                                                               \
NAME##_put_result NAME##_put (_##NAME##_htype* map, _##NAME##_vtype* entry,    \
                           HashMapDuplicateResolution dr) {                    \
    NAME##_put_result result;                                                  \
    _##NAME##_vtype tmp;                                                       \
    if ((result.entry = NAME##_find(map, entry))) {                            \
        switch (dr) {                                                          \
            case HMDR_FAIL:                                                    \
                result.status = HMPR_FAILED;                                   \
                return result;                                                 \
            case HMDR_REPLACE:                                                 \
                *result.entry = *entry;                                        \
                result.status = HMPR_REPLACED;                                 \
                return result;                                                 \
            case HMDR_SWAP:                                                    \
                tmp = *result.entry;                                           \
                *result.entry = *entry;                                        \
                *entry = tmp;                                                  \
                result.status = HMPR_SWAPPED;                                  \
                return result;                                                 \
            case HMDR_FIND:                                                    \
            default:                                                           \
                result.status = HMPR_FOUND;                                    \
                return result;                                                 \
        }                                                                      \
    }                                                                          \
    if (!NAME##_reserve(map, map->size+1)) {                                   \
        result.status = HMPR_FAILED;                                           \
        return result;                                                         \
    }                                                                          \
    result.entry = _##NAME##_put_real(map, entry);                             \
    if (!result.entry) {                                                       \
        result.status = HMPR_FAILED;                                           \
        return result;                                                         \
    }                                                                          \
    ++map->size;                                                               \
    result.status = HMPR_PUT;                                                  \
    return result;                                                             \
}                                                                              \
                                                                               \
bool NAME##_remove (_##NAME##_htype* map, _##NAME##_vtype* entry) {            \
    NAME##_bucket* bucket;                                                     \
    size_t nth;                                                                \
    if (!map->size) return false;                                              \
    bucket = _HASHMAP_BUCKET(map, GET_HASH(entry));                            \
    for (nth = 0; nth < bucket->size; ++nth) {                                 \
        if (!(CMP(entry, (&bucket->entries[nth])))) {                          \
            if (nth < bucket->size - 1)                                        \
                bucket->entries[nth] = bucket->entries[bucket->size-1];        \
            --bucket->size;                                                    \
            --map->size;                                                       \
            return true;                                                       \
        }                                                                      \
    }                                                                          \
    return false;                                                              \
}

#endif /* ifndef HASHMAP_H__ */

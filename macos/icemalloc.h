/*********************************************************************
Project	:	Perl5				-	
File	:	icemalloc.h			-	Memory allocator

$Log: icemalloc.h,v $
Revision 1.1  2000/08/14 01:48:17  neeri
Checked into Sourceforge

Revision 1.1  2000/05/14 21:45:04  neeri
First build released to public


*********************************************************************/

/*
**
** Notice.
**
** This source code was written by Tim Endres. time@ice.com
** Copyright 1988-1991 © By Tim Endres. All rights reserved.
**
** You may use this source code for any purpose you can dream
** of as long as this notice is never modified nor removed.
**
*/

#ifndef __ICEMALLOC__
#define __ICEMALLOC__

#include <sys/types.h>

#ifdef MALLOC_LOG
void MallocLog(const char * fmt, ...);
#endif

/*
** Right now we are limiting the maximum single allocation unit to 16Meg.
** This way we can stuff the index to the next ptr hdr into the
** low 24 bits of a long, then slam 8 bits of flag information
** into the upper 8 bits of the same long. Not necessarily beautiful
** but compact and functional.
*/

/*
**	_PM_DEBUG_LEVEL
**
**  1 - DPRINTF ERROR conditions.
**  2 - DPRINTF *AND* DACTION ERROR conditions.
**
**  3 - DPRINTF WARNING conditions.
**  5 - DPRINTF DEBUGING conditions.
** 10 - DPRINTF NOTES conditions.
**
*/

#undef DEBUG

#ifdef DEBUG

#	define _PM_STATS
#	define _PM_DYNAMIC_MERGING
#	define _PM_DYNAMIC_FREE

#	define	_PM_DEBUG_LEVEL		1

#	define DPRINTF(level, parms)	{ if ((level) <= pool_malloc_debug_level) { printf parms ; } }
#	define DACTION(level, action)	{ if ((level) <= pool_malloc_debug_level) { action } }

int		pool_malloc_debug_level = _PM_DEBUG_LEVEL;

#else

#	define _PM_DYNAMIC_MERGING
#	define _PM_DYNAMIC_FREE

#	define	_PM_DEBUG_LEVEL		0

#	define DPRINTF(level, parms)
#	define DACTION(level, action)

#endif DEVELOPMENT


/*
** MEMORY PTR HEADER FLAG BITS:
**
** 01 _PM_PTR_FREE		Is this piece of memory free?
** 02
** 04
** 08
**
** 10
** 20
** 40
** 80 _PM_PTR_PARITY	This is a parity bit for debugging.
**
*/

#define _PM_PTR_USED		0x01
#define _PM_PTR_PARITY		0x80

#define _PM_MIN_ALLOC_SIZE	8

#define	ALIGNMENT				4		/* The 68020 likes things long aligned. */
#define INT_ALIGN(i, r)			( ((i) + ((r) - 1)) & ~((r) - 1) )


#define SUGGESTED_BLK_SIZE		32768


#define GET_PTR_FLAGS(hdr)	\
	( (u_long) ( (((hdr)->size) >> 24) & 0x000000FF ) )
#define SET_PTR_USED(hdr)	\
	( (hdr)->size |= (((_PM_PTR_USED) << 24) & 0xFF000000) )
#define SET_PTR_FREE(hdr)	\
	( (hdr)->size &= ~(((_PM_PTR_USED) << 24) & 0xFF000000) )
#define IS_PTR_USED(hdr)	\
	( (GET_PTR_FLAGS(hdr) & _PM_PTR_USED) != 0 )
#define IS_PTR_FREE(hdr)	\
	( (GET_PTR_FLAGS(hdr) & _PM_PTR_USED) == 0 )

#define GET_PTR_SIZE(hdr)	\
	( (u_long) ( ((hdr)->size) & 0x00FFFFFF ) )
#define SET_PTR_SIZE(hdr, blksize)	\
	( (hdr)->size = ( ((hdr)->size & 0XFF000000) | ((blksize) & 0x00FFFFFF) ) )

typedef struct {
	u_long		size;
	} _mem_ptr_hdr, *_mem_ptr_hdr_ptr;


/* There are two storage methods. Blocks smaller than 64 bytes are allocated
   from a _MEM_BUCKET, larger blocks from a _MEM_BLK.
*/

typedef struct _MEM_BUCKET {
	struct _MEM_BUCKET * next;				/* Next bucket 										*/
	struct _MEM_BUCKET * prev;				/* Previous bucket									*/
	struct _MEM_POOL   * pool;				/* The bucket's pool									*/
	char *					memory;			/* The bucket's allocated memory. 				*/
	char *					free;				/* First free block 									*/
	short						max_count;		/* Total # of blocks 								*/
	short						free_count;		/* # of free blocks in this bucket 				*/
} _mem_bucket, *_mem_bucket_ptr;

typedef struct _MEM_BLK {
	u_long				size;				/* The size of this block's memory. */
	char					*memory;			/* The block's allocated memory. */
	u_long				max_free;		/* The maximum free size in the block */
	struct _MEM_BLK	*next;			/* The next block in the pool block list. */
	struct _MEM_POOL	*pool;			/* The block's pool. */
	} _mem_blk, *_mem_blk_ptr;


typedef struct _MEM_POOL {
	int					id;				/* The pool's ID. 							*/
	u_long				pref_blk_size;	/* The preferred size of new blks.		*/
	u_long				limit_blk_size;	/* Maximum size for a single blk.		*/
	_mem_bucket_ptr	blk_16;			/* Blocks <= 16 bytes						*/
	_mem_bucket_ptr	free_16;			/* Blocks <= 16 bytes						*/
	_mem_bucket_ptr	blk_32;			/* Blocks <= 32 bytes						*/
	_mem_bucket_ptr	free_32;			/* Blocks <= 32 bytes						*/
	_mem_bucket_ptr	blk_64;			/* Blocks <= 64 bytes						*/
	_mem_bucket_ptr	free_64;			/* Blocks <= 64 bytes						*/
	_mem_blk_ptr		blk_list;		/* The list of blocks in the pool. 		*/
	struct _MEM_POOL	*next;			/* The next pool in the forest. 			*/
#ifdef _PM_STATS
	u_long				total_memory;	/* The total allocated memory by this pool */
	u_long				total_storage;	/* The total malloc-able storage in this pool */
	u_long				total_malloc;	/* The total malloc-ed storage not freed. */
	u_long				max_blk_size;	/* The maximum block size allocated. */
	float					ave_req_size;	/* The ave allocated request size */
	u_long				ave_req_total;	/* The total requests in the average. */
	float					ave_blk_size;	/* The ave sallocated blk size */
	u_long				ave_blk_total;	/* The total blks in the average. */
#endif
	} _mem_pool, *_mem_pool_ptr;



extern _mem_pool	_mem_system_pool;

/*
** The memory pool forest. To the user, this is simply a disjoint
** group of memory pools, in which his memory pools lie. We keep
** it as a simple linked list. Forward linked, nothing fancy.
**
** The default pool is simply the front pool in the pool forest list.
*/
extern _mem_pool_ptr	_mem_pool_forest;

#define _default_mem_pool	_mem_pool_forest


void	* 				pool_malloc(_mem_pool_ptr pool, u_long size);
void	* 				pool_realloc(_mem_pool_ptr pool, void * ptr, u_long size);
int 					pool_free(void * ptr);
int 					free_pool(int id);
int 					free_pool_memory(int id);
_mem_pool_ptr		find_pool(int id);
_mem_pool_ptr		new_malloc_pool(int id, u_long pref_blk_size);
int 					set_default_pool(int id);
int 					merge_free_list();
void 					get_malloc_stats(long * total_memory, long * total_free, long * total_malloc);

#endif
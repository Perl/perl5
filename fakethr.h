typedef int perl_mutex;
typedef int perl_key;

struct perl_wait_queue {
    struct thread *		thread;
    struct perl_wait_queue *	next;
};
typedef struct perl_wait_queue *perl_cond;

/* Ask thread.h to include our per-thread extras */
#define HAVE_THREAD_INTERN
struct thread_intern {
    perl_thread next_run, prev_run;     /* Linked list of runnable threads */
    perl_cond   wait_queue;             /* Wait queue that we are waiting on */
    IV          private;                /* Holds data across time slices */
    I32         savemark;               /* Holds MARK for thread join values */
};

#define init_thread_intern(t) 				\
    STMT_START {					\
	t->Tself = (t);					\
	(t)->i.next_run = (t)->i.prev_run = (t);	\
	(t)->i.wait_queue = 0;				\
	(t)->i.private = 0;				\
    } STMT_END


typedef int perl_mutex;
typedef int perl_key;

struct perl_wait_queue {
    struct thread *		thread;
    struct perl_wait_queue *	next;
};
typedef struct perl_wait_queue *perl_cond;

struct thread_intern {
    perl_thread next_run, prev_run;     /* Linked list of runnable threads */
    perl_cond   wait_queue;             /* Wait queue that we are waiting on */
    IV          private;                /* Holds data across time slices */
    I32         savemark;               /* Holds MARK for thread join values */
};

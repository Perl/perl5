/*
 * @(#) dir.h 1.4 87/11/06   Public Domain.
 *
 *  A public domain implementation of BSD directory routines for
 *  MS-DOS.  Written by Michael Rendell ({uunet,utai}michael@garfield),
 *  August 1987
 *
 *  Enhanced and ported to OS/2 by Kai Uwe Rommel; added scandir() prototype
 *  December 1989, February 1990
 */


#define MAXNAMLEN  12
#define MAXPATHLEN 128

#define A_RONLY    0x01
#define A_HIDDEN   0x02
#define A_SYSTEM   0x04
#define A_LABEL    0x08
#define A_DIR      0x10
#define A_ARCHIVE  0x20


struct direct
{
  ino_t d_ino;                   /* a bit of a farce */
  int   d_reclen;                /* more farce */
  int   d_namlen;                /* length of d_name */
  char  d_name[MAXNAMLEN + 1];   /* null terminated */
  long  d_size;                  /* size in bytes */
  int   d_mode;                  /* DOS or OS/2 file attributes */
};

/* The fields d_size and d_mode are extensions by me (Kai Uwe Rommel).
 * The find_first and find_next calls deliver this data without any extra cost.
 * If this data is needed, these fields save a lot of extra calls to stat()
 * (each stat() again performs a find_first call !).
 */

struct _dircontents
{
  char *_d_entry;
  long _d_size;
  int _d_mode;
  struct _dircontents *_d_next;
};

typedef struct _dirdesc
{
  int  dd_id;                   /* uniquely identify each open directory */
  long dd_loc;                  /* where we are in directory entry is this */
  struct _dircontents *dd_contents;   /* pointer to contents of dir */
  struct _dircontents *dd_cp;         /* pointer to current position */
}
DIR;


extern DIR *opendir(char *);
extern struct direct *readdir(DIR *);
extern void seekdir(DIR *, long);
extern long telldir(DIR *);
extern void closedir(DIR *);
#define rewinddir(dirp) seekdir(dirp, 0L)

extern int scandir(char *, struct direct ***,
                   int (*)(struct direct *),
                   int (*)(struct direct *, struct direct *));

extern int getfmode(char *);
extern int setfmode(char *, unsigned);

/*
NAME
     opendir, readdir, telldir, seekdir, rewinddir, closedir -
     directory operations

SYNTAX
     #include <sys/types.h>
     #include <sys/dir.h>

     DIR *opendir(filename)
     char *filename;

     struct direct *readdir(dirp)
     DIR *dirp;

     long telldir(dirp)
     DIR *dirp;

     seekdir(dirp, loc)
     DIR *dirp;
     long loc;

     rewinddir(dirp)
     DIR *dirp;

     int closedir(dirp)
     DIR *dirp;

DESCRIPTION
     The opendir library routine opens the directory named by
     filename and associates a directory stream with it.  A
     pointer is returned to identify the directory stream in sub-
     sequent operations.  The pointer NULL is returned if the
     specified filename can not be accessed, or if insufficient
     memory is available to open the directory file.

     The readdir routine returns a pointer to the next directory
     entry.  It returns NULL upon reaching the end of the direc-
     tory or on detecting an invalid seekdir operation.  The
     readdir routine uses the getdirentries system call to read
     directories. Since the readdir routine returns NULL upon
     reaching the end of the directory or on detecting an error,
     an application which wishes to detect the difference must
     set errno to 0 prior to calling readdir.

     The telldir routine returns the current location associated
     with the named directory stream. Values returned by telldir
     are good only for the lifetime of the DIR pointer from which
     they are derived.  If the directory is closed and then reo-
     pened, the telldir value may be invalidated due to
     undetected directory compaction.

     The seekdir routine sets the position of the next readdir
     operation on the directory stream. Only values returned by
     telldir should be used with seekdir.

     The rewinddir routine resets the position of the named
     directory stream to the beginning of the directory.

     The closedir routine closes the named directory stream and
     returns a value of 0 if successful. Otherwise, a value of -1
     is returned and errno is set to indicate the error.  All
     resources associated with this directory stream are
     released.

EXAMPLE
     The following sample code searches a directory for the entry
     name.

     len = strlen(name);

     dirp = opendir(".");

     for (dp = readdir(dirp); dp != NULL; dp = readdir(dirp))

     if (dp->d_namlen == len && !strcmp(dp->d_name, name)) {

               closedir(dirp);

               return FOUND;

          }

     closedir(dirp);

     return NOT_FOUND;


SEE ALSO
     close(2), getdirentries(2), lseek(2), open(2), read(2),
     dir(5)
*/

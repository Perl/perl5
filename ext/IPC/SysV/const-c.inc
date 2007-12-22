#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPC_M IPC_R IPC_W MSG_R MSG_W SEM_A SEM_R SHM_A SHM_R SHM_W */
  /* Offset 1 gives the best switch position.  */
  switch (name[1]) {
  case 'E':
    if (memEQ(name, "SEM_A", 5)) {
    /*                ^         */
#ifdef SEM_A
      *iv_return = SEM_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEM_R", 5)) {
    /*                ^         */
#ifdef SEM_R
      *iv_return = SEM_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "SHM_A", 5)) {
    /*                ^         */
#ifdef SHM_A
      *iv_return = SHM_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_R", 5)) {
    /*                ^         */
#ifdef SHM_R
      *iv_return = SHM_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_W", 5)) {
    /*                ^         */
#ifdef SHM_W
      *iv_return = SHM_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "IPC_M", 5)) {
    /*                ^         */
#ifdef IPC_M
      *iv_return = IPC_M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "IPC_R", 5)) {
    /*                ^         */
#ifdef IPC_R
      *iv_return = IPC_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "IPC_W", 5)) {
    /*                ^         */
#ifdef IPC_W
      *iv_return = IPC_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MSG_R", 5)) {
    /*                ^         */
#ifdef MSG_R
      *iv_return = MSG_R;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_W", 5)) {
    /*                ^         */
#ifdef MSG_W
      *iv_return = MSG_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ENOSPC ENOSYS GETALL GETPID GETVAL SETALL SETVAL SHMLBA */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "GETVAL", 6)) {
    /*                   ^       */
#ifdef GETVAL
      *iv_return = GETVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SETVAL", 6)) {
    /*                   ^       */
#ifdef SETVAL
      *iv_return = SETVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "SHMLBA", 6)) {
    /*                   ^       */
#ifdef SHMLBA
      *iv_return = SHMLBA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GETPID", 6)) {
    /*                   ^       */
#ifdef GETPID
      *iv_return = GETPID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GETALL", 6)) {
    /*                   ^       */
#ifdef GETALL
      *iv_return = GETALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SETALL", 6)) {
    /*                   ^       */
#ifdef SETALL
      *iv_return = SETALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "ENOSPC", 6)) {
    /*                   ^       */
#ifdef ENOSPC
      *iv_return = ENOSPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "ENOSYS", 6)) {
    /*                   ^       */
#ifdef ENOSYS
      *iv_return = ENOSYS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GETNCNT GETZCNT IPC_SET SEM_ERR SHM_MAP SHM_RND S_IRGRP S_IROTH S_IRUSR
     S_IRWXG S_IRWXO S_IRWXU S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'C':
    if (memEQ(name, "GETNCNT", 7)) {
    /*                   ^        */
#ifdef GETNCNT
      *iv_return = GETNCNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GETZCNT", 7)) {
    /*                   ^        */
#ifdef GETZCNT
      *iv_return = GETZCNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SEM_ERR", 7)) {
    /*                   ^        */
#ifdef SEM_ERR
      *iv_return = SEM_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "S_IRGRP", 7)) {
    /*                   ^        */
#ifdef S_IRGRP
      *iv_return = S_IRGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWGRP", 7)) {
    /*                   ^        */
#ifdef S_IWGRP
      *iv_return = S_IWGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXGRP", 7)) {
    /*                   ^        */
#ifdef S_IXGRP
      *iv_return = S_IXGRP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SHM_MAP", 7)) {
    /*                   ^        */
#ifdef SHM_MAP
      *iv_return = SHM_MAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "S_IROTH", 7)) {
    /*                   ^        */
#ifdef S_IROTH
      *iv_return = S_IROTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWOTH", 7)) {
    /*                   ^        */
#ifdef S_IWOTH
      *iv_return = S_IWOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXOTH", 7)) {
    /*                   ^        */
#ifdef S_IXOTH
      *iv_return = S_IXOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SHM_RND", 7)) {
    /*                   ^        */
#ifdef SHM_RND
      *iv_return = SHM_RND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "IPC_SET", 7)) {
    /*                   ^        */
#ifdef IPC_SET
      *iv_return = IPC_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "S_IRUSR", 7)) {
    /*                   ^        */
#ifdef S_IRUSR
      *iv_return = S_IRUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IWUSR", 7)) {
    /*                   ^        */
#ifdef S_IWUSR
      *iv_return = S_IWUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IXUSR", 7)) {
    /*                   ^        */
#ifdef S_IXUSR
      *iv_return = S_IXUSR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "S_IRWXG", 7)) {
    /*                   ^        */
#ifdef S_IRWXG
      *iv_return = S_IRWXG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXO", 7)) {
    /*                   ^        */
#ifdef S_IRWXO
      *iv_return = S_IRWXO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "S_IRWXU", 7)) {
    /*                   ^        */
#ifdef S_IRWXU
      *iv_return = S_IRWXU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPC_EXCL IPC_INFO IPC_RMID IPC_STAT MSG_INFO MSG_STAT MSG_WAIT SEM_DEST
     SEM_INFO SEM_STAT SEM_UNDO SHM_COPY SHM_DEST SHM_FMAP SHM_INFO SHM_INIT
     SHM_LOCK SHM_SIZE SHM_STAT */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'C':
    if (memEQ(name, "SHM_COPY", 8)) {
    /*                   ^         */
#ifdef SHM_COPY
      *iv_return = SHM_COPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "SEM_DEST", 8)) {
    /*                   ^         */
#ifdef SEM_DEST
      *iv_return = SEM_DEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_DEST", 8)) {
    /*                   ^         */
#ifdef SHM_DEST
      *iv_return = SHM_DEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "IPC_EXCL", 8)) {
    /*                   ^         */
#ifdef IPC_EXCL
      *iv_return = IPC_EXCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "SHM_FMAP", 8)) {
    /*                   ^         */
#ifdef SHM_FMAP
      *iv_return = SHM_FMAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "IPC_INFO", 8)) {
    /*                   ^         */
#ifdef IPC_INFO
      *iv_return = IPC_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_INFO", 8)) {
    /*                   ^         */
#ifdef MSG_INFO
      *iv_return = MSG_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEM_INFO", 8)) {
    /*                   ^         */
#ifdef SEM_INFO
      *iv_return = SEM_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_INFO", 8)) {
    /*                   ^         */
#ifdef SHM_INFO
      *iv_return = SHM_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_INIT", 8)) {
    /*                   ^         */
#ifdef SHM_INIT
      *iv_return = SHM_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SHM_LOCK", 8)) {
    /*                   ^         */
#ifdef SHM_LOCK
      *iv_return = SHM_LOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "IPC_RMID", 8)) {
    /*                   ^         */
#ifdef IPC_RMID
      *iv_return = IPC_RMID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "IPC_STAT", 8)) {
    /*                   ^         */
#ifdef IPC_STAT
      *iv_return = IPC_STAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_STAT", 8)) {
    /*                   ^         */
#ifdef MSG_STAT
      *iv_return = MSG_STAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEM_STAT", 8)) {
    /*                   ^         */
#ifdef SEM_STAT
      *iv_return = SEM_STAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_SIZE", 8)) {
    /*                   ^         */
#ifdef SHM_SIZE
      *iv_return = SHM_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_STAT", 8)) {
    /*                   ^         */
#ifdef SHM_STAT
      *iv_return = SHM_STAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "SEM_UNDO", 8)) {
    /*                   ^         */
#ifdef SEM_UNDO
      *iv_return = SEM_UNDO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "MSG_WAIT", 8)) {
    /*                   ^         */
#ifdef MSG_WAIT
      *iv_return = MSG_WAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPC_ALLOC IPC_CREAT MSG_FWAIT MSG_MWAIT MSG_QWAIT MSG_RWAIT MSG_WWAIT
     SEM_ALLOC SEM_ORDER SHM_CLEAR SHM_REMAP */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "IPC_ALLOC", 9)) {
    /*                   ^          */
#ifdef IPC_ALLOC
      *iv_return = IPC_ALLOC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SEM_ALLOC", 9)) {
    /*                   ^          */
#ifdef SEM_ALLOC
      *iv_return = SEM_ALLOC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "IPC_CREAT", 9)) {
    /*                   ^          */
#ifdef IPC_CREAT
      *iv_return = IPC_CREAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_CLEAR", 9)) {
    /*                   ^          */
#ifdef SHM_CLEAR
      *iv_return = SHM_CLEAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "MSG_FWAIT", 9)) {
    /*                   ^          */
#ifdef MSG_FWAIT
      *iv_return = MSG_FWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "MSG_MWAIT", 9)) {
    /*                   ^          */
#ifdef MSG_MWAIT
      *iv_return = MSG_MWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SEM_ORDER", 9)) {
    /*                   ^          */
#ifdef SEM_ORDER
      *iv_return = SEM_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "MSG_QWAIT", 9)) {
    /*                   ^          */
#ifdef MSG_QWAIT
      *iv_return = MSG_QWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MSG_RWAIT", 9)) {
    /*                   ^          */
#ifdef MSG_RWAIT
      *iv_return = MSG_RWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_REMAP", 9)) {
    /*                   ^          */
#ifdef SHM_REMAP
      *iv_return = SHM_REMAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "MSG_WWAIT", 9)) {
    /*                   ^          */
#ifdef MSG_WWAIT
      *iv_return = MSG_WWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPC_GETACL IPC_LOCKED IPC_NOWAIT IPC_SETACL IPC_WANTED MSG_EXCEPT
     MSG_LOCKED SHM_DCACHE SHM_ECACHE SHM_ICACHE SHM_LOCKED SHM_NOSWAP
     SHM_RDONLY SHM_SHATTR SHM_UNLOCK */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "SHM_DCACHE", 10)) {
    /*                   ^            */
#ifdef SHM_DCACHE
      *iv_return = SHM_DCACHE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MSG_EXCEPT", 10)) {
    /*                   ^            */
#ifdef MSG_EXCEPT
      *iv_return = MSG_EXCEPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_ECACHE", 10)) {
    /*                   ^            */
#ifdef SHM_ECACHE
      *iv_return = SHM_ECACHE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "IPC_GETACL", 10)) {
    /*                   ^            */
#ifdef IPC_GETACL
      *iv_return = IPC_GETACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SHM_ICACHE", 10)) {
    /*                   ^            */
#ifdef SHM_ICACHE
      *iv_return = SHM_ICACHE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "IPC_LOCKED", 10)) {
    /*                   ^            */
#ifdef IPC_LOCKED
      *iv_return = IPC_LOCKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_LOCKED", 10)) {
    /*                   ^            */
#ifdef MSG_LOCKED
      *iv_return = MSG_LOCKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_LOCKED", 10)) {
    /*                   ^            */
#ifdef SHM_LOCKED
      *iv_return = SHM_LOCKED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "IPC_NOWAIT", 10)) {
    /*                   ^            */
#ifdef IPC_NOWAIT
      *iv_return = IPC_NOWAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_NOSWAP", 10)) {
    /*                   ^            */
#ifdef SHM_NOSWAP
      *iv_return = SHM_NOSWAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SHM_RDONLY", 10)) {
    /*                   ^            */
#ifdef SHM_RDONLY
      *iv_return = SHM_RDONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "IPC_SETACL", 10)) {
    /*                   ^            */
#ifdef IPC_SETACL
      *iv_return = IPC_SETACL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SHM_SHATTR", 10)) {
    /*                   ^            */
#ifdef SHM_SHATTR
      *iv_return = SHM_SHATTR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "SHM_UNLOCK", 10)) {
    /*                   ^            */
#ifdef SHM_UNLOCK
      *iv_return = SHM_UNLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "IPC_WANTED", 10)) {
    /*                   ^            */
#ifdef IPC_WANTED
      *iv_return = IPC_WANTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPC_NOERROR IPC_PRIVATE MSG_NOERROR SHM_HUGETLB SHM_REMOVED */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "IPC_NOERROR", 11)) {
    /*                     ^           */
#ifdef IPC_NOERROR
      *iv_return = IPC_NOERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MSG_NOERROR", 11)) {
    /*                     ^           */
#ifdef MSG_NOERROR
      *iv_return = MSG_NOERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SHM_HUGETLB", 11)) {
    /*                     ^           */
#ifdef SHM_HUGETLB
      *iv_return = SHM_HUGETLB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "IPC_PRIVATE", 11)) {
    /*                     ^           */
#ifdef IPC_PRIVATE
      *iv_return = IPC_PRIVATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SHM_REMOVED", 11)) {
    /*                     ^           */
#ifdef SHM_REMOVED
      *iv_return = SHM_REMOVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/home/mhx/perl/blead-debug/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(ENOSPC ENOSYS GETALL GETNCNT GETPID GETVAL GETZCNT IPC_ALLOC
	       IPC_CREAT IPC_EXCL IPC_GETACL IPC_INFO IPC_LOCKED IPC_M
	       IPC_NOERROR IPC_NOWAIT IPC_PRIVATE IPC_R IPC_RMID IPC_SET
	       IPC_SETACL IPC_SETLABEL IPC_STAT IPC_W IPC_WANTED MSG_EXCEPT
	       MSG_FWAIT MSG_INFO MSG_LOCKED MSG_MWAIT MSG_NOERROR MSG_QWAIT
	       MSG_R MSG_RWAIT MSG_STAT MSG_W MSG_WAIT MSG_WWAIT SEM_A
	       SEM_ALLOC SEM_DEST SEM_ERR SEM_INFO SEM_ORDER SEM_R SEM_STAT
	       SEM_UNDO SETALL SETVAL SHMLBA SHM_A SHM_CLEAR SHM_COPY
	       SHM_DCACHE SHM_DEST SHM_ECACHE SHM_FMAP SHM_HUGETLB SHM_ICACHE
	       SHM_INFO SHM_INIT SHM_LOCK SHM_LOCKED SHM_MAP SHM_NORESERVE
	       SHM_NOSWAP SHM_R SHM_RDONLY SHM_REMAP SHM_REMOVED SHM_RND
	       SHM_SHARE_MMU SHM_SHATTR SHM_SIZE SHM_STAT SHM_UNLOCK SHM_W
	       S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU S_IWGRP S_IWOTH
	       S_IWUSR S_IXGRP S_IXOTH S_IXUSR));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("IPC::SysV", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("IPC::SysV", $types);
__END__
   */

  switch (len) {
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "IPC_SETLABEL", 12)) {
#ifdef IPC_SETLABEL
      *iv_return = IPC_SETLABEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    /* Names all of length 13.  */
    /* SHM_NORESERVE SHM_SHARE_MMU */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'N':
      if (memEQ(name, "SHM_NORESERVE", 13)) {
      /*                   ^               */
#ifdef SHM_NORESERVE
        *iv_return = SHM_NORESERVE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SHM_SHARE_MMU", 13)) {
      /*                   ^               */
#ifdef SHM_SHARE_MMU
        *iv_return = SHM_SHARE_MMU;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}


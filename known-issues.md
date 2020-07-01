
# cpan directory

## cpan/Encode/t/`*`.t

adjust PERL_CORE to use correct lib

## cpan/IO-Socket-IP/lib/IO/Socket/IP.pm, cpan/Sys-Syslog/Syslog.pm

need to return with a true value `1`

## cpan/Math-Complex/t/Complex.t

missing `_stringify_cartesian` and `_stringify_polar` functions

## cpan/NEXT/t/next.t

should not print plan in BEGIN block - optional

## cpan/Unicode-Collate/Makefile.PL

`File::Spec` as hash key

## cpan/podlators/scripts/pod2man.PL & co

using undefined variable for `if \$running_under_some_shell;`
better using something like `if 0 && q[Running Under Some Perl];`

# t directory

## t/io/sem.t

Test file `t/io/sem.t` was introduced into the core distribution in commit 64d76282359 in December 2013 and is almost entirely unchanged since then.  When run as part of the test suite, it appears entirely ordinary.
```
$ cd t;./perl harness -v io/sem.t; cd -

ok 1 - acquired semaphore
ok 2 - Initialize all 10 semaphores to zero
ok 3 - Set semaphore 3 to 17
ok 4 - Get current semaphore values
ok 5 - Make sure we get back statuses for all 10 semaphores
ok 6 - Checking value of semaphore 3
ok 7 - Check value via GETVAL
ok
All tests successful.
Files=1, Tests=7,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.02 cusr  0.00 csys =  0.03 CPU)
Result: PASS
```
However, the file was written without using any warnings.  If we simply add a `-w` flag to its shebang line and re-run it, we get:
```
$ cd t;./perl harness -v io/sem.t; cd -

ok 1 - acquired semaphore
ok 2 - Initialize all 10 semaphores to zero
ok 3 - Set semaphore 3 to 17
ok 4 - Get current semaphore values
ok 5 - Make sure we get back statuses for all 10 semaphores
ok 6 - Checking value of semaphore 3
ok 7 - Check value via GETVAL
Argument "ignore" isn't numeric in semctl at io/sem.t line 50.
Argument "ignore" isn't numeric in semctl at io/sem.t line 59.
Use of uninitialized value $semvals in semctl at io/sem.t line 59.
Argument "ignored" isn't numeric in semctl at io/sem.t line 69.
ok
All tests successful.
Files=1, Tests=7,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.01 cusr  0.00 csys =  0.02 CPU)
Result: PASS
```
In the core-p7 branch I've been working on making test files strict- and warnings-compliant.  In many cases, inserting a `no warnings 'numeric'` would be sufficient.  However, in this case, the warning is significant because it points to a flaw in the test file and, potentially, a flaw in `perl` itself.

Here is the first instance of the warning cited above:
```
    ok(semctl($id, "ignore", SETALL, pack("s!*",(0)x$nsem)),
       "Initialize all $nsem semaphores to zero");
```
Now, it's perfectly obvious that `"ignore"` is non-numeric; hence, the warning.  But a case can be made that semctl() should die with a non-numeric argument rather than simply warn.  `perldoc -f semctl` starts:
```
   semctl ID,SEMNUM,CMD,ARG
        Calls the System V IPC function semctl(2).
```
... but has nothing further to say about `SEMNUM` -- though that spelling suggests the argument ought to be numeric.

If, however, we look under the hood, we see that the second argument in the underlying system call *must* be an `int`.  On Linux:
```
$ man 2 semctl
SYNOPSIS
       #include <sys/types.h>
       #include <sys/ipc.h>
       #include <sys/sem.h>

       int semctl(int semid, int semnum, int cmd, ...);

DESCRIPTION
       semctl() performs the control operation specified by cmd on the System V semaphore set iden‐
       tified by semid, or on the semnum-th semaphore of that set.  (The semaphores in  a  set  are
       numbered starting at 0.)
```
On OpenBSD:
```
SYNOPSIS
     #include <sys/sem.h>

     int
     semctl(int semid, int semnum, int cmd, union semun arg);

```
Shouldn't the Perl `semctl()` built-in `die` rather than `warn` if provided the wrong type for its second argument?


## t/io/nargv.tt/io/nargv.t

END block unlink

## t/io/open.t, t/io/openpid.t

need to cleanup ENV and delete PATH

## t/io/perlio.t

chdir to t

## t/re/`*`.t

fix multiple test to chdir in t

## t/run/runenv.t

delete ENV{PATH}

# lib directory

## lib/File/Compare.t

incorrect usage of or in `($^O eq "cygwin") or ($^O eq "vos");`

## lib/Net/netent.t, lib/Net/protoent.t, lib/Net/servent.t, lib/User/pwent.t

`our @netent` variable define in BEGIN scope

## lib/vmsish.t

issue when testing hints?

# Porting directory

## Porting/makerel

do not check for clean `.xz` and `.tar.gz` file

# utils directory

## utils/corelist.PL & co

using undefined variable for `if \$running_under_some_shell;`
better using something like `if 0 && q[Running Under Some Perl];`



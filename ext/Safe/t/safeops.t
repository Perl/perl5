#!perl
# Tests that all ops can be trapped by a Safe compartment

BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = '../lib';
    }
    else {
	# this won't work outside of the core, so exit
        print "1..0\n"; exit 0;
    }
}
use Config;
BEGIN {
    if ($Config{'extensions'} !~ /\bOpcode\b/ && $Config{'osname'} ne 'VMS') {
        print "1..0\n"; exit 0;
    }
}

use strict;
use Test::More tests => 354;
use Safe;

# Read the op names and descriptions directly from opcode.pl
my @op;
my @opname;
open my $fh, '<', '../opcode.pl' or die "Can't open opcode.pl: $!";
while (<$fh>) {
    last if /^__END__/;
}
while (<$fh>) {
    chomp;
    next if !$_ or /^#/;
    my ($op, $opname) = split /\t+/;
    push @op, $op;
    push @opname, $opname;
}
close $fh;

sub testop {
    my ($op, $opname, $code) = @_;
    pass("$op : skipped") and return if $code =~ /^SKIP/;
    pass("$op : skipped") and return if $code =~ m://: && $] < 5.009; # no dor
    my $c = new Safe;
    $c->deny_only($op);
    $c->reval($code);
    like($@, qr/'\Q$opname\E' trapped by operation mask/, $op);
}

my $i = 0;
while (<DATA>) {
    testop $op[$i], $opname[$i], $_;
    ++$i;
}

# lists op examples, in the same order than opcode.pl
# things that begin with SKIP are skipped, for various reasons (notably
# optree modified by the optimizer -- Safe checks are done before the
# optimizer modifies the optree)

__DATA__
SKIP # null
SKIP # stub
scalar $x # scalar
print @x # pushmark
wantarray # wantarray
42 # const
SKIP (set by optimizer) $x # gvsv
SKIP *x # gv
*x{SCALAR} # gelem
SKIP my $x # padsv
SKIP my @x # padav
SKIP my %x # padhv
SKIP (not implemented) # padany
SKIP split /foo/ # pushre
*x # rv2gv
$x # rv2sv
$#x # av2arylen
f() # rv2cv
sub { } # anoncode
prototype 'foo' # prototype
\($x,$y) # refgen
SKIP \$x # srefgen
ref # ref
bless # bless
qx/ls/ # backtick
<*.c> # glob
<FH> # readline
SKIP (set by optimizer) $x .= <F> # rcatline
SKIP (internal) # regcmaybe
SKIP (internal) # regcreset
SKIP (internal) # regcomp
/foo/ # match
qr/foo/ # qr
s/foo/bar/ # subst
SKIP (set by optimizer) # substcont
y:z:t: # trans
$x = $y # sassign
@x = @y # aassign
chop @foo # chop
chop # schop
chomp @foo # chomp
chomp # schomp
defined # defined
undef # undef
study # study
pos # pos
++$i # preinc
SKIP (set by optimizer) # i_preinc
--$i # predec
SKIP (set by optimizer) # i_predec
$i++ # postinc
SKIP (set by optimizer) # i_postinc
$i-- # postdec
SKIP (set by optimizer) # i_postdec
$x ** $y # pow
$x * $y # multiply
SKIP (set by optimizer) # i_multiply
$x / $y # divide
SKIP (set by optimizer) # i_divide
$x % $y # modulo
SKIP (set by optimizer) # i_modulo
$x x $y # repeat
$x + $y # add
SKIP (set by optimizer) # i_add
$x - $y # subtract
SKIP (set by optimizer) # i_subtract
$x . $y # concat
"$x" # stringify
$x << 1 # left_shift
$x >> 1 # right_shift
$x < $y # lt
SKIP (set by optimizer) # i_lt
$x > $y # gt
SKIP (set by optimizer) # i_gt
$i <= $y # le
SKIP (set by optimizer) # i_le
$i >= $y # ge
SKIP (set by optimizer) # i_ge
$x == $y # eq
SKIP (set by optimizer) # i_eq
$x != $y # ne
SKIP (set by optimizer) # i_ne
$i <=> $y # ncmp
SKIP (set by optimizer) # i_ncmp
$x lt $y # slt
$x gt $y # sgt
$x le $y # sle
$x ge $y # sge
$x eq $y # seq
$x ne $y # sne
$x cmp $y # scmp
$x & $y # bit_and
$x ^ $y # bit_xor
$x | $y # bit_or
-$x # negate
SKIP (set by optimizer) # i_negate
!$x # not
~$x # complement
atan2 1 # atan2
sin 1 # sin
cos 1 # cos
rand # rand
srand # srand
exp 1 # exp
log 1 # log
sqrt 1 # sqrt
int # int
hex # hex
oct # oct
abs # abs
length # length
substr $x, 1 # substr
vec # vec
index # index
rindex # rindex
sprintf '%s', 'foo' # sprintf
formline # formline
ord # ord
chr # chr
crypt 'foo','bar' # crypt
ucfirst # ucfirst
lcfirst # lcfirst
uc # uc
lc # lc
quotemeta # quotemeta
@a # rv2av
SKIP (set by optimizer) # aelemfast
$a[1] # aelem
@a[1,2] # aslice
each %h # each
values %h # values
keys %h # keys
delete $h{Key} # delete
exists $h{Key} # exists
%h # rv2hv
$h{kEy} # helem
@h{kEy} # hslice
unpack # unpack
pack # pack
split /foo/ # split
join $a, @b # join
@x = (1,2) # list
SKIP @x[1,2] # lslice
[1,2] # anonlist
{ a => 1 } # anonhash
splice @x, 1, 2, 3 # splice
push @x, $x # push
pop @x # pop
shift @x # shift
unshift @x # unshift
sort @x # sort
reverse @x # reverse
grep { $_ eq 'foo' } @x # grepstart
SKIP grep { $_ eq 'foo' } @x # grepwhile
map $_ + 1, @foo # mapstart
SKIP (set by optimizer) # mapwhile
SKIP # range
1..2 # flip
1..2 # flop
$x && $y # and
$x || $y # or
$x xor $y # xor
$x ? 1 : 0 # cond_expr
$x &&= $y # andassign
$x ||= $y # orassign
Foo->$x() # method
f() # entersub
sub f{} f() # leavesub
sub f:lvalue{return $x} f() # leavesublv
caller # caller
warn # warn
die # die
reset # reset
SKIP # lineseq
SKIP # nextstate
SKIP (needs debugger) # dbstate
while(0){} # unstack
SKIP # enter
SKIP # leave
SKIP # scope
SKIP # enteriter
SKIP # iter
SKIP # enterloop
SKIP # leaveloop
return # return
last # last
next # next
redo THIS # redo
dump # dump
goto THERE # goto
exit 0 # exit
open FOO # open
close FOO # close
pipe FOO,BAR # pipe_op
fileno FOO # fileno
umask 0755, 'foo' # umask
binmode FOO # binmode
tie # tie
untie # untie
tied # tied
dbmopen # dbmopen
dbmclose # dbmclose
SKIP (set by optimizer) # sselect
select FOO # select
getc FOO # getc
read FOO # read
write # enterwrite
SKIP # leavewrite
printf # prtf
print # print
sysopen # sysopen
sysseek # sysseek
sysread # sysread
syswrite # syswrite
send # send
recv # recv
eof FOO # eof
tell # tell
seek FH, $pos, $whence # seek
truncate FOO, 42 # truncate
fcntl # fcntl
ioctl # ioctl
flock FOO, 1 # flock
socket # socket
socketpair # sockpair
bind # bind
connect # connect
listen # listen
accept # accept
shutdown # shutdown
getsockopt # gsockopt
setsockopt # ssockopt
getsockname # getsockname
getpeername # getpeername
lstat FOO # lstat
stat FOO # stat
-R # ftrread
-W # ftrwrite
-X # ftrexec
-r # fteread
-w # ftewrite
-x # fteexec
-e # ftis
SKIP -O # fteowned
SKIP -o # ftrowned
-z # ftzero
-s # ftsize
-M # ftmtime
-A # ftatime
-C # ftctime
-S # ftsock
-c # ftchr
-b # ftblk
-f # ftfile
-d # ftdir
-p # ftpipe
-l # ftlink
-u # ftsuid
-g # ftsgid
-k # ftsvtx
-t # fttty
-T # fttext
-B # ftbinary
chdir '/' # chdir
chown # chown
chroot # chroot
unlink 'foo' # unlink
chmod 511, 'foo' # chmod
utime # utime
rename 'foo', 'bar' # rename
link 'foo', 'bar' # link
symlink 'foo', 'bar' # symlink
readlink 'foo' # readlink
mkdir 'foo' # mkdir
rmdir 'foo' # rmdir
opendir DIR # open_dir
readdir DIR # readdir
telldir DIR # telldir
seekdir DIR, $pos # seekdir
rewinddir DIR # rewinddir
closedir DIR # closedir
fork # fork
wait # wait
waitpid # waitpid
system # system
exec # exec
kill # kill
getppid # getppid
getpgrp # getpgrp
setpgrp # setpgrp
getpriority # getpriority
setpriority # setpriority
time # time
times # tms
localtime # localtime
gmtime # gmtime
alarm # alarm
sleep 1 # sleep
shmget # shmget
shmctl # shmctl
shmread # shmread
shmwrite # shmwrite
msgget # msgget
msgctl # msgctl
msgsnd # msgsnd
msgrcv # msgrcv
semget # semget
semctl # semctl
semop # semop
use strict # require
do 'file' # dofile
eval "1+1" # entereval
eval "1+1" # leaveeval
SKIP eval { 1+1 } # entertry
SKIP eval { 1+1 } # leavetry
gethostbyname 'foo' # ghbyname
gethostbyaddr 'foo' # ghbyaddr
gethostent # ghostent
getnetbyname 'foo' # gnbyname
getnetbyaddr 'foo' # gnbyaddr
getnetent # gnetent
getprotobyname 'foo' # gpbyname
getprotobynumber 42 # gpbynumber
getprotoent # gprotoent
getservbyname 'name', 'proto' # gsbyname
getservbyport 'a', 'b' # gsbyport
getservent # gservent
sethostent # shostent
setnetent # snetent
setprotoent # sprotoent
setservent # sservent
endhostent # ehostent
endnetent # enetent
endprotoent # eprotoent
endservent # eservent
getpwnam # gpwnam
getpwuid # gpwuid
getpwent # gpwent
setpwent # spwent
endpwent # epwent
getgrnam # ggrnam
getgrgid # ggrgid
getgrent # ggrent
setgrent # sgrent
endgrent # egrent
getlogin # getlogin
syscall # syscall
SKIP # lock
SKIP # threadsv
SKIP # setstate
$x->y() # method_named
$x // $y # dor
$x //= $y # dorassign
SKIP (no way) # custom

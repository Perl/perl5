#!/usr/bin/perl

while (<DATA>) {
    chop;
    $keyword{$_} = 1;
}

undef $/;
$* = 1;
while (<>) {
    $newname = $ARGV;
    $newname =~ s/\.pl$/.pm/ || next;
    $newname =~ s#(.*/)?(\w+)#$1\u$2#;
    if (-f $newname) {
	warn "Won't overwrite existing $newname\n";
	next;
    }
    $oldpack = $2;
    $newpack = "\u$2";
    @export = ();
    print "$oldpack => $newpack\n" if $verbose;

    s/\bstd(in|out|err)\b/\U$&/g;
    s/(sub\s+)(\w+)(\s*\{[ \t]*\n)\s*package\s+$oldpack\s*;[ \t]*\n+/${1}main'$2$3/ig;
    if (/sub\s+main'/) {
	@export = m/sub\s+main'(\w+)/g;
	s/(sub\s+)main'(\w+)/$1$2/g;
    }
    else {
	@export = m/sub\s+([A-Za-z]\w*)/g;
    }
    @export_ok = grep($keyword{$_}, @export);
    @export = grep(!$keyword{$_}, @export);
    @export{@export} = (1) x @export;
    s/(^\s*);#/$1#/g;
    s/(#.*)require ['"]$oldpack\.pl['"]/$1use $newpack/;
    s/(package\s*)($oldpack)\s*;[ \t]*\n+//ig;
    s/([\$\@%&*])'(\w+)/&xlate($1,"",$2)/eg;
    s/([\$\@%&*]?)(\w+)'(\w+)/&xlate($1,$2,$3)/eg;
    if (!/\$\[\s*\)?\s*=\s*[^0\s]/) {
	s/^\s*(local\s*\()?\s*\$\[\s*\)?\s*=\s*0\s*;[ \t]*\n//g;
	s/\$\[\s*\+\s*//g;
	s/\s*\+\s*\$\[//g;
	s/\$\[/0/g;
    }
    s/open\s+(\w+)/open($1)/g;
 
    if (s/\bdie\b/croak/g) {
	$carp = "use Carp;\n";
	s/croak "([^"]*)\\n"/croak "$1"/g;
    }
    else {
	$carp = "";
    }
    if (@export_ok) {
	$export_ok = "\@EXPORT_OK = qw(@export_ok);\n";
    }
    else {
	$export_ok = "";
    }

    open(PM, ">$newname") || warn "Can't create $newname: $!\n";
    print PM <<"END";
package $newpack;
require 5.000;
require Exporter;
$carp
\@ISA = qw(Exporter);
\@EXPORT = qw(@export);
$export_ok
$_
END
}

sub xlate {
    local($prefix, $pack, $ident) = @_;
    if ($prefix eq '' && $ident =~ /^(t|s|m|d|ing|ll|ed|ve|re)$/) {
	"${pack}'$ident";
    }
    elsif ($pack eq "" || $pack eq "main") {
	if ($export{$ident}) {
	    "$prefix$ident";
	}
	else {
	    "$prefix${pack}::$ident";
	}
    }
    elsif ($pack eq $oldpack) {
	"$prefix${newpack}::$ident";
    }
    else {
	"$prefix${pack}::$ident";
    }
}
__END__
AUTOLOAD
BEGIN
CORE
DESTROY
END
abs
accept
alarm
and
atan2
bind
binmode
bless
caller
chdir
chmod
chop
chown
chr
chroot
close
closedir
cmp
connect
continue
cos
crypt
dbmclose
dbmopen
defined
delete
die
do
dump
each
else
elsif
endgrent
endhostent
endnetent
endprotoent
endpwent
endservent
eof
eq
eval
exec
exit
exp
fcntl
fileno
flock
for
foreach
fork
format
formline
ge
getc
getgrent
getgrgid
getgrnam
gethostbyaddr
gethostbyname
gethostent
getlogin
getnetbyaddr
getnetbyname
getnetent
getpeername
getpgrp
getppid
getpriority
getprotobyname
getprotobynumber
getprotoent
getpwent
getpwnam
getpwuid
getservbyname
getservbyport
getservent
getsockname
getsockopt
glob
gmtime
goto
grep
gt
hex
if
index
int
ioctl
join
keys
kill
last
lc
lcfirst
le
length
link
listen
local
localtime
log
lstat
lt
m
mkdir
msgctl
msgget
msgrcv
msgsnd
my
ne
next
no
not
oct
open
opendir
or
ord
pack
package
pipe
pop
print
printf
push
q
qq
quotemeta
qw
qx
rand
read
readdir
readline
readlink
readpipe
recv
redo
ref
rename
require
reset
return
reverse
rewinddir
rindex
rmdir
s
scalar
seek
seekdir
select
semctl
semget
semop
send
setgrent
sethostent
setnetent
setpgrp
setpriority
setprotoent
setpwent
setservent
setsockopt
shift
shmctl
shmget
shmread
shmwrite
shutdown
sin
sleep
socket
socketpair
sort
splice
split
sprintf
sqrt
srand
stat
study
sub
substr
symlink
syscall
sysread
system
syswrite
tell
telldir
tie
time
times
tr
truncate
uc
ucfirst
umask
undef
unless
unlink
unpack
unshift
untie
until
use
utime
values
vec
wait
waitpid
wantarray
warn
while
write
x
xor
y

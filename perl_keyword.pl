#!./perl -w

# How to generate the logic of the lookup table Perl_keyword() in toke.c

use strict;
package Toke;
use vars qw(@ISA %types);
require ExtUtils::Constant::Base;
@ISA = 'ExtUtils::Constant::Base';

%types = (pos => "KEY_", neg => "-KEY_");

# We're allowing scalar references to produce evil customisation.
sub valid_type {
  defined $types{$_[1]} or ref $_[1];
}


# This might actually be a return statement
sub assignment_clause_for_type {
  my ($self, $args, $value) = @_;
  my ($type, $item) = @{$args}{qw(type item)};
  my $comment = '';
  $comment = " /* Weight $item->{weight} */" if defined $item->{weight};
  return "return $types{$type}$value;$comment" if $types{$type};
  "$$type$value;$comment";
}

sub return_statement_for_notfound {
  "return 0;"
}

# Ditch the default "const"
sub name_param_definition {
  "char *" . $_[0]->name_param;
}

sub C_constant_return_type {
  "I32";
}


sub C_constant_prefix_param {
  "aTHX_ ";
}

sub C_constant_prefix_param_defintion {
  "pTHX_ ";
}

sub namelen_param_definition {
  'I32 ' . $_[0] -> namelen_param;
}

package main;

my @pos = qw(__DATA__ __END__ AUTOLOAD BEGIN CHECK DESTROY do delete defined
	     END else eval elsif exists for format foreach grep goto glob INIT
	     if last local m my map next no our pos print printf package
	     prototype q qr qq qw qx redo return require s scalar sort split
	     study sub tr tie tied use undef until untie unless while y);

my @neg = qw(__FILE__ __LINE__ __PACKAGE__ and abs alarm atan2 accept bless
	     bind binmode CORE cmp chr cos chop close chdir chomp chmod chown
	     crypt chroot caller connect closedir continue die dump dbmopen
	     dbmclose eq eof err exp exit exec each endgrent endpwent
	     endnetent endhostent endservent endprotoent fork fcntl flock
	     fileno formline getppid getpgrp getpwent getpwnam getpwuid
	     getpeername getprotoent getpriority getprotobyname
	     getprotobynumber gethostbyname gethostbyaddr gethostent
	     getnetbyname getnetbyaddr getnetent getservbyname getservbyport
	     getservent getsockname getsockopt getgrent getgrnam getgrgid
	     getlogin getc gt ge gmtime hex int index ioctl join keys kill lt
	     le lc log link lock lstat length listen lcfirst localtime mkdir
	     msgctl msgget msgrcv msgsnd ne not or ord oct open opendir pop
	     push pack pipe quotemeta ref read rand recv rmdir reset rename
	     rindex reverse readdir readlink readline readpipe rewinddir seek
	     send semop select semctl semget setpgrp seekdir setpwent setgrent
	     setnetent setsockopt sethostent setservent setpriority
	     setprotoent shift shmctl shmget shmread shmwrite shutdown sin
	     sleep socket socketpair sprintf splice sqrt srand stat substr
	     system symlink syscall sysopen sysread sysseek syswrite tell time
	     times telldir truncate uc utime umask unpack unlink unshift
	     ucfirst values vec warn wait write waitpid wantarray x xor);

my %frequencies = (map {/(.*):\t(.*)/} <DATA>);

my @names;
push @names, map {{name=>$_, type=>"pos", weight=>$frequencies{$_}}} @pos;
push @names, map {{name=>$_, type=>"neg", weight=>$frequencies{$_}}} @neg;
push @names, {name=>'elseif', type=>\"", value=><<'EOC'};
/* This is somewhat hacky.  */
if(ckWARN_d(WARN_SYNTAX))
  Perl_warner(aTHX_ packWARN(WARN_SYNTAX), "elseif should be elsif");
break;
EOC

print Toke->C_constant ({subname=>'Perl_keyword', breakout=>~0}, @names);

__DATA__
my:	3785925
if:	2482605
sub:	2053554
return:	1401629
unless:	913955
shift:	904125
eq:	797065
defined:	694277
use:	686081
else:	527806
qw:	415641
or:	405163
s:	403691
require:	375220
ref:	347102
elsif:	322365
undef:	311156
and:	284867
foreach:	281720
local:	262973
push:	256975
package:	245661
print:	220904
our:	194417
die:	192203
length:	163975
next:	153355
m:	148776
caller:	148457
exists:	145939
eval:	136977
keys:	131427
join:	130820
substr:	121344
while:	120305
for:	118158
map:	115207
ne:	112906
__END__:	112636
vec:	110566
goto:	109258
do:	96004
last:	95078
split:	93678
warn:	91372
grep:	75912
delete:	74966
sprintf:	72704
q:	69076
bless:	62111
no:	61989
not:	55868
qq:	55149
index:	51465
CORE:	47391
pop:	46933
close:	44077
scalar:	43953
wantarray:	43024
open:	39060
x:	38549
lc:	38487
__PACKAGE__:	36767
stat:	36702
unshift:	36504
sort:	36394
chr:	35654
time:	32168
qr:	28519
splice:	25143
BEGIN:	24125
tr:	22665
chomp:	22337
ord:	22221
chdir:	20317
unlink:	18616
int:	18549
chmod:	18455
each:	18414
uc:	16961
pack:	14491
lstat:	13859
binmode:	12301
select:	12209
closedir:	11986
readdir:	11716
reverse:	10571
chop:	10172
tie:	10131
values:	10110
tied:	9749
read:	9434
opendir:	9007
fileno:	8591
exit:	8262
localtime:	7993
unpack:	7849
abs:	7767
printf:	6874
cmp:	6808
ge:	5666
pos:	5503
redo:	5219
rindex:	5005
rename:	4918
syswrite:	4437
system:	4326
lock:	4210
oct:	4195
le:	4052
gmtime:	4040
utime:	3849
sysread:	3729
hex:	3629
END:	3565
quotemeta:	3120
mkdir:	2951
continue:	2925
AUTOLOAD:	2713
tell:	2578
write:	2525
rmdir:	2493
seek:	2174
glob:	2172
study:	1933
rand:	1824
format:	1735
umask:	1658
eof:	1618
prototype:	1602
readlink:	1537
truncate:	1351
fcntl:	1257
sysopen:	1230
ucfirst:	1012
getc:	981
gethostbyname:	970
ioctl:	967
formline:	959
gt:	897
__FILE__:	888
until:	818
sqrt:	766
getprotobyname:	755
sysseek:	721
getpeername:	713
getpwuid:	681
xor:	619
y:	567
syscall:	560
CHECK:	538
connect:	526
err:	522
sleep:	519
sin:	499
send:	496
getpwnam:	483
cos:	447
exec:	429
link:	425
exp:	423
untie:	420
INIT:	418
waitpid:	414
__DATA__:	395
symlink:	386
kill:	382
setsockopt:	356
atan2:	350
pipe:	344
lt:	335
fork:	327
times:	310
getservbyname:	299
telldir:	294
bind:	290
dump:	274
flock:	260
recv:	250
getsockopt:	243
getsockname:	235
accept:	233
getprotobynumber:	232
rewinddir:	218
__LINE__:	209
qx:	177
lcfirst:	165
getlogin:	158
reset:	127
gethostbyaddr:	68
getgrgid:	67
srand:	41
chown:	34
seekdir:	20
readline:	19
semctl:	17
getpwent:	12
getgrnam:	11
getppid:	10
crypt:	8
DESTROY:	7
getpriority:	5
getservent:	4
gethostent:	3
setpriority:	2
setnetent:	1

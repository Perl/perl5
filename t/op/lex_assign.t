#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}

umask 0;
$xref = \ "";
@a = (1..5);
%h = (1..6);
$aref = \@a;
$href = \%h;
open OP, qq{$^X -le "print 'aaa Ok ok' for 1..100"|};
$chopit = 'aaaaaa';
@chopar = (113 .. 119);
$posstr = '123456';
$cstr = 'aBcD.eF';
pos $posstr = 3;
$nn = $n = 2;
sub subb {"in s"}

@INPUT = <DATA>;
print "1..", (scalar @INPUT), "\n";
$ord = 0;

sub wrn {"@_"}

for (@INPUT) {
  $ord++;
  ($op, undef, $comment) = /^([^\#]+)(\#\s+(.*))?/;
  $comment = $op unless defined $comment;
  $op = "$op==$op" unless $op =~ /==/;
  ($op, $expectop) = $op =~ /(.*)==(.*)/;
  
  $skip = ($op =~ /^'\?\?\?'/ or $comment =~ /skip\(.*\Q$^O\E.*\)/i)
	  ? "skip" : "not";
  $integer = ($comment =~ /^i_/) ? "use integer" : '' ;
  (print "#skipping $comment:\nok $ord\n"), next if $skip eq 'skip';
  
  eval <<EOE;
  local \$SIG{__WARN__} = \\&wrn;
  my \$a = 'fake';
  $integer;
  \$a = $op;
  \$b = $expectop;
  if (\$a ne \$b) {
    print "# \$comment: got `\$a', expected `\$b'\n";
    print "\$skip " if \$a ne \$b or \$skip eq 'skip';
  }
  print "ok \$ord\\n";
EOE
  if ($@) {
    if ($@ =~ /is unimplemented/) {
      print "# skipping $comment: unimplemented:\nok $ord\n";
    } else {
      warn $@;
      print "not ok $ord\n";
    }
  }
}
__END__
ref $xref			# ref
ref $cstr			# ref nonref
`ls`				# backtick skip(MSWin32)
`$undefed`			# backtick undef skip(MSWin32)
<*>				# glob
<OP>				# readline
'faked'				# rcatline
(@z = (1 .. 3))			# aassign
chop $chopit			# chop
(chop (@x=@chopar))		# schop
chomp $chopit			# chomp
(chop (@x=@chopar))		# schomp
pos $posstr			# pos
pos $chopit			# pos returns undef
$nn++==2			# postinc
$nn++==3			# i_postinc
$nn--==4			# postdec
$nn--==3			# i_postdec
$n ** $n			# pow
$n * $n				# multiply
$n * $n				# i_multiply
$n / $n				# divide
$n / $n				# i_divide
$n % $n				# modulo
$n % $n				# i_modulo
$n x $n				# repeat
$n + $n				# add
$n + $n				# i_add
$n - $n				# subtract
$n - $n				# i_subtract
$n . $n				# concat
$n . $a=='2fake'		# concat with self
"3$a"=='3fake'			# concat with self in stringify
"$n"				# stringify
$n << $n			# left_shift
$n >> $n			# right_shift
$n <=> $n			# ncmp
$n <=> $n			# i_ncmp
$n cmp $n			# scmp
$n & $n				# bit_and
$n ^ $n				# bit_xor
$n | $n				# bit_or
-$n				# negate
-$n				# i_negate
~$n				# complement
atan2 $n,$n			# atan2
sin $n				# sin
cos $n				# cos
'???'				# rand
exp $n				# exp
log $n				# log
sqrt $n				# sqrt
int $n				# int
hex $n				# hex
oct $n				# oct
abs $n				# abs
length $posstr			# length
substr $posstr, 2, 2		# substr
vec("abc",2,8)			# vec
index $posstr, 2		# index
rindex $posstr, 2		# rindex
sprintf "%i%i", $n, $n		# sprintf
ord $n				# ord
chr $n				# chr
crypt $n, $n			# crypt
ucfirst ($cstr . "a")		# ucfirst padtmp
ucfirst $cstr			# ucfirst
lcfirst $cstr			# lcfirst
uc $cstr			# uc
lc $cstr			# lc
quotemeta $cstr			# quotemeta
@$aref				# rv2av
@$undefed			# rv2av undef
each %h==1			# each
values %h			# values
keys %h				# keys
%$href				# rv2hv
pack "C2", $n,$n		# pack
split /a/, "abad"		# split
join "a"; @a			# join
push @a,3==6			# push
unshift @aaa			# unshift
reverse	@a			# reverse
reverse	$cstr			# reverse - scal
grep $_, 1,0,2,0,3		# grepwhile
map "x$_", 1,0,2,0,3		# mapwhile
subb()				# entersub
caller				# caller
warn "ignore this\n"		# warn
'faked'				# die
open BLAH, "<non-existent"	# open
fileno STDERR			# fileno
umask 0				# umask
select STDOUT			# sselect
select "","","",0		# select
getc OP				# getc
'???'				# read
'???'				# sysread
'???'				# syswrite
'???'				# send
'???'				# recv
'???'				# tell
'???'				# fcntl
'???'				# ioctl
'???'				# flock
'???'				# accept
'???'				# shutdown
'???'				# ftsize
'???'				# ftmtime
'???'				# ftatime
'???'				# ftctime
chdir 'non-existent'		# chdir
'???'				# chown
'???'				# chroot
unlink 'non-existent'		# unlink
chmod 'non-existent'		# chmod
utime 'non-existent'		# utime
rename 'non-existent', 'non-existent1'	# rename
link 'non-existent', 'non-existent1' # link
'???'				# symlink
readlink 'non-existent', 'non-existent1' # readlink
'???'				# mkdir
'???'				# rmdir
'???'				# telldir
'???'				# fork
'???'				# wait
'???'				# waitpid
system "$^X -e 0"		# system
'???'				# exec
'???'				# kill
getppid				# getppid
getpgrp				# getpgrp
'???'				# setpgrp
getpriority $$, $$		# getpriority
'???'				# setpriority
time				# time
localtime			# localtime
gmtime				# gmtime
sleep 1				# sleep
'???'				# alarm
'???'				# shmget
'???'				# shmctl
'???'				# shmread
'???'				# shmwrite
'???'				# msgget
'???'				# msgctl
'???'				# msgsnd
'???'				# msgrcv
'???'				# semget
'???'				# semctl
'???'				# semop
'???'				# getlogin
'???'				# syscall

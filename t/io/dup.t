#!./perl

# $RCSfile: dup.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:27 $

print "1..8\n";

print "ok 1\n";

open(dupout,">&STDOUT");
open(duperr,">&STDERR");

open(STDOUT,">Io.dup") || die "Can't open stdout";
open(STDERR,">&STDOUT") || die "Can't open stderr";

select(STDERR); $| = 1;
select(STDOUT); $| = 1;

print STDOUT "ok 2\n";
print STDERR "ok 3\n";
    print `echo ok 4`;
    print `echo ok 5 1>&2`; # does this work?
    system 'echo ok 6';
    system 'echo ok 7 1>&2';

close(STDOUT);
close(STDERR);

open(STDOUT,">&dupout");
open(STDERR,">&duperr");

if (($^O eq 'MSWin32') || ($^O eq 'NetWare')) { print `type Io.dup` }
else                  { system 'cat Io.dup' }
unlink 'Io.dup';

print STDOUT "ok 8\n";


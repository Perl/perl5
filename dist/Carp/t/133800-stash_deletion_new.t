#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;

use Carp;

printf "Test file %s, Perl $^V, Carp $Carp::VERSION $INC{'Carp.pm'}\n", __FILE__;

{
## base test of die()
my $Die_sub = eval <<'EVAL_EOF';
package Die_Package;
sub {
#line 1 Die_File
    die "Die_Msg";
}
EVAL_EOF

ok(!$@); # 1
eval { $Die_sub->() };
like($@, qr/^Die_Msg at Die_File line 1/); # 2
{
    no strict 'refs';
    delete ${'::'}{'Die_Package::'};
}
eval { $Die_sub->() };
like($@, qr/^Die_Msg at Die_File line 1/); # 3
}

######################################

{
## test of confess()
my $Confess_sub = eval <<'EVAL_EOF';
package Confess_Package;
sub {
#line 2 Confess_File
Carp::confess("Confess_Msg");
}
EVAL_EOF

ok(!$@); # 4
eval { $Confess_sub->() };
like($@, qr/^Confess_Msg at Confess_File line 2/); # 5
{
    no strict 'refs';
    delete ${'::'}{'Confess_Package::'};
}
eval { $Confess_sub->() };
like($@, qr/^Confess_Msg at Confess_File line 2/); # 6
}

######################################

{
## test of croak()
my $Croak_sub = eval <<'EVAL_EOF';
package Croak_Package;
sub {
#line 3 Croak_File
Carp::croak("Croak_Msg");
}
EVAL_EOF

ok(!$@, "Croak_sub compile"); # 7
eval { $Croak_sub->() };
like($@, qr/^Croak_Msg at Croak_File line 3/, "Croak_sub execute"); # 8
{
    no strict 'refs';
    delete ${'::'}{'Croak_Package::'};
}
eval { $Croak_sub->() };
like($@, qr/^Croak_Msg at Croak_File line 3/, "Croak_sub execute after package delete"); # 9
}

######################################

{
## test of helper package with croak()
my $Croak2_sub = eval <<'EVAL_EOF';
package CroakHelper_Package;
sub helper {
    Carp::croak("CroakHelper_Msg");
}
package Croak2_Package;
sub {
#line 4 Croak2_File
    CroakHelper_Package::helper();
}
EVAL_EOF

ok(!$@); # 10
eval { $Croak2_sub->() };
like($@, qr/^CroakHelper_Msg at Croak2_File line 4/); # 11
{
    no strict 'refs';
    delete ${'::'}{'Croak2_Package::'};
}
eval { $Croak2_sub->() };
like($@, qr/^CroakHelper_Msg at Croak2_File line 4/); # 12
{
    no strict 'refs';
    delete ${'::'}{'CroakHelper_Package::'};
}
eval { $Croak2_sub->() };
like($@, qr/^CroakHelper_Msg at Croak2_File line 4/); # 13
}

######################################

{
## test of helper package with confess()
# the amount of information available and how it is displayed varies quite
# a bit depending on the version of perl (specifically, what caller returns
# in that version), so there is a bit of fiddling around required to handle
# that
my $unknown_pat = qr/__ANON__::/;
$unknown_pat = qr/$unknown_pat|\(unknown\)/
    if $] < 5.014;

my $Sub_sub = eval <<'EVAL_EOF';
package SubHelper_Package;
sub helper {
    Carp::confess("_Msg");
}
package Sub_Package;
sub {
#line 5 Sub_File
    SubHelper_Package::helper();
}
EVAL_EOF

ok(!$@); # 14
eval { $Sub_sub->() };
unlike($@, qr/$unknown_pat/); # 15
{
    no strict 'refs';
    delete ${'::'}{'Sub_Package::'};
}
eval { $Sub_sub->() };
like($@, qr/$unknown_pat|Sub_Package::/); # 16
unlike($@, qr/$unknown_pat.*$unknown_pat/s); # 17
{
    no strict 'refs';
    delete ${'::'}{'SubHelper_Package::'};
}
eval { $Sub_sub->() };
like($@, qr/(?:$unknown_pat|SubHelper_Package::).*(?:$unknown_pat|Sub_Package::)/s); # 18
}


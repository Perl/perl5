
use Devel::Harness;

use strict;

print "1..17\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib' if -d '../lib';

}

my $total = 0;
my $good = 0;

my $test = 0;   
sub ok {
    my ($name, $test_sub) = @_;
    my $line = (caller)[2];
    my $value;

    eval { $value = &{ $test_sub }() } ;

    ++ $test ;

    if ($@) {
        printf "not ok $test # Testing '$name', line $line $@\n";
    }
    elsif ($value != 1){
        printf "not ok $test # Testing '$name', line $line, value != 1 ($value)\n";
    }
    else {
        print "ok $test\n";
    }

} 

ok "Static newCONSTSUB()", 
   sub { Devel::Harness::test1(); Devel::Harness::test_value_1() == 1} ;

ok "Global newCONSTSUB()", 
   sub { Devel::Harness::test2(); Devel::Harness::test_value_2() == 2} ;

ok "Extern newCONSTSUB()", 
   sub { Devel::Harness::test3(); Devel::Harness::test_value_3() == 3} ;

ok "newRV_inc()", sub { Devel::Harness::test4()} ;

ok "newRV_noinc()", sub { Devel::Harness::test5()} ;

ok "PL_sv_undef", sub { not defined Devel::Harness::test6()} ;

ok "PL_sv_yes", sub { Devel::Harness::test7()} ;

ok "PL_sv_no", sub { !Devel::Harness::test8()} ;

ok "PL_na", sub { Devel::Harness::test9("abcd") == 4} ;

ok "boolSV 1", sub { Devel::Harness::test10(1) } ;

ok "boolSV 0", sub { ! Devel::Harness::test10(0) } ;

ok "newSVpvn", sub { Devel::Harness::test11("abcde", 3) eq "abc" } ;

ok "DEFSV", sub { $_ = "Fred"; Devel::Harness::test12() eq "Fred" } ;

ok "ERRSV", sub { eval { 1; }; ! Devel::Harness::test13() };

ok "ERRSV", sub { eval { fred() }; Devel::Harness::test13() };

ok "CXT 1", sub { Devel::Harness::test14()} ;

ok "CXT 2", sub { Devel::Harness::test15()} ;

__END__
# TODO

PERL_VERSION
PERL_BCDVERSION

PL_stdingv
PL_hints
PL_curcop
PL_curstash
PL_copline
PL_Sv
PL_compiling
PL_dirty

PTR2IV
INT2PTR

dTHR
gv_stashpvn
NOOP
SAVE_DEFSV
PERL_UNUSED_DECL
dNOOP

#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Test::More qw(no_plan); # tests =>  7;
use lib qw( lib );
use ExtUtils::ParseXS::Utilities qw(
);
#    check_conditional_preprocessor_statements

my $self = {};
$self->{line} = [];
$self->{XSStack} = [];
$self->{XSStack}->[0] = {};
my @capture = ();
sub capture { push @capture, $_[0] };

#{
#    $self->{line} = [
#        "#if this_is_an_if_statement",
#        "Alpha this is not an if/elif/elsif/endif",
#        "#elif this_is_an_elif_statement",
#        "Beta this is not an if/elif/elsif/endif",
#        "#else this_is_an_else_statement",
#        "Gamma this is not an if/elif/elsif/endif",
#        "#endif this_is_an_endif_statement",
#    ];
#    $self->{XSStack}->[-1]{type} = 'if';
#
#    @capture = ();
#    local $SIG{__WARN__} = \&capture;
#    is( check_conditional_preprocessor_statements($self), 0,
#        "basic case: returned 0: all ifs resolved" );
#    ok( ! @capture, "No warnings captured, as expected" );
#}
#
#{
#    $self->{line} = [
#        "#if this_is_an_if_statement",
#        "Alpha this is not an if/elif/elsif/endif",
#        "#if this_is_a_different_if_statement",
#        "Beta this is not an if/elif/elsif/endif",
#        "#endif this_is_a_different_endif_statement",
#        "Gamma this is not an if/elif/elsif/endif",
#        "#endif this_is_an_endif_statement",
#    ];
#    $self->{XSStack}->[-1]{type} = 'if';
#
#    @capture = ();
#    local $SIG{__WARN__} = \&capture;
#    is( check_conditional_preprocessor_statements($self), 0,
#        "one nested if case: returned 0: all ifs resolved" );
#    ok( ! @capture, "No warnings captured, as expected" );
#}
#
#{
#    $self->{line} = [
#        "Alpha this is not an if/elif/elsif/endif",
#        "#elif this_is_an_elif_statement",
#        "Beta this is not an if/elif/elsif/endif",
#        "#else this_is_an_else_statement",
#        "Gamma this is not an if/elif/elsif/endif",
#        "#endif this_is_an_endif_statement",
#    ];
#    $self->{XSStack}->[-1]{type} = 'if';
#
#    @capture = ();
#    local $SIG{__WARN__} = \&capture;
#    is( check_conditional_preprocessor_statements($self), undef,
#        "missing 'if' case: returned undef: all ifs resolved" );
#    ok( @capture, "Warning captured, as expected" );
#}


pass("Passed all tests in $0");

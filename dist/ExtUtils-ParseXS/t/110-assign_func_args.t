#!/usr/bin/perl
#
# test the C_func_signature() utility method
# (formerly called assign_func_args()).

use strict;
use warnings;
use Test::More qw(no_plan); # tests =>  7;
use ExtUtils::ParseXS::Utilities qw(
    C_func_signature
);

#sub C_func_signature {
#  my ($self, $argsref, $class) = @_;
#  return join(", ", @func_args);

my ($self, @args, $class);
my ($func_args, $expected);

# fake up a Node::Sig object
# XXX really we should actually bless an object
sub set_sig {
    my ($self, $var, $inout) = @_;
    $self->{xsub_sig}{names}{$var}{in_out} = $inout;
}

$self ={};

@args = qw( alpha beta gamma );
set_sig($self, 'alpha', 'OUT');
$expected = q|&alpha, beta, gamma|;
$func_args = C_func_signature($self, \@args, $class);
is( $func_args, $expected,
    "Got expected func_args: in_out true; class undefined" );

@args = ( 'My::Class', qw( beta gamma ) );
set_sig($self, 'beta', 'OUT');
$class = 'My::Class';
$expected = q|&beta, gamma|;
$func_args = C_func_signature($self, \@args, $class);
is( $func_args, $expected,
    "Got expected func_args: in_out true; class defined" );

@args = ( 'My::Class', qw( beta gamma ) );
set_sig($self, 'beta', '');
$class = 'My::Class';
$expected = q|beta, gamma|;
$func_args = C_func_signature($self, \@args, $class);
is( $func_args, $expected,
    "Got expected func_args: in_out false; class defined" );

@args = qw( alpha beta gamma );
set_sig($self, 'alpha', '');
$class = undef;
$expected = q|alpha, beta, gamma|;
$func_args = C_func_signature($self, \@args, $class);
is( $func_args, $expected,
    "Got expected func_args: in_out false; class undefined" );

pass("Passed all tests in $0");

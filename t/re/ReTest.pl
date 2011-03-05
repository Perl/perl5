#!./perl
#
# This is the test subs used for regex testing. 
# This used to be part of re/pat.t
use warnings;
use strict;
use 5.010;
use base qw/Exporter/;
use Carp;
use vars qw(
    $IS_ASCII
    $IS_EBCDIC
    $ordA
);

$| = 1;

our $ordA = ord ('A');  # This defines ASCII/UTF-8 vs EBCDIC/UTF-EBCDIC
# This defined the platform.
our $IS_ASCII  = $ordA ==  65;
our $IS_EBCDIC = $ordA == 193;

require './test.pl';

sub eval_ok ($;$) {
    my ($code, $name) = @_;
    local $@;
    if (ref $code) {
        ok(eval {&$code} && !$@, $name);
    }
    else {
        ok(eval  ($code) && !$@, $name);
    }
}

sub must_warn {
    my ($code, $pattern, $name) = @_;
    Carp::confess("Bad pattern") unless $pattern;
    my $w;
    local $SIG {__WARN__} = sub {$w .= join "" => @_};
    use warnings 'all';
    ref $code ? &$code : eval $code;
    like($w, qr/$pattern/, "Got warning /$pattern/");
}

sub may_not_warn {
    my ($code, $name) = @_;
    my $w;
    local $SIG {__WARN__} = sub {$w .= join "" => @_};
    use warnings 'all';
    ref $code ? &$code : eval $code;
    is($w, undef, $name) or diag("Got warning '$w'");
}

1;

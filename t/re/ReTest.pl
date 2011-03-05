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

1;

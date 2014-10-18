#!perl

use Test::More tests => 4;
use XS::APItest;
use utf8;

$_ = "καλοκαίρι";
sv_catpvn($_, " \xe9t\xe9"); # uses SV_CATBYTES
is $_, "καλοκαίρι été", 'sv_catpvn_flags(utfsv, ... SV_CATBYTES)';
$_ = "\xe9t\xe9";
sv_catpvn($_, " καλοκαίρι"); # uses SV_CATUTF8
is $_, "été καλοκαίρι", 'sv_catpvn_flags(bytesv, ... SV_CATUTF8)';
$_ = "καλοκαίρι";
sv_catpvn($_, " été"); # uses SV_CATUTF8
is $_, "καλοκαίρι été", 'sv_catpvn_flags(utfsv, ... SV_CATUTF8)';
$_ = "\xe9t\xe9";
sv_catpvn($_, " \xe9t\xe9"); # uses SV_CATBYTES
is $_, "été été", 'sv_catpvn_flags(bytesv, ... SV_CATBYTES)';

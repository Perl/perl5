#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';    # for which_perl() etc
    set_up_inc('../lib');
}

use strict;
use warnings;

use feature 'trim';
no warnings 'experimental::trim';

# Vanilla trim tests
{
    is(trim("    Hello world!   ")      , "Hello world!"  , 'Trim spaces');
    is(trim("\tHello world!\t")         , "Hello world!"  , 'Trim tabs');
    is(trim("\n\n\nHello\nworld!\n")    , "Hello\nworld!" , 'Trim \n');
    is(trim("\t\n\n\nHello world!\n \t"), "Hello world!"  , 'Trim all three');
    is(trim("Perl")                     , "Perl"          , 'Trim nothing');
    is(trim('')                         , ""              , 'Trim empty string');
}

{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= join "", @_; };

    is(trim(undef), ""                                               , 'Trim undef');
    like($warn    , qr/^Use of uninitialized value in string trim at/, 'Trim undef triggers warning');
}

# Fancier trim tests against a regexp and unicode
{
    is(trim("    Hello world!    "), trim_regexp_compare("    Hello world!    "), 'Trim compared to regexp');
    is(trim("\n\nHello world!    "), trim_regexp_compare("\n\nHello world!    "), 'Trim compared to regexp');
    is(trim("    Hello world!\t\t"), trim_regexp_compare("    Hello world!\t\t"), 'Trim compared to regexp');
    is(trim("   \N{U+2603}       "), "\N{U+2603}"                               , 'Trim with unicode content');
    is(trim("\N{U+2029}foobar    "), "foobar"                                   , 'Trim with unicode whitespace');
    is(trim("\xa0foobar          "), "foobar"                                   , 'Trim with latin1 whitespace');
}

# Tests against special variable types and scopes
{
    my  $str1 = "   Hello world!\t";
    is(trim($str1), "Hello world!", "trim on a my \$var");
    our $str2 = "\t\nHello world!\t  ";
    is(trim($str2), "Hello world!", "trim on an our \$var");
}

# Test on a magical fetching variable
{
    my $str3 = "   Hello world!\t";
    $str3 =~ m/(.+Hello)/;
    is(trim($1), "Hello", "trim on a magical variable");
}

# Inplace edit
{
    my $str4 = "\t\tHello world!\n\n";
    $str4 = trim($str4);
    is($str4, "Hello world!", "Trim on an inplace variable");
}

################################################################################

sub trim_regexp_compare {
    my $s = shift();

    $s =~ s/\A\s+|\s+\z//ug;

    return $s;
}

# vim: tabstop=4 shiftwidth=4 expandtab autoindent softtabstop=4

#!./perl

use strict;
use warnings;
no  warnings 'syntax';

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

sub is;
sub plan;

require './test.pl';
plan tests => 3;

{
    # Bug #77084 points out a corruption problem when scalar //g is used
    # on overloaded objects.

    my $TAG = "foo:bar";
    use overload '""' => sub {$TAG};

    my $o = bless [];
    my ($one) = $o =~ /(.*)/g;
    is $one, $TAG, "list context //g against overloaded object";

    local our $TODO = "Bug #77084";

    my $r = $o =~ /(.*)/g;
    is $1, $TAG, "scalar context //g against overloaded object";

    $o =~ /(.*)/g;
    is $1, $TAG, "void context //g against overloaded object";
}


__END__

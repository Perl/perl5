#!./perl

BEGIN {
    unshift @INC, 't';
    require Config;
    if (($Config::Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
}

$|  = 1;
use warnings;
use strict;
use utf8;
use B;
BEGIN  {
    eval { require threads; threads->import; }
}
use Test::More;

sub f {
    # I like pi
    π:1;
}

{
    # github 24040
    my $f = B::svref_2object(\&f);
    my $op = $f->START;
    while ($op && !($op->name =~ /^(db|next)state$/ && $op->label)) {
        $op = $op->next;
    }
    $op or die "Not found";
    my $label = $op->label;
    is($label, "π", "UTF8 label correctly UTF8");
}

sub f2 {
    goto π;
    π:1;
}

{
    # github 24040 - goto
    my $f2 = B::svref_2object(\&f2);
    my $op = $f2->START;
    while ($op && $op->name ne 'goto') {
        $op = $op->next;
    }
    $op or die "goto Not found";
    my $label = $op->pv;
    is($label, "π", "goto UTF8 label correctly UTF8");
}

done_testing();

#!./perl
#
# opcount.t
#
# Test whether various constructs have the right numbers of particular op
# types. This is chiefly to test that various optimisations are not
# inadvertently removed.
#
# For example the array access in sub { $a[0] } should get optimised from
# aelem into aelemfast. So we want to test that there are 1 aelemfast, 0
# aelem and 1 ex-aelem ops in the optree for that sub.

BEGIN {
    chdir 't';
    require './test.pl';
    skip_all_if_miniperl("No B under miniperl");
    @INC = '../lib';
}

use warnings;
use strict;

plan 2261;

use B ();


{
    my %counts;

    # for a given op, increment $count{opname}. Treat null ops
    # as "ex-foo" where possible

    sub B::OP::test_opcount_callback {
        my ($op) = @_;
        my $name = $op->name;
        if ($name eq 'null') {
            my $targ = $op->targ;
            if ($targ) {
                $name = "ex-" . substr(B::ppname($targ), 3);
            }
        }
        $counts{$name}++;
    }

    # Given a code ref and a hash ref of expected op counts, check that
    # for each opname => count pair, whether that op appears that many
    # times in the op tree for that sub. If $debug is 1, display all the
    # op counts for the sub.

    sub test_opcount {
        my ($debug, $desc, $coderef, $expected_counts) = @_;

        %counts = ();
        B::walkoptree(B::svref_2object($coderef)->ROOT,
                        'test_opcount_callback');

        if ($debug) {
            note(sprintf "%3d %s", $counts{$_}, $_) for sort keys %counts;
        }

        my @exp;
        for (sort keys %$expected_counts) {
            my ($c, $e) = ($counts{$_}//0, $expected_counts->{$_});
            if ($c != $e) {
                push @exp, "expected $e, got $c: $_";
            }
        }
        ok(!@exp, $desc);
        if (@exp) {
            diag($_) for @exp;
        }
    }    
}

# aelem => aelemfast: a basic test that this test file works

test_opcount(0, "basic aelemfast",
                sub { our @a; $a[0] = 1 },
                {
                    aelem      => 0,
                    aelemfast  => 1,
                    'ex-aelem' => 1,
                }
            );

# Porting/bench.pl tries to create an empty and active loop, with the
# ops executed being exactly the same apart from the additional ops
# in the active loop. Check that this remains true.

{
    test_opcount(0, "bench.pl empty loop",
                sub { for my $x (1..$ARGV[0]) { 1; } },
                {
                     aelemfast => 1,
                     and       => 1,
                     const     => 1,
                     enteriter => 1,
                     iter      => 1,
                     leaveloop => 1,
                     leavesub  => 1,
                     lineseq   => 2,
                     nextstate => 2,
                     null      => 1,
                     pushmark  => 1,
                     unstack   => 1,
                }
            );

    no warnings 'void';
    test_opcount(0, "bench.pl active loop",
                sub { for my $x (1..$ARGV[0]) { $x; } },
                {
                     aelemfast => 1,
                     and       => 1,
                     const     => 1,
                     enteriter => 1,
                     iter      => 1,
                     leaveloop => 1,
                     leavesub  => 1,
                     lineseq   => 2,
                     nextstate => 2,
                     null      => 1,
                     padsv     => 1, # this is the additional active op
                     pushmark  => 1,
                     unstack   => 1,
                }
            );
}

#
# multideref
#
# try many permutations of aggregate lookup expressions

{
    package Foo;

    my (@agg_lex, %agg_lex, $i_lex, $r_lex);
    our (@agg_pkg, %agg_pkg, $i_pkg, $r_pkg);

    my $f;
    my @bodies = ('[0]', '[128]', '[$i_lex]', '[$i_pkg]',
                   '{foo}', '{$i_lex}', '{$i_pkg}',
                  );

    for my $prefix ('$f->()->', '$agg_lex', '$agg_pkg', '$r_lex->', '$r_pkg->')
    {
        for my $mod ('', 'local', 'exists', 'delete') {
            for my $body0 (@bodies) {
                for my $body1 ('', @bodies) {
                    for my $body2 ('', '[2*$i_lex]') {
                        my $code = "$mod $prefix$body0$body1$body2";
                        my $sub = "sub { $code }";
                        my $coderef = eval $sub
                            or die "eval '$sub': $@";

                        my %c = (aelem         => 0,
                                 aelemfast     => 0,
                                 aelemfast_lex => 0,
                                 exists        => 0,
                                 delete        => 0,
                                 helem         => 0,
                                 multideref    => 0,
                        );

                        my $top = 'aelem';
                        if ($code =~ /^\s*\$agg_...\[0\]$/) {
                            # we should expect aelemfast rather than multideref
                            $top = $code =~ /lex/ ? 'aelemfast_lex'
                                                  : 'aelemfast';
                            $c{$top} = 1;
                        }
                        else {
                            $c{multideref} = 1;
                        }

                        if ($body2 ne '') {
                            # trailing index; top aelem/exists/whatever
                            # node is kept
                            $top = $mod unless $mod eq '' or $mod eq 'local';
                            $c{$top} = 1
                        }

                        ::test_opcount(0, $sub, $coderef, \%c);
                    }
                }
            }
        }
    }
}


# multideref: ensure that the prefix expression and trailing index
# expression are optimised (include aelemfast in those expressions)


test_opcount(0, 'multideref expressions',
                sub { ($_[0] // $_)->[0]{2*$_[0]} },
                {
                    aelemfast  => 2,
                    helem      => 1,
                    multideref => 1,
                },
            );

# multideref with interesting constant indices


test_opcount(0, 'multideref const index',
                sub { $_->{1}{1.1} },
                {
                    helem      => 0,
                    multideref => 1,
                },
            );

use constant my_undef => undef;
test_opcount(0, 'multideref undef const index',
                sub { $_->{+my_undef} },
                {
                    helem      => 1,
                    multideref => 0,
                },
            );

# multideref when its the first op in a subchain

test_opcount(0, 'multideref op_other etc',
                sub { $_{foo} = $_ ? $_{bar} : $_{baz} },
                {
                    helem      => 0,
                    multideref => 3,
                },
            );

# multideref without hints

{
    no strict;
    no warnings;

    test_opcount(0, 'multideref no hints',
                sub { $_{foo}[0] },
                {
                    aelem      => 0,
                    helem      => 0,
                    multideref => 1,
                },
            );
}

# exists shouldn't clash with aelemfast

test_opcount(0, 'multideref exists',
                sub { exists $_[0] },
                {
                    aelem      => 0,
                    aelemfast  => 0,
                    multideref => 1,
                },
            );

test_opcount(0, 'barewords can be constant-folded',
             sub { no strict 'subs'; FOO . BAR },
             {
                 concat => 0,
             });

{
    no warnings 'experimental::signatures';
    use feature 'signatures';

    my @a;
    test_opcount(0, 'signature default expressions get optimised',
                 sub ($s = $a[0]) {},
                 {
                     aelem         => 0,
                     aelemfast_lex => 1,
                 });
}

# in-place sorting

{
    local our @global = (3,2,1);
    my @lex = qw(a b c);

    test_opcount(0, 'in-place sort of global',
                 sub { @global = sort @global; 1 },
                 {
                     rv2av   => 1,
                     aassign => 0,
                 });

    test_opcount(0, 'in-place sort of lexical',
                 sub { @lex = sort @lex; 1 },
                 {
                     padav   => 1,
                     aassign => 0,
                 });

    test_opcount(0, 'in-place reversed sort of global',
                 sub { @global = sort { $b <=> $a } @global; 1 },
                 {
                     rv2av   => 1,
                     aassign => 0,
                 });


    test_opcount(0, 'in-place custom sort of global',
                 sub { @global = sort {  $a<$b?1:$a>$b?-1:0 } @global; 1 },
                 {
                     rv2av   => 1,
                     aassign => 0,
                 });

    sub mysort { $b cmp $a };
    test_opcount(0, 'in-place sort with function of lexical',
                 sub { @lex = sort mysort @lex; 1 },
                 {
                     padav   => 1,
                     aassign => 0,
                 });


}

# in-place assign optimisation for @a = split

{
    local our @pkg;
    my @lex;

    for (['@pkg',       0, ],
         ['local @pkg', 0, ],
         ['@lex',       0, ],
         ['my @a',      0, ],
         ['@{[]}',      1, ],
    ){
        # partial implies that the aassign has been optimised away, but
        # not the rv2av
        my ($code, $partial) = @$_;
        test_opcount(0, "in-place assignment for split: $code",
                eval qq{sub { $code = split }},
                {
                    padav   => 0,
                    rv2av   => $partial,
                    aassign => 0,
                });
    }
}

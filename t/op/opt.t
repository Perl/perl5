#!./perl

# Use B to test that optimisations are not inadvertently removed.

BEGIN {
    chdir 't';
    require './test.pl';
    skip_all_if_miniperl("No B under miniperl");
    @INC = '../lib';
}

plan 19;

use B qw 'svref_2object OPpASSIGN_COMMON';


# aassign with no common vars
for ('my ($self) = @_',
     'my @x; @y = $x[0]', # aelemfast_lex
    )
{
    my $sub = eval "sub { $_ }";
    my $last_expr =
      svref_2object($sub)->ROOT->first->last;
    if ($last_expr->name ne 'aassign') {
        die "Expected aassign but found ", $last_expr->name,
            "; this test needs to be rewritten" 
    }
    is $last_expr->private & OPpASSIGN_COMMON, 0,
      "no ASSIGN_COMMON for $_";
}    


# join -> stringify/const

for (['CONSTANT', sub {          join "foo", $_ }],
     ['$var'    , sub {          join  $_  , $_ }],
     ['$myvar'  , sub { my $var; join  $var, $_ }],
) {
    my($sep,$sub) = @$_;
    my $last_expr = svref_2object($sub)->ROOT->first->last;
    is $last_expr->name, 'stringify',
      "join($sep, \$scalar) optimised to stringify";
}

for (['CONSTANT', sub {          join "foo", "bar"    }, 0, "bar"    ],
     ['CONSTANT', sub {          join "foo", "bar", 3 }, 1, "barfoo3"],
     ['$var'    , sub {          join  $_  , "bar"    }, 0, "bar"    ],
     ['$myvar'  , sub { my $var; join  $var, "bar"    }, 0, "bar"    ],
) {
    my($sep,$sub,$is_list,$expect) = @$_;
    my $last_expr = svref_2object($sub)->ROOT->first->last;
    my $tn = "join($sep, " . ($is_list?'list of constants':'const') . ")";
    is $last_expr->name, 'const', "$tn optimised to constant";
    is $sub->(), $expect, "$tn folded correctly";
}


# split to array

for(['@pkgary'      , '@_'       ],
    ['@lexary'      , 'my @a; @a'],
    ['my(@array)'   , 'my(@a)'   ],
    ['local(@array)', 'local(@_)'],
    ['@{...}'       , '@{\@_}'   ],
){
    my($tn,$code) = @$_;
    my $sub = eval "sub { $code = split }";
    my $split = svref_2object($sub)->ROOT->first->last;
    is $split->name, 'split', "$tn = split swallows up the assignment";
}


# stringify with join kid --> join
is svref_2object(sub { "@_" })->ROOT->first->last->name, 'join',
  'qq"@_" optimised from stringify(join(...)) to join(...)';
